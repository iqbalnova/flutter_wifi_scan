import Flutter
import UIKit

public class FlutterWifiScanPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterWifiScanPlugin()
        
        let methodChannel = FlutterMethodChannel(
            name: "flutter_wifi_scan/methods",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        let eventChannel = FlutterEventChannel(
            name: "flutter_wifi_scan/scan_events",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // All method calls return unsupported/false on iOS
        switch call.method {
        case "isSupported":
            result(false)
        case "hasPermissions":
            result(false)
        case "requestPermissions":
            result(false)
        case "isWiFiEnabled":
            result(false)
        case "isLocationEnabled":
            result(false)
        case "stopScan":
            result(nil)
        case "refreshScan":
            result(nil)
        case "getOuiDatabaseVersion":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // Immediately return empty list on iOS
        events([])
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}