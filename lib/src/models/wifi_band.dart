/// Wi-Fi frequency band
enum WiFiBand {
  /// 2.4 GHz band
  band24GHz,

  /// 5 GHz band
  band5GHz,

  /// 6 GHz band (Wi-Fi 6E)
  band6GHz,

  /// Unknown or unsupported band
  unknown;

  /// Parse from frequency in MHz
  static WiFiBand fromFrequency(int frequency) {
    if (frequency >= 2400 && frequency < 2500) {
      return WiFiBand.band24GHz;
    } else if (frequency >= 5000 && frequency < 6000) {
      return WiFiBand.band5GHz;
    } else if (frequency >= 5925 && frequency < 7125) {
      return WiFiBand.band6GHz;
    }
    return WiFiBand.unknown;
  }

  String get displayName {
    switch (this) {
      case WiFiBand.band24GHz:
        return '2.4 GHz';
      case WiFiBand.band5GHz:
        return '5 GHz';
      case WiFiBand.band6GHz:
        return '6 GHz';
      case WiFiBand.unknown:
        return 'Unknown';
    }
  }
}
