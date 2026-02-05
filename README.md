# flutter_wifi_scan

A Flutter plugin for real-time Wi-Fi scanning on Android. iOS explicitly returns `unsupported` for all operations.

## Features

✅ **Real-time Wi-Fi scanning** via EventChannel streaming  
✅ **Band filtering** (2.4 GHz, 5 GHz, 6 GHz)  
✅ **Extended network information** including PHY speeds, channel width, manufacturer  
✅ **Clean, maintainable API** with proper lifecycle management  
✅ **Production-ready** with permission handling and error states  
✅ **iOS support** with explicit unsupported responses (no private APIs)

## Platform Support

| Platform | Supported | Notes                                    |
| -------- | --------- | ---------------------------------------- |
| Android  | ✅ Yes    | Full support with real-time scanning     |
| iOS      | ⚠️ No     | All APIs return `unsupported` explicitly |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_wifi_scan:
    git:
      url: https://github.com/meisydevlab/flutter_wifi_scan.git
```

## Android Requirements

### Minimum SDK

- `minSdkVersion`: 21 (Android 5.0)
- `compileSdkVersion`: 34 (Android 14)

### Permissions

Add to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Runtime Requirements

- **Wi-Fi must be enabled**
- **Location services must be enabled** (required by Android for Wi-Fi scanning)
- **Location permission must be granted**

The plugin will automatically emit empty lists when these conditions aren't met.

## Quick Start

### Basic Usage

```dart
import 'package:flutter_wifi_scan/flutter_wifi_scan.dart';

class WifiScanPage extends StatefulWidget {
  @override
  _WifiScanPageState createState() => _WifiScanPageState();
}

class _WifiScanPageState extends State<WifiScanPage> {
  StreamSubscription<List<WiFiScanResult>>? _scanSubscription;
  List<WiFiScanResult> _networks = [];

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() async {
    // Check if supported
    if (!await FlutterWifiScan.isSupported) {
      print('Wi-Fi scanning not supported on this platform');
      return;
    }

    // Request permissions if needed
    if (!await FlutterWifiScan.hasPermissions) {
      final granted = await FlutterWifiScan.requestPermissions();
      if (!granted) {
        print('Permission denied');
        return;
      }
    }

    // Start scanning
    _scanSubscription = FlutterWifiScan.startScan().listen((results) {
      setState(() {
        _networks = results;
      });
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterWifiScan.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _networks.length,
      itemBuilder: (context, index) {
        final network = _networks[index];
        return ListTile(
          title: Text(network.ssid),
          subtitle: Text('${network.rssi} dBm • ${network.security.displayName}'),
        );
      },
    );
  }
}
```

### Band Filtering

Filter scan results by frequency band:

```dart
// Only 5 GHz networks
final stream = FlutterWifiScan.startScan(bandFilter: WiFiBand.band5GHz);

// Only 2.4 GHz networks
final stream = FlutterWifiScan.startScan(bandFilter: WiFiBand.band24GHz);

// Only 6 GHz networks (Wi-Fi 6E)
final stream = FlutterWifiScan.startScan(bandFilter: WiFiBand.band6GHz);

// All bands (default)
final stream = FlutterWifiScan.startScan();
```

### Network Detail View

Access extended information for each network:

```dart
void showNetworkDetails(WiFiScanResult network) {
  print('SSID: ${network.ssid}');
  print('BSSID: ${network.bssid}');
  print('RSSI: ${network.rssi} dBm');
  print('Security: ${network.security.displayName}');
  print('Band: ${network.band.displayName}');
  print('Manufacturer: ${network.manufacturer ?? "Unknown"}');
  print('Channel: ${network.channel}');
  print('Channel Width: ${network.channelWidth} MHz');
  print('Frequency: ${network.frequency} MHz');
  print('Max PHY Speed: ${network.phyMaxSpeedMbps} Mbps');
  print('Signal Quality: ${network.signalQuality}');
  print('Signal Strength: ${network.signalStrengthPercent}%');
}
```

## API Reference

### Methods

#### `isSupported`

```dart
Future<bool> get isSupported
```

Check if Wi-Fi scanning is supported on this platform.

- Returns `true` on Android
- Returns `false` on iOS

#### `hasPermissions`

```dart
Future<bool> get hasPermissions
```

Check if all required permissions are granted.

#### `requestPermissions`

```dart
Future<bool> requestPermissions()
```

Request required permissions from the user.

#### `isWiFiEnabled`

```dart
Future<bool> get isWiFiEnabled
```

Check if Wi-Fi is enabled on the device.

#### `isLocationEnabled`

```dart
Future<bool> get isLocationEnabled
```

Check if location services are enabled (required for Wi-Fi scanning on Android).

#### `startScan`

```dart
Stream<List<WiFiScanResult>> startScan({WiFiBand? bandFilter})
```

Start a real-time Wi-Fi scan stream. Returns a broadcast stream that emits scan results continuously.

#### `stopScan`

```dart
Future<void> stopScan()
```

Stop the Wi-Fi scan stream and clean up resources.

#### `refreshScan`

```dart
Future<void> refreshScan()
```

Trigger an immediate scan without waiting for the automatic scan interval.

### Models

#### `WiFiScanResult`

| Field             | Type           | Description                    | Availability   |
| ----------------- | -------------- | ------------------------------ | -------------- |
| `ssid`            | `String`       | Network name                   | Always         |
| `bssid`           | `String`       | MAC address                    | Always         |
| `rssi`            | `int`          | Signal strength in dBm         | Always         |
| `security`        | `WiFiSecurity` | Security information           | Always         |
| `band`            | `WiFiBand`     | Frequency band                 | Always         |
| `manufacturer`    | `String?`      | Device manufacturer (from OUI) | When available |
| `frequency`       | `int?`         | Frequency in MHz               | API 21+        |
| `channel`         | `int?`         | Wi-Fi channel number           | API 21+        |
| `channelWidth`    | `int?`         | Channel width in MHz           | API 23+        |
| `phyMaxSpeedMbps` | `int?`         | Maximum PHY speed              | API 30+        |
| `timestamp`       | `int`          | Scan timestamp                 | Always         |

**Computed Properties:**

- `signalStrengthPercent`: Signal strength as 0-100 percentage
- `signalQuality`: Human-readable quality ("Excellent", "Good", "Fair", "Weak", "Very Weak")

#### `WiFiBand`

```dart
enum WiFiBand {
  band24GHz,  // 2.4 GHz
  band5GHz,   // 5 GHz
  band6GHz,   // 6 GHz (Wi-Fi 6E)
  unknown
}
```

#### `WiFiSecurity`

| Property       | Type     | Description                    |
| -------------- | -------- | ------------------------------ |
| `isOpen`       | `bool`   | Network has no security        |
| `hasWep`       | `bool`   | Uses WEP encryption            |
| `hasWpa`       | `bool`   | Uses WPA encryption            |
| `hasWpa2`      | `bool`   | Uses WPA2 encryption           |
| `hasWpa3`      | `bool`   | Uses WPA3 encryption           |
| `hasEap`       | `bool`   | Uses enterprise authentication |
| `capabilities` | `String` | Raw capability string          |
| `displayName`  | `String` | User-friendly security type    |
| `strength`     | `int`    | Security strength (0-3)        |

## Technical Details

### Android Implementation

#### EventChannel Streaming

- Uses `BroadcastReceiver` to listen for scan results
- Automatically handles Wi-Fi state changes
- Properly registers/unregisters receivers to prevent memory leaks

#### Scan Throttling

- Respects Android's 15-second minimum scan interval
- Prevents excessive battery drain
- Schedules scans efficiently with `Handler`

#### Thread Safety

- All EventSink emissions happen on the main thread
- No blocking operations on the main thread

#### PHY Speed Notes

PHY speeds are theoretical maximums based on:

- Wi-Fi standard (802.11n/ac/ax/be)
- Channel width (20/40/80/160 MHz)
- Number of spatial streams (estimated)

Actual speeds will be lower due to:

- Distance from access point
- Interference
- Network congestion
- Client capabilities

**Availability:**

- `phyMaxSpeedMbps`: API 30+ (Android 11+)
- `phyUploadSpeedMbps`: Not available (requires connection)
- `phyDownloadSpeedMbps`: Not available (requires connection)

Upload/download PHY speeds require an active connection and are not available from scan results.

#### Channel Width Availability

- 20/40 MHz: API 23+ (Android 6.0+)
- 80/160 MHz: API 23+ (Android 6.0+)
- Default: 20 MHz on older devices

#### Manufacturer Detection

Uses OUI (Organizationally Unique Identifier) lookup from the first 3 bytes of the BSSID (MAC address). The plugin includes a curated database of common manufacturers.

To check the OUI database version:

```dart
final version = await FlutterWifiScan.ouiDatabaseVersion;
```

### iOS Implementation

iOS does not provide public APIs for Wi-Fi scanning. The plugin explicitly returns:

- `isSupported`: `false`
- `hasPermissions`: `false`
- All scan streams: empty list `[]`

This approach:
✅ Maintains API consistency across platforms  
✅ Avoids private API usage (App Store rejection)  
✅ Provides clear feedback to users

### Stream Lifecycle

The scan stream follows Flutter's standard stream lifecycle:

1. **Stream Creation**: `startScan()` creates a broadcast stream
2. **Listener Attachment**: First listener triggers scan start
3. **Continuous Emission**: Results emitted as scans complete
4. **Listener Detachment**: Last listener cancellation doesn't stop scanning
5. **Manual Stop**: Call `stopScan()` to fully stop scanning and clean up

**Best Practice:**

```dart
@override
void dispose() {
  _scanSubscription?.cancel();  // Cancel subscription
  FlutterWifiScan.stopScan();   // Stop scanning
  super.dispose();
}
```

## Performance Considerations

### Battery Usage

- Wi-Fi scanning uses moderate battery
- Scan frequency limited to every 15 seconds (Android requirement)
- Stop scanning when not needed

### Memory Management

- Scan results are emitted as new lists each time
- Old results are garbage collected automatically
- No internal caching of results

### Scan Throttling

Android limits Wi-Fi scans to 4-5 per minute per app. The plugin:

- Enforces 15-second minimum between scans
- Queues scan requests if triggered too soon
- Automatically schedules next scan after results

## Troubleshooting

### No scan results on Android

Check these conditions:

1. Wi-Fi is enabled: `await FlutterWifiScan.isWiFiEnabled`
2. Location is enabled: `await FlutterWifiScan.isLocationEnabled`
3. Permissions granted: `await FlutterWifiScan.hasPermissions`
4. Plugin is supported: `await FlutterWifiScan.isSupported`

### Permission denied

Make sure to:

1. Add permissions to `AndroidManifest.xml`
2. Call `FlutterWifiScan.requestPermissions()`
3. Check `targetSdkVersion` in `build.gradle`

### Slow scan updates

This is expected behavior:

- Android limits scans to every 15 seconds minimum
- The plugin respects these limits
- Use `refreshScan()` to force an immediate scan

### Empty SSID

Some networks hide their SSID (hidden networks). These will show as empty strings.

## Example App

See the [example](example/) directory for a complete implementation with:

- Permission handling
- Band filtering UI
- List view with signal strength
- Detail view with extended information
- Proper lifecycle management

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Built with ❤️ by [Meisy Dev Lab](https://github.com/meisydevlab)
