import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/dashboard.dart';
import '../models/student.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/reporting.dart';
import 'reporting_fallbacks.dart';
import 'students_provider.dart';

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.leaderboard();
  }

  final students = await ref.watch(studentsProvider.future);
  return buildLeaderboardFromStudents(students);
});

final reportsSnapshotProvider = FutureProvider<ReportsSnapshot>((ref) async {
  if (ApiConstants.frontendOnly) {
    return ReportsSnapshot(
      dashboard: MockData.dashboard(),
      students: MockData.students(),
      leaderboard: MockData.leaderboard(),
    );
  }

  try {
    final response = await dio.get(ApiConstants.reports);
    final payload = _readMap(response.data);
    final dashboardMap = _readMap(payload['dashboard']).isNotEmpty
        ? _readMap(payload['dashboard'])
        : payload;
    final students = _readList(
      payload['students'],
    ).map(Student.fromJson).toList();
    final leaderboard = _readList(
      payload['leaderboard'],
    ).map(LeaderboardEntry.fromJson).toList();

    return ReportsSnapshot(
      dashboard: DashboardData.fromJson(
        _enrichDashboardMap(dashboardMap, payload),
      ),
      students: students,
      leaderboard: leaderboard.isNotEmpty
          ? leaderboard
          : buildLeaderboardFromStudents(students),
    );
  } on DioException catch (error) {
    final code = error.response?.statusCode;
    if (code != 404 && code != 405) {
      rethrow;
    }
  }

  final responses = await Future.wait([
    dio.get(ApiConstants.dashboard),
    dio.get(
      ApiConstants.students,
      queryParameters: const {'page': 1, 'limit': 100},
    ),
  ]);

  final dashboardData = _readMap(responses[0].data);
  final studentsData = _readList(
    _readMap(responses[1].data)['students'] ?? responses[1].data,
  );

  final students = studentsData.map(Student.fromJson).toList();
  final leaderboard = buildLeaderboardFromStudents(students);

  return ReportsSnapshot(
    dashboard: DashboardData.fromJson(
      _enrichDashboardMap(dashboardData, dashboardData),
    ),
    students: students.isNotEmpty
        ? students
        : leaderboard.map(studentFromLeaderboard).toList(),
    leaderboard: leaderboard,
  );
});

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
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

Map<String, dynamic> _enrichDashboardMap(
  Map<String, dynamic> dashboard,
  Map<String, dynamic> source,
) {
  final existingAgeRows = dashboard['age_group_progress'];
  if (existingAgeRows is List && existingAgeRows.isNotEmpty) {
    return dashboard;
  }

  final derived = _deriveAgeGroupProgress(source['subject_level_summary']);
  if (derived.isNotEmpty) {
    return {...dashboard, 'age_group_progress': derived};
  }

  return dashboard;
}

List<Map<String, dynamic>> _deriveAgeGroupProgress(Object? value) {
  final rows = _readList(value);
  if (rows.isEmpty) {
    return const [];
  }

  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final row in rows) {
    final gradelvl = _normalizeGradeLevelLabel(row['gradelvl']);
    final subject = (row['subject'] as String? ?? '').trim();
    final key = '$gradelvl|$subject';
    grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(row);
  }

  return grouped.entries.map((entry) {
    final rowsForGroup = entry.value;
    final sample = rowsForGroup.first;
    final totalStudents = rowsForGroup.fold<int>(
      0,
      (sum, row) =>
          sum +
          (_readInt(row['student_groups']) ??
              _readInt(row['active_students']) ??
              0),
    );

    final weights = rowsForGroup
        .map<double>(
          (row) =>
              (_readInt(row['student_groups']) ??
                      _readInt(row['active_students']) ??
                      0)
                  .toDouble(),
        )
        .toList(growable: false);

    final avgScores = rowsForGroup
        .map<double>((row) => _readDouble(row['avg_score']) ?? 0.0)
        .toList(growable: false);

    final passRates = rowsForGroup
        .map<double>((row) => _readDouble(row['pass_rate_pct']) ?? 0.0)
        .toList(growable: false);

    return <String, dynamic>{
      'gradelvl': _normalizeGradeLevelLabel(sample['gradelvl']),
      'subject': sample['subject'] as String? ?? '',
      'active_students': totalStudents,
      'avg_score': _weightedAverage(avgScores, weights),
      'pass_rate_pct': _weightedAverage(passRates, weights),
    };
  }).toList();
}

double _weightedAverage(List<double> values, List<double> weights) {
  if (values.isEmpty || weights.isEmpty || values.length != weights.length) {
    return 0.0;
  }

  final totalWeight = weights.fold<double>(0.0, (sum, weight) => sum + weight);
  if (totalWeight <= 0) {
    return values.fold<double>(0.0, (sum, value) => sum + value) /
        values.length;
  }

  var weightedSum = 0.0;
  for (var index = 0; index < values.length; index++) {
    weightedSum += values[index] * weights[index];
  }
  return weightedSum / totalWeight;
}

String _normalizeGradeLevelLabel(Object? value) {
  final label = (value as String?)?.trim() ?? '';
  final lower = label.toLowerCase();
  if (lower.contains('(4-5)') || lower.contains('(6-7)')) {
    return label;
  }
  if (lower.contains('binhi')) {
    return 'Binhi (4-5)';
  }
  if (lower.contains('punla')) {
    return 'Punla (6-7)';
  }
  return label;
}
