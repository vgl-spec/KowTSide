import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/system_monitoring.dart';

final syncLogsProvider = FutureProvider<SyncLogsData>((ref) async {
  if (ApiConstants.frontendOnly) {
    final records = MockData.devices()
        .map(
          (device) => SyncLogRecord(
            deviceUuid: device.deviceUuid,
            deviceName: device.deviceName,
            eventType: 'sync_complete',
            status: 'success',
            rawStatus: 'success',
            studId: null,
            syncedAt: DateTime.tryParse(device.lastSyncedAt ?? ''),
            studentsSynced: device.studentsOnDevice,
          ),
        )
        .toList();
    return SyncLogsData(records: records);
  }

  try {
    final response = await dio.get(ApiConstants.syncLogs);
    final list = _readList(
      response.data,
      keys: const ['logs', 'sync_logs', 'records', 'data'],
    );
    return SyncLogsData(
      records: list.map((entry) => SyncLogRecord.fromJson(entry)).toList()
        ..sort(
          (a, b) => (b.syncedAt ?? DateTime(1970)).compareTo(
            a.syncedAt ?? DateTime(1970),
          ),
        ),
    );
  } on DioException catch (error) {
    final code = error.response?.statusCode;
    if (code != 404 && code != 405) {
      rethrow;
    }
  }

  final dashboardResponse = await dio.get(ApiConstants.dashboard);
  final recentSyncs = _readList(
    dashboardResponse.data,
    keys: const ['recent_syncs'],
  );
  if (recentSyncs.isNotEmpty) {
    return SyncLogsData(
      records:
          recentSyncs.map((entry) => SyncLogRecord.fromJson(entry)).toList()
            ..sort(
              (a, b) => (b.syncedAt ?? DateTime(1970)).compareTo(
                a.syncedAt ?? DateTime(1970),
              ),
            ),
    );
  }

  final devicesResponse = await dio.get(ApiConstants.devices);
  final devices = _readList(devicesResponse.data, keys: const ['devices']);
  return SyncLogsData(
    records: devices.map((entry) => SyncLogRecord.fromJson(entry)).toList()
      ..sort(
        (a, b) => (b.syncedAt ?? DateTime(1970)).compareTo(
          a.syncedAt ?? DateTime(1970),
        ),
      ),
  );
});

final systemHealthProvider = FutureProvider<SystemHealthData>((ref) async {
  if (ApiConstants.frontendOnly) {
    return SystemHealthData(
      status: 'ok',
      oracle: 'connected',
      oracleDetails: const OracleDetails(
        connected: true,
        responseMs: 42,
        dbTime: null,
        pool: null,
        error: null,
      ),
      wsClients: 3,
      uptimeSeconds: 86400,
      timestamp: DateTime.now(),
      activeDevices: MockData.devices().length,
      syncedDevices: MockData.devices().length,
      rssBytes: 134217728,
      heapUsedBytes: 50331648,
      heapTotalBytes: 83886080,
      rowCounts: SystemRowCounts(
        students: MockData.students().length,
        scores: MockData.dashboard().totalScores,
        activeQuestions: MockData.questions().where((q) => q.isActive).length,
        devices: MockData.devices().length,
        syncedDevices: MockData.devices().length,
        syncLogs: MockData.devices().length,
        admins: 1,
      ),
      objectStatusSummary: const [],
      criticalObjects: const [],
    );
  }

  try {
    final response = await dio.get(ApiConstants.systemHealth);
    final data = _readMap(response.data);
    if (data.isNotEmpty) {
      return SystemHealthData.fromJson(data);
    }
  } on DioException catch (error) {
    final code = error.response?.statusCode;
    if (code != 404 && code != 405) {
      rethrow;
    }
  }

  final responses = await Future.wait([
    dio.get(ApiConstants.health),
    dio.get(ApiConstants.devices),
  ]);

  final health = _readMap(responses[0].data);
  final devices = _readList(responses[1].data, keys: const ['devices']);

  final activeDevices = devices.length;
  final syncedDevices = devices.where((device) {
    final syncedAt = device['last_synced_at'] as String?;
    return syncedAt != null && syncedAt.isNotEmpty;
  }).length;

  return SystemHealthData.fromJson({
    ...health,
    'active_devices': activeDevices,
    'synced_devices': syncedDevices,
    'row_counts': {'devices': activeDevices, 'synced_devices': syncedDevices},
  });
});

Map<String, dynamic> _readMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readList(
  Object? data, {
  required List<String> keys,
}) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    final directData = data['data'];
    if (directData is List) {
      return directData
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
  }
  if (data is Map) {
    final asMap = data.map((key, entry) => MapEntry(key.toString(), entry));
    for (final key in keys) {
      final value = asMap[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
  }
  return const [];
}
