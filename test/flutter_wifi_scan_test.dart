// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_wifi_scan/flutter_wifi_scan.dart';
// import 'package:flutter_wifi_scan/flutter_wifi_scan_platform_interface.dart';
// import 'package:flutter_wifi_scan/flutter_wifi_scan_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockFlutterWifiScanPlatform
//     with MockPlatformInterfaceMixin
//     implements FlutterWifiScanPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final FlutterWifiScanPlatform initialPlatform = FlutterWifiScanPlatform.instance;

//   test('$MethodChannelFlutterWifiScan is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelFlutterWifiScan>());
//   });

//   test('getPlatformVersion', () async {
//     FlutterWifiScan flutterWifiScanPlugin = FlutterWifiScan();
//     MockFlutterWifiScanPlatform fakePlatform = MockFlutterWifiScanPlatform();
//     FlutterWifiScanPlatform.instance = fakePlatform;

//     expect(await flutterWifiScanPlugin.getPlatformVersion(), '42');
//   });
// }
