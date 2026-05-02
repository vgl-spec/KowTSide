import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/dashboard.dart';
import '../models/question.dart';

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
  if (dashboard.poolHealth.isNotEmpty) {
    return dashboard;
  }

  final questions = await _loadQuestionFallbackRows();
  if (questions.isEmpty) {
    return dashboard;
  }

  return DashboardData(
    totalStudents: dashboard.totalStudents,
    totalScores: dashboard.totalScores,
    averageScore: dashboard.averageScore,
    passRatePct: dashboard.passRatePct,
    contentVersion: dashboard.contentVersion,
    ageGroupProgress: dashboard.ageGroupProgress,
    poolHealth: _buildPoolHealthFallback(questions),
  );
});

Future<List<Question>> _loadQuestionFallbackRows() async {
  try {
    final response = await dio.get(
      ApiConstants.questions,
      queryParameters: const {'limit': 100, 'is_active': 1},
    );
    final list =
        response.data['questions'] as List? ??
        response.data['data'] as List? ??
        const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => Question.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
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
