import 'package:flutter/material.dart';
import 'package:flutter_wifi_scan/flutter_wifi_scan.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wi-Fi Scanner Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WifiScanPage(),
    );
  }
}

class WifiScanPage extends StatefulWidget {
  const WifiScanPage({super.key});

  @override
  State<WifiScanPage> createState() => _WifiScanPageState();
}

class _WifiScanPageState extends State<WifiScanPage> {
  StreamSubscription<List<WiFiScanResult>>? _scanSubscription;
  List<WiFiScanResult> _scanResults = [];
  WiFiBand? _selectedBand;
  bool _isSupported = false;
  bool _hasPermissions = false;
  bool _isScanning = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    // Check if Wi-Fi scanning is supported
    final supported = await FlutterWifiScan.isSupported;
    setState(() {
      _isSupported = supported;
      if (!supported) {
        _statusMessage = 'Wi-Fi scanning is not supported on this platform';
        return;
      }
    });

    // Check permissions
    final hasPerms = await FlutterWifiScan.hasPermissions;
    setState(() => _hasPermissions = hasPerms);

    if (!hasPerms) {
      setState(
        () =>
            _statusMessage = 'Location permission required for Wi-Fi scanning',
      );
      return;
    }

    // Check prerequisites
    final wifiEnabled = await FlutterWifiScan.isWiFiEnabled;
    final locationEnabled = await FlutterWifiScan.isLocationEnabled;

    if (!wifiEnabled) {
      setState(() => _statusMessage = 'Please enable Wi-Fi');
      return;
    }

    if (!locationEnabled) {
      setState(() => _statusMessage = 'Please enable location services');
      return;
    }

    // Start scanning
    _startScanning();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning...';
    });

    _scanSubscription = FlutterWifiScan.startScan(bandFilter: _selectedBand)
        .listen(
          (results) {
            setState(() {
              _scanResults = results;
              _statusMessage = 'Found ${results.length} networks';
            });
          },
          onError: (error) {
            setState(() {
              _statusMessage = 'Error: $error';
            });
          },
        );
  }

  Future<void> _requestPermissions() async {
    final granted = await FlutterWifiScan.requestPermissions();
    setState(() => _hasPermissions = granted);

    if (granted) {
      _initializeScanner();
    } else {
      setState(() => _statusMessage = 'Permission denied');
    }
  }

  void _changeBandFilter(WiFiBand? band) {
    setState(() => _selectedBand = band);

    // Restart scan with new filter
    _scanSubscription?.cancel();
    if (_isSupported && _hasPermissions) {
      _startScanning();
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterWifiScan.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Scanner'),
        actions: [
          // Band filter dropdown
          if (_isScanning)
            PopupMenuButton<WiFiBand?>(
              icon: const Icon(Icons.filter_alt),
              initialValue: _selectedBand,
              onSelected: _changeBandFilter,
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('All Bands')),
                const PopupMenuItem(
                  value: WiFiBand.band24GHz,
                  child: Text('2.4 GHz'),
                ),
                const PopupMenuItem(
                  value: WiFiBand.band5GHz,
                  child: Text('5 GHz'),
                ),
                const PopupMenuItem(
                  value: WiFiBand.band6GHz,
                  child: Text('6 GHz'),
                ),
              ],
            ),
          // Refresh button
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => FlutterWifiScan.refreshScan(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Row(
              children: [
                Icon(
                  _isScanning ? Icons.wifi_find : Icons.wifi_off,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                if (_selectedBand != null)
                  Chip(
                    label: Text(_selectedBand!.displayName),
                    onDeleted: () => _changeBandFilter(null),
                  ),
              ],
            ),
          ),

          // Request permissions button
          if (_isSupported && !_hasPermissions)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.security),
                label: const Text('Grant Location Permission'),
              ),
            ),

          // Scan results list
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_isSupported) {
      return const Center(
        child: Text('Wi-Fi scanning not supported on this platform'),
      );
    }

    if (!_hasPermissions) {
      return const Center(child: Text('Location permission required'));
    }

    if (!_isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_scanResults.isEmpty) {
      return const Center(child: Text('No Wi-Fi networks found'));
    }

    // Sort by signal strength
    final sortedResults = List<WiFiScanResult>.from(_scanResults)
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return ListView.builder(
      itemCount: sortedResults.length,
      itemBuilder: (context, index) {
        final result = sortedResults[index];
        return _buildNetworkTile(result);
      },
    );
  }

  Widget _buildNetworkTile(WiFiScanResult result) {
    return ListTile(
      leading: Icon(
        _getSignalIcon(result.signalStrengthPercent),
        color: _getSignalColor(result.signalStrengthPercent),
      ),
      title: Text(
        result.ssid.isEmpty ? '<Hidden Network>' : result.ssid,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${result.security.displayName} • ${result.rssi} dBm • ${result.band.displayName}',
      ),
      trailing: result.security.isOpen
          ? null
          : Icon(Icons.lock, size: 16, color: Colors.grey[600]),
      onTap: () => _showNetworkDetails(result),
    );
  }

  IconData _getSignalIcon(int strength) {
    if (strength >= 80) return Icons.signal_wifi_4_bar;
    if (strength >= 60) return Icons.signal_wifi_4_bar_lock;
    if (strength >= 40) return Icons.signal_wifi_4_bar_outlined;
    if (strength >= 20) return Icons.signal_wifi_0_bar;
    return Icons.signal_wifi_0_bar;
  }

  Color _getSignalColor(int strength) {
    if (strength >= 60) return Colors.green;
    if (strength >= 40) return Colors.orange;
    return Colors.red;
  }

  void _showNetworkDetails(WiFiScanResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return NetworkDetailView(
            result: result,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class NetworkDetailView extends StatelessWidget {
  final WiFiScanResult result;
  final ScrollController scrollController;

  const NetworkDetailView({
    super.key,
    required this.result,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Network name
                Center(
                  child: Column(
                    children: [
                      Icon(
                        _getSignalIcon(result.signalStrengthPercent),
                        size: 48,
                        color: _getSignalColor(result.signalStrengthPercent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.ssid.isEmpty ? '<Hidden Network>' : result.ssid,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.signalQuality,
                        style: TextStyle(
                          color: _getSignalColor(result.signalStrengthPercent),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Details
                _buildDetailRow('BSSID', result.bssid),
                _buildDetailRow('Security', result.security.displayName),
                if (result.manufacturer != null)
                  _buildDetailRow('Manufacturer', result.manufacturer!),
                _buildDetailRow('Band', result.band.displayName),
                _buildDetailRow('RSSI', '${result.rssi} dBm'),
                _buildDetailRow(
                  'Signal Strength',
                  '${result.signalStrengthPercent}%',
                ),
                if (result.frequency != null)
                  _buildDetailRow('Frequency', '${result.frequency} MHz'),
                if (result.channel != null)
                  _buildDetailRow('Channel', result.channel.toString()),
                if (result.channelWidth != null)
                  _buildDetailRow(
                    'Channel Width',
                    '${result.channelWidth} MHz',
                  ),
                if (result.phyMaxSpeedMbps != null)
                  _buildDetailRow(
                    'Max PHY Speed',
                    '${result.phyMaxSpeedMbps} Mbps',
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Capabilities
                _buildSectionHeader('Capabilities'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (result.security.isOpen)
                      _buildChip('Open', Colors.orange),
                    if (result.security.hasWep) _buildChip('WEP', Colors.red),
                    if (result.security.hasWpa) _buildChip('WPA', Colors.blue),
                    if (result.security.hasWpa2)
                      _buildChip('WPA2', Colors.green),
                    if (result.security.hasWpa3)
                      _buildChip('WPA3', Colors.purple),
                    if (result.security.hasEap)
                      _buildChip('Enterprise', Colors.teal),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
    );
  }

  IconData _getSignalIcon(int strength) {
    if (strength >= 80) return Icons.signal_wifi_4_bar;
    if (strength >= 60) return Icons.signal_wifi_4_bar_lock;
    if (strength >= 40) return Icons.signal_wifi_4_bar_outlined;
    if (strength >= 20) return Icons.signal_wifi_0_bar;
    return Icons.signal_wifi_0_bar;
  }

  Color _getSignalColor(int strength) {
    if (strength >= 60) return Colors.green;
    if (strength >= 40) return Colors.orange;
    return Colors.red;
  }
}
