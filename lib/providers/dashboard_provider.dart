import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/dashboard.dart';
import '../models/question.dart';
import '../models/reporting.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.dashboard();
  }
  final timer = Timer.periodic(const Duration(seconds: 20), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final resp = await dio.get(ApiConstants.dashboard);
  final data =
      resp.data['data'] as Map<String, dynamic>? ??
      resp.data as Map<String, dynamic>;
  final dashboard = DashboardData.fromJson(data);
  if (dashboard.poolHealth.isNotEmpty &&
      dashboard.ageGroupProgress.isNotEmpty) {
    return dashboard;
  }

  final fallbackResponses = await Future.wait([
    dio.get(
      ApiConstants.questions,
      queryParameters: const {'limit': 100, 'is_active': 1},
    ),
    dio.get(ApiConstants.leaderboard),
  ]);
  final questionResp = fallbackResponses[0];
  final leaderboardResp = fallbackResponses[1];
  final questionData =
      questionResp.data['questions'] as List? ??
      questionResp.data['data'] as List? ??
      const <dynamic>[];
  final leaderboardData =
      leaderboardResp.data['leaderboard'] as List? ??
      leaderboardResp.data['data'] as List? ??
      const <dynamic>[];
  final leaderboard = leaderboardData
      .map((entry) => LeaderboardEntry.fromJson(entry as Map<String, dynamic>))
      .toList();

  return DashboardData(
    totalStudents: dashboard.totalStudents,
    totalScores: dashboard.totalScores,
    averageScore: dashboard.averageScore,
    passRatePct: dashboard.passRatePct,
    contentVersion: dashboard.contentVersion,
    ageGroupProgress: dashboard.ageGroupProgress.isNotEmpty
        ? dashboard.ageGroupProgress
        : _buildAgeProgressFallback(leaderboard, dashboard),
    poolHealth: dashboard.poolHealth.isNotEmpty
        ? dashboard.poolHealth
        : _buildPoolHealthFallback(
            questionData
                .map((item) => Question.fromJson(item as Map<String, dynamic>))
                .toList(),
          ),
  );
});

List<AgeGroupProgress> _buildAgeProgressFallback(
  List<LeaderboardEntry> leaderboard,
  DashboardData dashboard,
) {
  if (leaderboard.isEmpty) {
    return const [];
  }

  final byGroup = <String, List<LeaderboardEntry>>{};
  for (final entry in leaderboard) {
    byGroup.putIfAbsent(entry.gradelvl, () => <LeaderboardEntry>[]).add(entry);
  }

  return byGroup.entries.map((entry) {
    final rows = entry.value;
    final totalSessions = rows.fold<int>(0, (sum, row) => sum + row.sessions);
    final totalScore = rows.fold<double>(0, (sum, row) => sum + row.totalScore);
    final avgScore = totalSessions == 0
        ? dashboard.averageScore
        : totalScore / totalSessions;

    return AgeGroupProgress(
      gradelvl: entry.key,
      subject: 'All Subjects',
      activeStudents: rows.length,
      avgScore: avgScore,
      passRatePct: dashboard.passRatePct,
    );
  }).toList();
}

List<PoolHealthEntry> _buildPoolHealthFallback(List<Question> questions) {
  final active = questions.where((question) => question.isActive).toList();

  return [
    for (final gradelvl in gradelvlLabels.entries)
      for (final subject in subjectLabels.entries)
        for (final diff in diffLabels.entries)
          PoolHealthEntry(
            gradelvlId: gradelvl.key,
            subjectId: subject.key,
            diffId: diff.key,
            gradelvl: gradelvl.value,
            subject: subject.value,
            difficulty: diff.value,
            questionCount: active
                .where(
                  (question) =>
                      question.gradelvlId == gradelvl.key &&
                      question.subjectId == subject.key &&
                      question.diffId == diff.key,
                )
                .length,
          ),
  ];
}
