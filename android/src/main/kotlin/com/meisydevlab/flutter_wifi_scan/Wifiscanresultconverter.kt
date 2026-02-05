package com.meisydevlab.flutter_wifi_scan

import android.net.wifi.ScanResult
import android.net.wifi.WifiInfo
import android.os.Build

object WifiScanResultConverter {
    
    fun toMap(scanResult: ScanResult): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()

        // Basic fields (always available)
        map["ssid"] = scanResult.SSID ?: ""
        map["bssid"] = scanResult.BSSID ?: ""
        map["rssi"] = scanResult.level
        map["capabilities"] = scanResult.capabilities ?: ""
        map["frequency"] = scanResult.frequency
        map["timestamp"] = scanResult.timestamp

        // Channel calculation from frequency
        map["channel"] = getChannelFromFrequency(scanResult.frequency)

        // Manufacturer lookup from BSSID (OUI)
        map["manufacturer"] = OuiLookup.lookup(scanResult.BSSID)

        // Channel width (API 23+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            map["channelWidth"] = getChannelWidthMHz(scanResult.channelWidth)
        }

        // PHY speeds (API 30+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Max supported speed
            map["phyMaxSpeedMbps"] = scanResult.wifiStandard.let { standard ->
                getMaxSpeedForStandard(standard, scanResult.channelWidth)
            }
        }

        return map
    }

    private fun getChannelFromFrequency(frequency: Int): Int {
        return when {
            frequency in 2412..2484 -> {
                // 2.4 GHz band
                if (frequency == 2484) 14 else (frequency - 2412) / 5 + 1
            }
            frequency in 5170..5825 -> {
                // 5 GHz band
                (frequency - 5170) / 5 + 34
            }
            frequency in 5955..7115 -> {
                // 6 GHz band (Wi-Fi 6E)
                (frequency - 5955) / 5 + 1
            }
            else -> 0
        }
    }

    private fun getChannelWidthMHz(channelWidth: Int): Int {
        // Convert Android's channel width constant to MHz
        return when (channelWidth) {
            0 -> 20  // CHANNEL_WIDTH_20MHZ
            1 -> 40  // CHANNEL_WIDTH_40MHZ
            2 -> 80  // CHANNEL_WIDTH_80MHZ
            3 -> 160 // CHANNEL_WIDTH_160MHZ
            4 -> 80  // CHANNEL_WIDTH_80MHZ_PLUS_MHZ (80+80)
            else -> 20
        }
    }

    private fun getMaxSpeedForStandard(standard: Int, channelWidth: Int): Int {
        // Estimates based on Wi-Fi standard and channel width
        // These are theoretical maximums
        
        val widthMHz = getChannelWidthMHz(channelWidth)
        
        return when (standard) {
            1 -> 11      // WIFI_STANDARD_LEGACY (802.11b)
            2 -> 54      // WIFI_STANDARD_11A
            3 -> 54      // WIFI_STANDARD_11B
            4 -> 54      // WIFI_STANDARD_11G
            5 -> when (widthMHz) { // WIFI_STANDARD_11N
                20 -> 150
                40 -> 300
                else -> 600
            }
            6 -> when (widthMHz) { // WIFI_STANDARD_11AC
                20 -> 200
                40 -> 400
                80 -> 867
                160 -> 1733
                else -> 3467
            }
            7 -> when (widthMHz) { // WIFI_STANDARD_11AX (Wi-Fi 6)
                20 -> 287
                40 -> 574
                80 -> 1201
                160 -> 2402
                else -> 4804
            }
            8 -> when (widthMHz) { // WIFI_STANDARD_11BE (Wi-Fi 7)
                20 -> 574
                40 -> 1376
                80 -> 2882
                160 -> 5764
                else -> 11529
            }
            else -> 0
        }
    }
}