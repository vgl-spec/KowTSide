class SyncLogRecord {
  final String deviceUuid;
  final String deviceName;
  final String eventType;
  final String status;
  final String rawStatus;
  final String? studId;
  final DateTime? syncedAt;
  final int studentsSynced;
  final String? errorPayload;

  const SyncLogRecord({
    required this.deviceUuid,
    required this.deviceName,
    required this.eventType,
    required this.status,
    required this.rawStatus,
    required this.studId,
    required this.syncedAt,
    required this.studentsSynced,
    this.errorPayload,
  });

  factory SyncLogRecord.fromJson(Map<String, dynamic> json) {
    final normalizedStatus = _normalizeStatus(
      json['status'] ?? json['raw_status'],
    );

    return SyncLogRecord(
      deviceUuid:
          json['device_uuid'] as String? ??
          json['batch_id'] as String? ??
          'unknown',
      deviceName: json['device_name'] as String? ?? 'Unknown device',
      eventType: json['event_type'] as String? ?? 'sync_complete',
      status: normalizedStatus,
      rawStatus:
          (json['raw_status'] as String? ?? json['status'] as String? ?? '')
              .trim(),
      studId: json['stud_id'] as String?,
      syncedAt: _readDateTime(
        json['received_at'] ?? json['synced_at'] ?? json['last_synced_at'],
      ),
      studentsSynced:
          _readInt(json['students_synced']) ??
          _readInt(json['students_on_device']) ??
          0,
      errorPayload: json['error_payload'] as String?,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isSkipped => status == 'skipped';
}

class SyncLogsData {
  final List<SyncLogRecord> records;

  const SyncLogsData({required this.records});

  int get successCount => records.where((record) => record.isSuccess).length;
  int get failedCount => records.where((record) => record.isFailed).length;
  int get skippedCount => records.where((record) => record.isSkipped).length;

  double get successRate {
    if (records.isEmpty) return 0;
    return (successCount / records.length) * 100;
  }
}

class OraclePoolSnapshot {
  final int poolMin;
  final int poolMax;
  final int poolIncrement;
  final int connectionsOpen;
  final int connectionsInUse;

  const OraclePoolSnapshot({
    required this.poolMin,
    required this.poolMax,
    required this.poolIncrement,
    required this.connectionsOpen,
    required this.connectionsInUse,
  });

  factory OraclePoolSnapshot.fromJson(Map<String, dynamic> json) {
    return OraclePoolSnapshot(
      poolMin: _readInt(json['pool_min']) ?? 0,
      poolMax: _readInt(json['pool_max']) ?? 0,
      poolIncrement: _readInt(json['pool_increment']) ?? 0,
      connectionsOpen: _readInt(json['connections_open']) ?? 0,
      connectionsInUse: _readInt(json['connections_in_use']) ?? 0,
    );
  }
}

class OracleDetails {
  final bool connected;
  final int responseMs;
  final DateTime? dbTime;
  final OraclePoolSnapshot? pool;
  final String? error;

  const OracleDetails({
    required this.connected,
    required this.responseMs,
    required this.dbTime,
    required this.pool,
    required this.error,
  });

  factory OracleDetails.fromJson(Map<String, dynamic> json) {
    final poolMap = _readMap(json['pool']);
    return OracleDetails(
      connected:
          json['connected'] == true ||
          (json['status'] as String?) == 'connected',
      responseMs: _readInt(json['response_ms']) ?? 0,
      dbTime: _readDateTime(json['db_time']),
      pool: poolMap.isEmpty ? null : OraclePoolSnapshot.fromJson(poolMap),
      error: json['error'] as String?,
    );
  }
}

class SystemRowCounts {
  final int students;
  final int scores;
  final int activeQuestions;
  final int devices;
  final int syncedDevices;
  final int syncLogs;
  final int admins;

  const SystemRowCounts({
    required this.students,
    required this.scores,
    required this.activeQuestions,
    required this.devices,
    required this.syncedDevices,
    required this.syncLogs,
    required this.admins,
  });

  factory SystemRowCounts.fromJson(Map<String, dynamic> json) {
    return SystemRowCounts(
      students: _readInt(json['students']) ?? 0,
      scores: _readInt(json['scores']) ?? 0,
      activeQuestions: _readInt(json['active_questions']) ?? 0,
      devices: _readInt(json['devices']) ?? 0,
      syncedDevices: _readInt(json['synced_devices']) ?? 0,
      syncLogs: _readInt(json['sync_logs']) ?? 0,
      admins: _readInt(json['admins']) ?? 0,
    );
  }
}

class ObjectStatusSummary {
  final String objectType;
  final String status;
  final int count;

  const ObjectStatusSummary({
    required this.objectType,
    required this.status,
    required this.count,
  });

  factory ObjectStatusSummary.fromJson(Map<String, dynamic> json) {
    return ObjectStatusSummary(
      objectType: json['object_type'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'UNKNOWN',
      count: _readInt(json['count']) ?? 0,
    );
  }
}

class CriticalObjectStatus {
  final String objectName;
  final String objectType;
  final String status;
  final DateTime? lastDdlTime;

  const CriticalObjectStatus({
    required this.objectName,
    required this.objectType,
    required this.status,
    required this.lastDdlTime,
  });

  factory CriticalObjectStatus.fromJson(Map<String, dynamic> json) {
    return CriticalObjectStatus(
      objectName: json['object_name'] as String? ?? 'Unknown',
      objectType: json['object_type'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'UNKNOWN',
      lastDdlTime: _readDateTime(json['last_ddl_time']),
    );
  }
}

class SystemHealthData {
  final String status;
  final String oracle;
  final OracleDetails oracleDetails;
  final int wsClients;
  final int uptimeSeconds;
  final DateTime? timestamp;
  final int activeDevices;
  final int syncedDevices;
  final int rssBytes;
  final int heapUsedBytes;
  final int heapTotalBytes;
  final SystemRowCounts rowCounts;
  final List<ObjectStatusSummary> objectStatusSummary;
  final List<CriticalObjectStatus> criticalObjects;

  const SystemHealthData({
    required this.status,
    required this.oracle,
    required this.oracleDetails,
    required this.wsClients,
    required this.uptimeSeconds,
    required this.timestamp,
    required this.activeDevices,
    required this.syncedDevices,
    required this.rssBytes,
    required this.heapUsedBytes,
    required this.heapTotalBytes,
    required this.rowCounts,
    required this.objectStatusSummary,
    required this.criticalObjects,
  });

  factory SystemHealthData.fromJson(Map<String, dynamic> json) {
    final oracleField = json['oracle'];
    final oracleDetailsMap = _readMap(json['oracle_details']);
    final memory = _readMap(json['memory']);
    final rowCountsMap = _readMap(json['row_counts']);

    final effectiveOracle = oracleField is String
        ? oracleField
        : (oracleDetailsMap['connected'] == true
              ? 'connected'
              : 'disconnected');

    return SystemHealthData(
      status: json['status'] as String? ?? 'degraded',
      oracle: effectiveOracle,
      oracleDetails: OracleDetails.fromJson({
        'connected': effectiveOracle == 'connected',
        ...oracleDetailsMap,
      }),
      wsClients: _readInt(json['ws_clients']) ?? 0,
      uptimeSeconds: _readInt(json['uptime_seconds']) ?? 0,
      timestamp: _readDateTime(
        json['checked_at'] ?? json['timestamp'] ?? oracleDetailsMap['db_time'],
      ),
      activeDevices:
          _readInt(json['active_devices']) ??
          _readInt(rowCountsMap['devices']) ??
          0,
      syncedDevices:
          _readInt(json['synced_devices']) ??
          _readInt(rowCountsMap['synced_devices']) ??
          0,
      rssBytes: _readInt(memory['rss_bytes']) ?? 0,
      heapUsedBytes: _readInt(memory['heap_used_bytes']) ?? 0,
      heapTotalBytes: _readInt(memory['heap_total_bytes']) ?? 0,
      rowCounts: SystemRowCounts.fromJson(rowCountsMap),
      objectStatusSummary: _readList(
        json['object_status_summary'],
      ).map(ObjectStatusSummary.fromJson).toList(),
      criticalObjects: _readList(
        json['critical_objects'],
      ).map(CriticalObjectStatus.fromJson).toList(),
    );
  }

  bool get apiHealthy => status == 'ok';
  bool get dbHealthy => oracle == 'connected' || oracleDetails.connected;
  bool get wsHealthy => wsClients > 0;

  int get invalidObjectCount => objectStatusSummary
      .where((item) => item.status.toUpperCase() != 'VALID')
      .fold<int>(0, (sum, item) => sum + item.count);
}

String _normalizeStatus(Object? value) {
  final normalized = (value as String? ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'processed':
    case 'completed':
    case 'success':
      return 'success';
    case 'failed':
    case 'error':
      return 'failed';
    case 'skipped':
    case 'noop':
      return 'skipped';
    default:
      return normalized.isEmpty ? 'success' : normalized;
  }
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }
  return const [];
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
