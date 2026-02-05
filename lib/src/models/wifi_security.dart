/// Wi-Fi security/capability types
class WiFiSecurity {
  final bool isOpen;
  final bool hasOwe;
  final bool hasWapi;
  final bool hasWep;
  final bool hasWpa;
  final bool hasWpa2;
  final bool hasWpa3;
  final bool hasEap;
  final String capabilities;

  const WiFiSecurity({
    required this.isOpen,
    required this.hasOwe,
    required this.hasWapi,
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

    final hasWep = caps.contains('WEP');
    final hasWpa = caps.contains('WPA-PSK') || caps.contains('WPA-');
    final hasWpa2 = caps.contains('WPA2');
    final hasWpa3 = caps.contains('WPA3') || caps.contains('SAE');
    final hasEap = caps.contains('EAP');
    final hasOwe = caps.contains('OWE');
    final hasWapi = caps.contains('WAPI');

    final isOpen =
        !hasWep &&
        !hasWpa &&
        !hasWpa2 &&
        !hasWpa3 &&
        !hasEap &&
        !hasOwe &&
        !hasWapi;

    return WiFiSecurity(
      isOpen: isOpen,
      hasOwe: hasOwe,
      hasWapi: hasWapi,
      hasWep: hasWep,
      hasWpa: hasWpa,
      hasWpa2: hasWpa2,
      hasWpa3: hasWpa3,
      hasEap: hasEap,
      capabilities: capabilities,
    );
  }

  /// Get a user-friendly security type string
  String get displayName {
    if (isOpen) return 'Open';
    if (hasWapi) return 'WAPI';
    if (hasOwe) return 'Enhanced Open (OWE)';
    if (hasWpa3 && hasEap) return 'WPA3-Enterprise';
    if (hasWpa3) return 'WPA3';
    if (hasWpa2 && hasWpa) return 'WPA/WPA2';
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
