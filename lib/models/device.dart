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
