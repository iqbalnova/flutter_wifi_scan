import 'wifi_band.dart';
import 'wifi_security.dart';

/// Represents a single Wi-Fi scan result
class WiFiScanResult {
  // List view fields (lightweight, always present)
  final String ssid;
  final int rssi;
  final WiFiSecurity security;

  // Detail view fields (expanded information)
  final String bssid;
  final String? manufacturer;
  final WiFiBand band;
  final int? channel;
  final int? channelWidth; // in MHz
  final int? frequency; // in MHz

  // PHY information (may be null on older devices/APIs)
  final int? phyUploadSpeedMbps;
  final int? phyDownloadSpeedMbps;
  final int? phyMaxSpeedMbps;

  // Raw timestamp from scan
  final int timestamp;

  const WiFiScanResult({
    required this.ssid,
    required this.rssi,
    required this.security,
    required this.bssid,
    this.manufacturer,
    required this.band,
    this.channel,
    this.channelWidth,
    this.frequency,
    this.phyUploadSpeedMbps,
    this.phyDownloadSpeedMbps,
    this.phyMaxSpeedMbps,
    required this.timestamp,
  });

  /// Parse from platform map
  factory WiFiScanResult.fromMap(Map<dynamic, dynamic> map) {
    final frequency = map['frequency'] as int?;
    final band = frequency != null
        ? WiFiBand.fromFrequency(frequency)
        : WiFiBand.unknown;

    return WiFiScanResult(
      ssid: map['ssid'] as String? ?? '',
      rssi: map['rssi'] as int? ?? -100,
      security: WiFiSecurity.fromCapabilities(
        map['capabilities'] as String? ?? '',
      ),
      bssid: map['bssid'] as String? ?? '',
      manufacturer: map['manufacturer'] as String?,
      band: band,
      channel: map['channel'] as int?,
      channelWidth: map['channelWidth'] as int?,
      frequency: frequency,
      phyUploadSpeedMbps: map['phyUploadSpeedMbps'] as int?,
      phyDownloadSpeedMbps: map['phyDownloadSpeedMbps'] as int?,
      phyMaxSpeedMbps: map['phyMaxSpeedMbps'] as int?,
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  /// Convert to map for platform communication
  Map<String, dynamic> toMap() {
    return {
      'ssid': ssid,
      'rssi': rssi,
      'capabilities': security.capabilities,
      'bssid': bssid,
      'manufacturer': manufacturer,
      'frequency': frequency,
      'channel': channel,
      'channelWidth': channelWidth,
      'phyUploadSpeedMbps': phyUploadSpeedMbps,
      'phyDownloadSpeedMbps': phyDownloadSpeedMbps,
      'phyMaxSpeedMbps': phyMaxSpeedMbps,
      'timestamp': timestamp,
    };
  }

  /// Check if this result matches the given band filter
  bool matchesBand(WiFiBand? filter) {
    return filter == null || band == filter;
  }

  /// Get signal strength as percentage (0-100)
  int get signalStrengthPercent {
    // RSSI typically ranges from -100 (worst) to -30 (best)
    final percent = ((rssi + 100) * 100 / 70).clamp(0, 100);
    return percent.round();
  }

  /// Get signal quality descriptor
  String get signalQuality {
    final percent = signalStrengthPercent;
    if (percent >= 80) return 'Excellent';
    if (percent >= 60) return 'Good';
    if (percent >= 40) return 'Fair';
    if (percent >= 20) return 'Weak';
    return 'Very Weak';
  }

  @override
  String toString() {
    return 'WiFiScanResult(ssid: $ssid, rssi: $rssi dBm, '
        'band: ${band.displayName}, security: ${security.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WiFiScanResult && other.bssid == bssid;
  }

  @override
  int get hashCode => bssid.hashCode;
}
