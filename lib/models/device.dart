class Device {
  final String deviceUuid;
  final String deviceName;
  final String registeredAt;
  final String? lastSyncedAt;
  final int studentsOnDevice;

  const Device({
    required this.deviceUuid,
    required this.deviceName,
    required this.registeredAt,
    this.lastSyncedAt,
    required this.studentsOnDevice,
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        deviceUuid: j['device_uuid'] as String? ?? '',
        deviceName: j['device_name'] as String? ?? 'Unknown Device',
        registeredAt: j['registered_at'] as String? ?? '',
        lastSyncedAt: j['last_synced_at'] as String?,
        studentsOnDevice: j['students_on_device'] as int? ?? 0,
      );

  bool get hasSynced => lastSyncedAt != null && lastSyncedAt!.isNotEmpty;
}

class DevicePage {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<Device> devices;

  const DevicePage({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.devices,
  });

  factory DevicePage.fromJson(Map<String, dynamic> json) {
    final list =
        json['devices'] as List? ?? json['data'] as List? ?? const <dynamic>[];
    final total = _readInt(json['total']) ?? list.length;
    final rawLimit = _readInt(json['limit']) ?? list.length;
    final limit = rawLimit <= 0 ? 1 : rawLimit;
    final totalPages =
        _readInt(json['total_pages']) ??
        (total == 0 ? 1 : ((total + limit - 1) ~/ limit));

    return DevicePage(
      page: _readInt(json['page']) ?? 1,
      limit: limit,
      total: total,
      totalPages: totalPages < 1 ? 1 : totalPages,
      devices: list
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
