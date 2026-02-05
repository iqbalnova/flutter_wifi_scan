package com.meisydevlab.flutter_wifi_scan

/**
 * OUI (Organizationally Unique Identifier) lookup utility
 * Maps the first 3 bytes of MAC address (BSSID) to manufacturer
 */
object OuiLookup {
    
    // Abbreviated OUI database with common manufacturers
    // In production, this could be loaded from assets or updated from network
    private val ouiMap = mapOf(
        "00:03:7F" to "Atheros",
        "00:0C:43" to "Ralink",
        "00:13:10" to "Linksys",
        "00:14:BF" to "D-Link",
        "00:18:E7" to "Cisco",
        "00:1B:2F" to "Belkin",
        "00:1C:10" to "Cisco",
        "00:1D:7E" to "Cisco-Linksys",
        "00:21:29" to "D-Link",
        "00:23:69" to "Cisco",
        "00:24:01" to "D-Link",
        "00:25:9C" to "Cisco",
        "00:50:56" to "VMware",
        "00:60:B3" to "Hewlett Packard",
        "08:00:27" to "Oracle VirtualBox",
        "0C:80:63" to "TP-Link",
        "10:BF:48" to "TP-Link",
        "14:CC:20" to "TP-Link",
        "18:D6:C7" to "TP-Link",
        "20:E5:2A" to "Tenda",
        "28:2C:B2" to "Edimax",
        "28:EE:52" to "TP-Link",
        "30:46:9A" to "Netgear",
        "3C:46:D8" to "TP-Link",
        "40:16:7E" to "Cisco",
        "44:D9:E7" to "TP-Link",
        "50:3E:AA" to "Asus",
        "50:C7:BF" to "TP-Link",
        "54:A0:50" to "Asus",
        "5C:62:8B" to "Tenda",
        "60:31:97" to "Netgear",
        "60:E3:27" to "TP-Link",
        "70:4D:7B" to "Netgear",
        "74:DA:88" to "TP-Link",
        "78:44:76" to "Netgear",
        "7C:8B:CA" to "TP-Link",
        "84:16:F9" to "TP-Link",
        "88:C3:97" to "Tenda",
        "8C:A6:DF" to "Netgear",
        "90:F6:52" to "TP-Link",
        "94:D9:B3" to "Tenda",
        "98:DE:D0" to "TP-Link",
        "9C:A2:F4" to "Netgear",
        "A0:F3:C1" to "TP-Link",
        "A4:2B:8C" to "TP-Link",
        "A8:40:41" to "Netgear",
        "AC:84:C6" to "TP-Link",
        "B0:48:7A" to "TP-Link",
        "B0:95:75" to "Netgear",
        "B8:27:EB" to "Raspberry Pi",
        "BC:46:99" to "Apple",
        "C0:25:E9" to "TP-Link",
        "C4:6E:1F" to "TP-Link",
        "C4:E9:84" to "TP-Link",
        "C8:3A:35" to "Tenda",
        "CC:2D:E0" to "Netgear",
        "D4:6E:0E" to "TP-Link",
        "D8:0D:17" to "TP-Link",
        "DC:9F:DB" to "Google",
        "E0:28:6D" to "TP-Link",
        "E4:9A:79" to "Cisco",
        "E8:94:F6" to "TP-Link",
        "EC:08:6B" to "TP-Link",
        "F0:72:8C" to "Xiaomi",
        "F4:EC:38" to "TP-Link",
        "F8:1A:67" to "TP-Link",
        "FC:EC:DA" to "TP-Link",
    )

    private const val DATABASE_VERSION = "2024-01-15"

    /**
     * Look up manufacturer from BSSID (MAC address)
     * @param bssid MAC address in format "XX:XX:XX:XX:XX:XX"
     * @return Manufacturer name or null if not found
     */
    fun lookup(bssid: String?): String? {
        if (bssid.isNullOrEmpty() || bssid.length < 8) return null
        
        // Extract first 3 octets (OUI)
        val oui = bssid.substring(0, 8).uppercase()
        return ouiMap[oui]
    }

    /**
     * Get the OUI database version
     */
    fun getVersion(): String = DATABASE_VERSION

    /**
     * Check if a manufacturer is in the database
     */
    fun contains(oui: String): Boolean {
        return ouiMap.containsKey(oui.uppercase())
    }

    /**
     * Get total number of manufacturers in database
     */
    fun size(): Int = ouiMap.size
}