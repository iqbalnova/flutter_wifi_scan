package com.meisydevlab.flutter_wifi_scan

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class FlutterWifiScanPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var wifiManager: WifiManager? = null
    private var locationManager: LocationManager? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var scanReceiver: BroadcastReceiver? = null
    private var isScanning = false
    
    // Scan throttling to respect Android limits
    private var lastScanTime = 0L
    private val minScanInterval = 15000L // 15 seconds minimum between scans

    private var permissionRequestCallback: ((Boolean) -> Unit)? = null
    private val PERMISSION_REQUEST_CODE = 1001

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "flutter_wifi_scan/methods")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "flutter_wifi_scan/scan_events")
        eventChannel.setStreamHandler(this)

        wifiManager = context?.applicationContext?.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        locationManager = context?.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopScanning()
        context = null
        wifiManager = null
        locationManager = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    // MethodChannel handler
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(true)
            "hasPermissions" -> result.success(hasPermissions())
            "requestPermissions" -> requestPermissions(result)
            "isWiFiEnabled" -> result.success(isWiFiEnabled())
            "isLocationEnabled" -> result.success(isLocationEnabled())
            "stopScan" -> {
                stopScanning()
                result.success(null)
            }
            "refreshScan" -> {
                if (canScan()) {
                    triggerScan()
                }
                result.success(null)
            }
            "getOuiDatabaseVersion" -> result.success(OuiLookup.getVersion())
            else -> result.notImplemented()
        }
    }

    // EventChannel StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startScanning()
    }

    override fun onCancel(arguments: Any?) {
        stopScanning()
        eventSink = null
    }

    // Permission handling
    private fun hasPermissions(): Boolean {
        val ctx = context ?: return false

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val locationPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION)
            } else {
                ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_COARSE_LOCATION)
            }
            locationPermission == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val activity = activityBinding?.activity

        if (activity == null) {
            result.success(false)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(true)
            return
        }

        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Manifest.permission.ACCESS_FINE_LOCATION
        } else {
            Manifest.permission.ACCESS_COARSE_LOCATION
        }

        permissionRequestCallback = { granted ->
            result.success(granted)
            permissionRequestCallback = null
        }

        activity.requestPermissions(arrayOf(permission), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionRequestCallback?.invoke(granted)
            return true
        }
        return false
    }

    private fun isWiFiEnabled(): Boolean {
        return wifiManager?.isWifiEnabled == true
    }

    private fun isLocationEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return true
        }
        return locationManager?.isLocationEnabled == true
    }

    private fun canScan(): Boolean {
        return isLocationEnabled() && hasPermissions()
    }

    // Scanning logic
    private fun startScanning() {
        if (isScanning) return
        isScanning = true

        if (!canScan()) {
            // Emit empty list and don't register receiver
            emitResults(emptyList())
            return
        }

        // Register broadcast receiver for scan results
        scanReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    WifiManager.SCAN_RESULTS_AVAILABLE_ACTION -> {
                        handleScanResults()
                    }
                    WifiManager.WIFI_STATE_CHANGED_ACTION,
                    LocationManager.PROVIDERS_CHANGED_ACTION -> {
                        // Re-check conditions and emit empty if needed
                        if (!canScan()) {
                            emitResults(emptyList())
                        } else {
                            triggerScan()
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
            addAction(WifiManager.WIFI_STATE_CHANGED_ACTION)
            addAction(LocationManager.PROVIDERS_CHANGED_ACTION)
        }

        context?.registerReceiver(scanReceiver, filter)

        // Trigger initial scan
        triggerScan()
    }

    private fun stopScanning() {
        if (!isScanning) return
        isScanning = false

        try {
            scanReceiver?.let { context?.unregisterReceiver(it) }
        } catch (e: Exception) {
            // Receiver might not be registered
        }
        scanReceiver = null
    }

    private fun triggerScan() {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastScanTime < minScanInterval) {
            // Too soon, schedule for later
            mainHandler.postDelayed({
                if (isScanning) triggerScan()
            }, minScanInterval - (currentTime - lastScanTime))
            return
        }

        lastScanTime = currentTime
        
        try {
            wifiManager?.startScan()
        } catch (e: SecurityException) {
            // Permission denied
            emitResults(emptyList())
        }
    }

    private fun handleScanResults() {
        if (!canScan()) {
            emitResults(emptyList())
            return
        }

        try {
            val scanResults = wifiManager?.scanResults ?: emptyList()
            emitResults(scanResults)
        } catch (e: SecurityException) {
            emitResults(emptyList())
        }

        // Schedule next scan
        mainHandler.postDelayed({
            if (isScanning) triggerScan()
        }, minScanInterval)
    }

    private fun emitResults(scanResults: List<ScanResult>) {
        val results = scanResults.map { result ->
            WifiScanResultConverter.toMap(result)
        }

        mainHandler.post {
            eventSink?.success(results)
        }
    }
}