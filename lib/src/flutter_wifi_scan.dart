import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'models/wifi_scan_result.dart';
import 'models/wifi_band.dart';

/// Main plugin class for Wi-Fi scanning
class FlutterWifiScan {
  static const MethodChannel _methodChannel = MethodChannel(
    'flutter_wifi_scan/methods',
  );

  static const EventChannel _scanEventChannel = EventChannel(
    'flutter_wifi_scan/scan_events',
  );

  static Stream<List<WiFiScanResult>>? _scanStream;
  static StreamSubscription? _scanSubscription;

  /// Check if Wi-Fi scanning is supported on this platform
  /// Returns true on Android, false on iOS
  static Future<bool> get isSupported async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if all required permissions are granted
  /// On Android: checks for location permission
  /// On iOS: returns false (unsupported)
  static Future<bool> get hasPermissions async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('hasPermissions');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request required permissions
  /// On Android: requests location permission if not granted
  /// On iOS: returns false (unsupported)
  static Future<bool> requestPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'requestPermissions',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if Wi-Fi is enabled on the device
  static Future<bool> get isWiFiEnabled async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isWiFiEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if location services are enabled (required for Wi-Fi scanning on Android)
  static Future<bool> get isLocationEnabled async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isLocationEnabled',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start a real-time Wi-Fi scan stream
  ///
  /// The stream will emit scan results continuously until disposed.
  /// The stream automatically handles:
  /// - Wi-Fi state changes
  /// - Permission changes
  /// - Location service changes
  ///
  /// Optional [bandFilter] to filter results by frequency band.
  ///
  /// The stream will emit an empty list when:
  /// - Wi-Fi is disabled
  /// - Location services are disabled
  /// - Permissions are not granted
  ///
  /// Example:
  /// ```dart
  /// final stream = FlutterWifiScan.startScan();
  /// stream.listen((results) {
  ///   debugPrint('Found ${results.length} networks');
  /// });
  /// ```
  static Stream<List<WiFiScanResult>> startScan({WiFiBand? bandFilter}) {
    // Create the scan stream if it doesn't exist
    _scanStream ??= _scanEventChannel
        .receiveBroadcastStream()
        .map<List<WiFiScanResult>>((dynamic event) {
          if (event == null) return [];

          try {
            final List<dynamic> resultsList = event as List<dynamic>;
            return resultsList
                .map((dynamic item) => WiFiScanResult.fromMap(item as Map))
                .toList();
          } catch (e) {
            debugPrint('Error parsing scan results: $e');
            return [];
          }
        })
        .asBroadcastStream();

    // Apply band filter if specified
    if (bandFilter != null) {
      return _scanStream!.map(
        (results) =>
            results.where((result) => result.matchesBand(bandFilter)).toList(),
      );
    }

    return _scanStream!;
  }

  /// Stop the Wi-Fi scan stream and clean up resources
  ///
  /// This should be called when:
  /// - The scan screen is disposed
  /// - The app no longer needs scan results
  ///
  /// The stream can be restarted by calling [startScan] again.
  static Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _scanStream = null;

    try {
      await _methodChannel.invokeMethod('stopScan');
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Trigger a single immediate scan
  ///
  /// This is useful to force a fresh scan without waiting for
  /// the automatic scan interval.
  ///
  /// Note: This does not return results directly. Results will be
  /// emitted through the scan stream from [startScan].
  static Future<void> refreshScan() async {
    try {
      await _methodChannel.invokeMethod('refreshScan');
    } catch (e) {
      debugPrint('Error refreshing scan: $e');
    }
  }

  /// Get the OUI (Organizationally Unique Identifier) manufacturer database version
  ///
  /// Returns a string like "2024-01-15" or null if unavailable
  static Future<String?> get ouiDatabaseVersion async {
    try {
      return await _methodChannel.invokeMethod<String>('getOuiDatabaseVersion');
    } catch (e) {
      return null;
    }
  }
}
