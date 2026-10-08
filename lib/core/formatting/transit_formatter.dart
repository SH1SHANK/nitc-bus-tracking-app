/// Formatting utilities for transit status, distance, and timestamps.
class TransitFormatter {
  const TransitFormatter._();

  /// Formats an estimated time of arrival (in minutes or duration).
  static String formatEta(int minutes) {
    if (minutes <= 0) return 'Arriving now';
    if (minutes == 1) return '1 min';
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    if (remMinutes == 0) return '${hours}h';
    return '${hours}h ${remMinutes}m';
  }

  /// Formats walking time in minutes (e.g. "3 min walk").
  static String formatWalkingTime(int minutes) {
    if (minutes <= 1) return '1 min walk';
    return '$minutes mins walk';
  }

  /// Formats distance in meters or kilometers.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Formats speed in km/h.
  static String formatSpeed(double speedKmH) {
    return '${speedKmH.round()} km/h';
  }

  /// Formats relative update timestamp (e.g., "Updated just now", "Updated 2m ago").
  static String formatLastUpdated(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 15) return 'Live';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    return '${difference.inHours}h ago';
  }
}
