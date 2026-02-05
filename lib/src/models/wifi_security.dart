/// Wi-Fi security/capability types
class WiFiSecurity {
  final bool isOpen;
  final bool hasWep;
  final bool hasWpa;
  final bool hasWpa2;
  final bool hasWpa3;
  final bool hasEap;
  final String capabilities;

  const WiFiSecurity({
    required this.isOpen,
    required this.hasWep,
    required this.hasWpa,
    required this.hasWpa2,
    required this.hasWpa3,
    required this.hasEap,
    required this.capabilities,
  });

  /// Parse security from Android capability string
  factory WiFiSecurity.fromCapabilities(String capabilities) {
    final caps = capabilities.toUpperCase();

    return WiFiSecurity(
      isOpen:
          !caps.contains('WEP') &&
          !caps.contains('WPA') &&
          !caps.contains('EAP'),
      hasWep: caps.contains('WEP'),
      hasWpa: caps.contains('WPA-PSK') && !caps.contains('WPA2'),
      hasWpa2: caps.contains('WPA2'),
      hasWpa3: caps.contains('WPA3') || caps.contains('SAE'),
      hasEap: caps.contains('EAP'),
      capabilities: capabilities,
    );
  }

  /// Get a user-friendly security type string
  String get displayName {
    if (isOpen) return 'Open';
    if (hasWpa3) return 'WPA3';
    if (hasWpa2) return 'WPA2';
    if (hasWpa) return 'WPA';
    if (hasWep) return 'WEP';
    if (hasEap) return 'Enterprise';
    return 'Secured';
  }

  /// Get security strength indicator (0-3: weak to strong)
  int get strength {
    if (isOpen) return 0;
    if (hasWep) return 1;
    if (hasWpa || hasWpa2) return 2;
    if (hasWpa3) return 3;
    return 2;
  }

  @override
  String toString() => displayName;
}
