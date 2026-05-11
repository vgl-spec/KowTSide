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
  if (names.isNotEmpty) {
    return [
      for (var index = 0; index < names.length; index++)
        AreaOption(areaId: index + 1, areaName: names[index]),
    ];
  }
  return [
    for (var index = 0; index < _fallbackAreaCatalog.length; index++)
      AreaOption(areaId: index + 1, areaName: _fallbackAreaCatalog[index]),
  ];
});

const List<String> _fallbackAreaCatalog = [
  'LAW STREET',
  'KIMCO VILLAGE',
  'WALING-WALING STREET',
  'VICTORIA SUBDIVISION',
  'SAMPAGUITA STREET',
  'DRJ VILLAGE',
  'LOWER SAUYO',
  'SPAZIO BERNARDO CONDOMINIUM',
  'VICTORIA STREET',
  'RICHLAND SUBDIVISION',
  'PASCUAL STREET',
  'GREENVILLE SUBDIVISION',
  'TEODORO COMPOUND',
  'DEL NACIA VILLE 4',
  'AREA 85',
  'NIA VILLAGE',
  'AREA 99',
  'OCEAN PARK',
  'AREA 135',
  'GREENVIEW ROYALE',
  'BISTEKVILLE 15',
  'GREENVIEW EXECUTIVE',
  'MARIAN EXTENSION',
  'BIR VILLAGE',
  'MARIAN SUBDIVISION',
  'VICTORIAN HEIGHTS',
  'MOZART EXTENSION',
  'VILLA HERMANO 1',
  'COMMERCIO',
  'VILLA HERMANO 2',
  'UPPER GULOD',
  'PRIVADA HOMES',
  'LOWER GULOD',
  'MERRY HOMES',
  'AREA 169',
  'ATHERTON',
  'AREA 160-168',
  'LAGKITAN',
  'DEL MUNDO COMPOUND',
  'HERMINIGILDO COMPOUND',
  'MABUHAY COMPOUND',
  'AREA 5A',
  'AREA 5B',
  'AREA 6A',
  'NAVAL',
  'VILLA ROSARIO',
  'LIPTON STREET',
  'OLD CABUYAO',
  'BALUYOT 1',
  'BALUYOT 2A',
  'BALUYOT 2B',
  'MONTINOLA',
  'BALUYOT PARK',
  'PAPELAN',
  'DAANG NAWASA',
];

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
