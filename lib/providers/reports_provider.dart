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
        _readMap(data['dashboard'] ?? data['summary'] ?? data),
      );
      final students = _readList(
        data['students'] ?? data['learners'],
      ).map(Student.fromJson).toList();
      final leaderboard = _readList(
        data['leaderboard'] ?? data['top_learners'],
      ).map(LeaderboardEntry.fromJson).toList();

      if (students.isNotEmpty || leaderboard.isNotEmpty) {
        return ReportsSnapshot(
          dashboard: dashboard,
          students: students,
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

  return ReportsSnapshot(
    dashboard: DashboardData.fromJson(dashboardData),
    students: studentsData.map(Student.fromJson).toList(),
    leaderboard: leaderboardData.map(LeaderboardEntry.fromJson).toList(),
  );
});

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
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
