import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard.dart';
import '../models/student.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/reporting.dart';

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.leaderboard();
  }

  final response = await dio.get(ApiConstants.leaderboard);
  final list =
      response.data['leaderboard'] as List? ??
      response.data['data'] as List? ??
      response.data as List? ??
      const <dynamic>[];

  return list
      .map((entry) => LeaderboardEntry.fromJson(entry as Map<String, dynamic>))
      .toList();
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
    final data = _readMap(response.data);
    if (data.isNotEmpty) {
      final dashboard = DashboardData.fromJson(
        _enrichDashboardMap(
          _readMap(data['dashboard'] ?? data['summary'] ?? data),
          data,
        ),
      );
      final students = _readList(
        data['students'] ?? data['learners'],
      ).map(Student.fromJson).toList();
      final leaderboard = _readList(
        data['leaderboard'] ?? data['top_learners'],
      ).map(LeaderboardEntry.fromJson).toList();
      final effectiveStudents = students.isNotEmpty
          ? students
          : _studentsFromLeaderboard(leaderboard);

      if (effectiveStudents.isNotEmpty || leaderboard.isNotEmpty) {
        return ReportsSnapshot(
          dashboard: dashboard,
          students: effectiveStudents,
          leaderboard: leaderboard,
        );
      }
    }
  } catch (_) {
    // Fall back to existing DB-backed endpoints when dedicated reports endpoint
    // is unavailable or partially implemented.
  }

  final responses = await Future.wait([
    dio.get(ApiConstants.dashboard),
    dio.get(ApiConstants.students),
    dio.get(ApiConstants.leaderboard),
  ]);

  final dashboardData = _readMap(responses[0].data);
  final studentsData = _readList(
    _readMap(responses[1].data)['students'] ?? responses[1].data,
  );
  final leaderboardData = _readList(
    _readMap(responses[2].data)['leaderboard'] ?? responses[2].data,
  );

  final leaderboard = leaderboardData.map(LeaderboardEntry.fromJson).toList();
  final students = studentsData.map(Student.fromJson).toList();

  return ReportsSnapshot(
    dashboard: DashboardData.fromJson(
      _enrichDashboardMap(dashboardData, dashboardData),
    ),
    students: students.isNotEmpty
        ? students
        : _studentsFromLeaderboard(leaderboard),
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
    return {
      ...dashboard,
      'age_group_progress': derived,
    };
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
      (sum, row) => sum + (_readInt(row['student_groups']) ?? _readInt(row['active_students']) ?? 0),
    );

    final weights = rowsForGroup
        .map((row) => (_readInt(row['student_groups']) ?? _readInt(row['active_students']) ?? 0).toDouble())
        .toList();

    return <String, dynamic>{
      'gradelvl': _normalizeGradeLevelLabel(sample['gradelvl']),
      'subject': sample['subject'] as String? ?? '',
      'active_students': totalStudents,
      'avg_score': _weightedAverage(
        rowsForGroup.map((row) => _readDouble(row['avg_score']) ?? 0.0).toList(),
        weights,
      ),
      'pass_rate_pct': _weightedAverage(
        rowsForGroup.map((row) => _readDouble(row['pass_rate_pct']) ?? 0.0).toList(),
        weights,
      ),
    };
  }).toList();
}

double _weightedAverage(List<double> values, List<double> weights) {
  if (values.isEmpty || weights.isEmpty || values.length != weights.length) {
    return 0.0;
  }

  final totalWeight = weights.fold<double>(0.0, (sum, weight) => sum + weight);
  if (totalWeight <= 0) {
    return values.fold<double>(0.0, (sum, value) => sum + value) / values.length;
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
  if (lower.contains('punla')) {
    return 'Punla (4-5)';
  }
  if (lower.contains('binhi')) {
    return 'Binhi (6-7)';
  }
  return label;
}
List<Student> _studentsFromLeaderboard(List<LeaderboardEntry> leaderboard) {
  return leaderboard.map((entry) {
    final nameParts = entry.fullName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : entry.nickname;
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    final avgScore = entry.sessions <= 0
        ? 0.0
        : entry.totalScore / entry.sessions;

    return Student(
      studId: entry.studId,
      nickname: entry.nickname,
      firstName: firstName,
      lastName: lastName,
      area: '',
      birthday: '',
      age: 0,
      gradelvl: entry.gradelvl,
      sex: '',
      totalSessions: entry.sessions,
      avgScore: avgScore,
      proficiency: _proficiencyFor(avgScore),
    );
  }).toList();
}

String _proficiencyFor(double avgScore) {
  if (avgScore >= 9.0) return 'Excelling';
  if (avgScore >= 7.0) return 'On track';
  if (avgScore >= 5.0) return 'Needs support';
  return 'Needs significant support';
}
