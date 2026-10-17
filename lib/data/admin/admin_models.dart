import 'package:flutter/foundation.dart';

/// Operational overview metrics returned by `GET /api/v1/admin/overview`.
@immutable
class AdminOverview {
  const AdminOverview({
    required this.totalDevices,
    required this.activeDevices,
    required this.inactiveDevices,
    required this.onlineDevices,
    required this.staleDevices,
    required this.offlineDevices,
    required this.totalBuses,
    required this.activeBuses,
    required this.telemetryLastReceivedAt,
    required this.databaseConnected,
    required this.uptimeSeconds,
  });

  final int totalDevices;
  final int activeDevices;
  final int inactiveDevices;
  final int onlineDevices;
  final int staleDevices;
  final int offlineDevices;
  final int totalBuses;
  final int activeBuses;
  final DateTime? telemetryLastReceivedAt;
  final bool databaseConnected;
  final double uptimeSeconds;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    return AdminOverview(
      totalDevices: (json['total_devices'] as num?)?.toInt() ?? 0,
      activeDevices: (json['active_devices'] as num?)?.toInt() ?? 0,
      inactiveDevices: (json['inactive_devices'] as num?)?.toInt() ?? 0,
      onlineDevices: (json['online_devices'] as num?)?.toInt() ?? 0,
      staleDevices: (json['stale_devices'] as num?)?.toInt() ?? 0,
      offlineDevices: (json['offline_devices'] as num?)?.toInt() ?? 0,
      totalBuses: (json['total_buses'] as num?)?.toInt() ?? 0,
      activeBuses: (json['active_buses'] as num?)?.toInt() ?? 0,
      telemetryLastReceivedAt:
          json['telemetry_last_received_at'] != null
              ? DateTime.tryParse(json['telemetry_last_received_at'].toString())
              : null,
      databaseConnected: json['database_connected'] as bool? ?? false,
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Last known position of a device in admin inventory.
@immutable
class AdminDevicePosition {
  const AdminDevicePosition({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.seq,
    required this.epoch,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final int seq;
  final int epoch;
  final DateTime recordedAt;

  factory AdminDevicePosition.fromJson(Map<String, dynamic> json) {
    return AdminDevicePosition(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      epoch: (json['epoch'] as num?)?.toInt() ?? 1,
      recordedAt:
          DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now(),
    );
  }
}

/// Safe inventory view of a registered device.
@immutable
class AdminDevice {
  const AdminDevice({
    required this.id,
    required this.deviceId,
    this.busId,
    this.busNumber,
    this.busLabel,
    required this.isActive,
    required this.currentEpoch,
    this.firmwareVersion,
    required this.createdAt,
    this.lastSeenAt,
    this.lastPosition,
  });

  final String id;
  final String deviceId;
  final String? busId;
  final String? busNumber;
  final String? busLabel;
  final bool isActive;
  final int currentEpoch;
  final String? firmwareVersion;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final AdminDevicePosition? lastPosition;

  factory AdminDevice.fromJson(Map<String, dynamic> json) {
    return AdminDevice(
      id: json['id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      busId: json['bus_id'] as String?,
      busNumber: json['bus_number'] as String?,
      busLabel: json['bus_label'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      currentEpoch: (json['current_epoch'] as num?)?.toInt() ?? 1,
      firmwareVersion: json['firmware_version'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      lastSeenAt:
          json['last_seen_at'] != null
              ? DateTime.tryParse(json['last_seen_at'].toString())
              : null,
      lastPosition:
          json['last_position'] != null &&
                  json['last_position'] is Map<String, dynamic>
              ? AdminDevicePosition.fromJson(
                json['last_position'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// Result of registering a new tracking device (includes one-time revealed secret).
@immutable
class DeviceRegistrationResult {
  const DeviceRegistrationResult({
    required this.device,
    required this.generatedSecret,
    required this.message,
  });

  final AdminDevice device;
  final String generatedSecret;
  final String message;

  factory DeviceRegistrationResult.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResult(
      device: AdminDevice.fromJson(json['device'] as Map<String, dynamic>),
      generatedSecret: json['generated_secret'] as String? ?? '',
      message: json['message'] as String? ?? 'Device registered successfully',
    );
  }
}

/// Tracker diagnostics snapshot in Live Debug Console.
@immutable
class TrackerDebugItem {
  const TrackerDebugItem({
    required this.deviceId,
    required this.busNumber,
    this.routeName,
    required this.isActive,
    required this.epoch,
    required this.seq,
    required this.freshness,
    this.lastSeenAt,
    this.currentPosition,
    this.recentBreadcrumbs = const [],
  });

  final String deviceId;
  final String busNumber;
  final String? routeName;
  final bool isActive;
  final int epoch;
  final int seq;
  final String freshness; // 'online' | 'stale' | 'offline'
  final DateTime? lastSeenAt;
  final Map<String, dynamic>? currentPosition;
  final List<AdminDevicePosition> recentBreadcrumbs;

  factory TrackerDebugItem.fromJson(Map<String, dynamic> json) {
    final breadcrumbsList =
        (json['recent_breadcrumbs'] as List<dynamic>?)
            ?.map(
              (b) => AdminDevicePosition.fromJson(b as Map<String, dynamic>),
            )
            .toList() ??
        const [];

    return TrackerDebugItem(
      deviceId: json['device_id'] as String? ?? '',
      busNumber: json['bus_number'] as String? ?? '',
      routeName: json['route_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      epoch: (json['epoch'] as num?)?.toInt() ?? 1,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      freshness: json['freshness'] as String? ?? 'offline',
      lastSeenAt:
          json['last_seen_at'] != null
              ? DateTime.tryParse(json['last_seen_at'].toString())
              : null,
      currentPosition: json['current_position'] as Map<String, dynamic>?,
      recentBreadcrumbs: breadcrumbsList,
    );
  }
}

/// Detailed health check indicator.
@immutable
class DetailedHealth {
  const DetailedHealth({
    required this.apiStatus,
    required this.uptimeSeconds,
    required this.heapUsedMb,
    required this.heapTotalMb,
    required this.rssMb,
    required this.nodeVersion,
    required this.dbStatus,
    required this.dbLatencyMs,
    required this.dbConnected,
    required this.totalRecordsRecorded,
    this.lastPacketAgeSeconds,
    required this.telemetryHealthy,
    required this.fleetTotal,
    required this.fleetOnline,
    required this.fleetStale,
    required this.fleetOffline,
    required this.timestamp,
  });

  final String apiStatus;
  final double uptimeSeconds;
  final double heapUsedMb;
  final double heapTotalMb;
  final double rssMb;
  final String nodeVersion;

  final String dbStatus;
  final double dbLatencyMs;
  final bool dbConnected;

  final int totalRecordsRecorded;
  final double? lastPacketAgeSeconds;
  final bool telemetryHealthy;

  final int fleetTotal;
  final int fleetOnline;
  final int fleetStale;
  final int fleetOffline;

  final DateTime timestamp;

  factory DetailedHealth.fromJson(Map<String, dynamic> json) {
    final api = (json['api'] as Map<String, dynamic>?) ?? {};
    final memory = (api['memory'] as Map<String, dynamic>?) ?? {};
    final db = (json['database'] as Map<String, dynamic>?) ?? {};
    final telemetry = (json['telemetry'] as Map<String, dynamic>?) ?? {};
    final fleet = (json['fleet'] as Map<String, dynamic>?) ?? {};

    return DetailedHealth(
      apiStatus: api['status'] as String? ?? 'unknown',
      uptimeSeconds: (api['uptime_seconds'] as num?)?.toDouble() ?? 0.0,
      heapUsedMb: (memory['heap_used_mb'] as num?)?.toDouble() ?? 0.0,
      heapTotalMb: (memory['heap_total_mb'] as num?)?.toDouble() ?? 0.0,
      rssMb: (memory['rss_mb'] as num?)?.toDouble() ?? 0.0,
      nodeVersion: api['node_version'] as String? ?? '',
      dbStatus: db['status'] as String? ?? 'unknown',
      dbLatencyMs: (db['latency_ms'] as num?)?.toDouble() ?? 0.0,
      dbConnected: db['connected'] as bool? ?? false,
      totalRecordsRecorded:
          (telemetry['total_records_recorded'] as num?)?.toInt() ?? 0,
      lastPacketAgeSeconds:
          (telemetry['last_packet_age_seconds'] as num?)?.toDouble(),
      telemetryHealthy: telemetry['healthy'] as bool? ?? false,
      fleetTotal: (fleet['total'] as num?)?.toInt() ?? 0,
      fleetOnline: (fleet['online'] as num?)?.toInt() ?? 0,
      fleetStale: (fleet['stale'] as num?)?.toInt() ?? 0,
      fleetOffline: (fleet['offline'] as num?)?.toInt() ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now(),
    );
  }
}

/// Audit log record for administrative operations.
@immutable
class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.action,
    required this.targetType,
    this.targetId,
    required this.details,
    this.ipAddress,
    required this.adminEmail,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final String adminEmail;
  final DateTime createdAt;

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String?,
      details: (json['details'] as Map<String, dynamic>?) ?? {},
      ipAddress: json['ip_address'] as String?,
      adminEmail: json['admin_email'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }
}

/// Administrator allowlist member.
@immutable
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? notes;
  final DateTime createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }
}
