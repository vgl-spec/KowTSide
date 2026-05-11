import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import 'students_provider.dart';

class AreaOption {
  final int areaId;
  final String areaName;

  const AreaOption({required this.areaId, required this.areaName});
}

final areaOptionsProvider = FutureProvider<List<AreaOption>>((ref) async {
  if (ApiConstants.frontendOnly) {
    final students = await ref.watch(studentsProvider.future);
    final names =
        students
            .map((student) => student.area.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [
      for (var index = 0; index < names.length; index++)
        AreaOption(areaId: index + 1, areaName: names[index]),
    ];
  }

  try {
    final response = await dio.get(ApiConstants.areas);
    final payload = _readMap(response.data);
    final list =
        payload['areas'] as List? ?? payload['data'] as List? ?? const [];
    final rows = list
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map((entry) {
          final areaId = _readInt(entry['area_id'] ?? entry['areaId']) ?? 0;
          final name =
              (entry['area_nm'] ?? entry['areaName'] ?? entry['area'] ?? '')
                  .toString()
                  .trim();
          return AreaOption(areaId: areaId, areaName: name);
        })
        .where((entry) => entry.areaId > 0 && entry.areaName.isNotEmpty)
        .toList(growable: false);
    if (rows.isNotEmpty) {
      final deduped = <int, AreaOption>{};
      for (final row in rows) {
        deduped[row.areaId] = row;
      }
      return deduped.values.toList()
        ..sort((a, b) => a.areaId.compareTo(b.areaId));
    }
  } on DioException catch (_) {}

  final students = await ref.watch(studentsProvider.future);
  final names =
      students
          .map((student) => student.area.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [
    for (var index = 0; index < names.length; index++)
      AreaOption(areaId: index + 1, areaName: names[index]),
  ];
});

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, dynamic>{};
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
