const _uuidPattern =
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

/// Maps the app's versioned notification payload types to existing screens.
String notificationDestination(Map<String, dynamic>? data) {
  if (data == null) return '/notifications';

  bool hasValidIds(List<String> keys) => keys.every((key) {
    final value = data[key];
    return value is String && RegExp(_uuidPattern).hasMatch(value);
  });

  return switch (data['type']) {
    'arrival' when hasValidIds(['bus_id', 'stop_id', 'route_id']) =>
      '/notifications',
    'reminder' when hasValidIds(['reminder_id', 'stop_id']) => '/reminders',
    'announcement' when hasValidIds(['announcement_id']) => '/notifications',
    'disruption' when hasValidIds(['announcement_id', 'route_id']) =>
      '/notifications',
    _ => '/notifications',
  };
}
