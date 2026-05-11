import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../core/score_utils.dart';
import '../models/dashboard.dart';
import '../models/question.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.dashboard();
  }

  final resp = await dio.get(ApiConstants.dashboard);
  final payload = _readMap(resp.data);
  final data = _enrichDashboardPayload(
    _readMap(payload['data']).isNotEmpty ? _readMap(payload['data']) : payload,
    payload,
  );
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

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, dynamic>{};
}

Map<String, dynamic> _enrichDashboardPayload(
  Map<String, dynamic> dashboard,
  Map<String, dynamic> payload,
) {
  final summaryRows =
      payload['subject_level_summary'] ?? dashboard['subject_level_summary'];
  final summaryList = _readList(summaryRows);
  if (summaryList.isNotEmpty) {
    final derivedAgeRows = _deriveAgeGroupProgress(summaryList);
    final derivedOverall = _deriveOverall(summaryList);
    return {
      ...dashboard,
      'subject_level_summary': summaryRows,
      'age_group_progress': derivedAgeRows,
      if (derivedOverall != null) ...derivedOverall,
    };
  }

  return dashboard;
}

List<Map<String, dynamic>> _readList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _deriveAgeGroupProgress(
  List<Map<String, dynamic>> rows,
) {
  if (rows.isEmpty) {
    return const [];
  }

  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final row in rows) {
    final gradelvl = (row['gradelvl'] as String? ?? '').trim();
    final subject = (row['subject'] as String? ?? '').trim();
    grouped
        .putIfAbsent('$gradelvl|$subject', () => <Map<String, dynamic>>[])
        .add(row);
  }

  return grouped.entries
      .map((entry) {
        final sample = entry.value.first;
        final totalStudents = entry.value.fold<int>(
          0,
          (sum, row) =>
              sum +
              (_readInt(row['student_groups']) ??
                  _readInt(row['active_students']) ??
                  0),
        );
        final studentWeights = entry.value
            .map<double>(
              (row) =>
                  (_readInt(row['student_groups']) ??
                          _readInt(row['active_students']) ??
                          0)
                      .toDouble(),
            )
            .toList(growable: false);
        final attemptWeights = entry.value
            .map<double>(
              (row) =>
                  (_readInt(row['total_attempts']) ??
                          _readInt(row['attempts']) ??
                          0)
                      .toDouble(),
            )
            .toList(growable: false);
        final avgScores = entry.value
            .map<double>((row) {
              final subject = (row['subject'] as String? ?? '').trim();
              final difficulty = (row['difficulty'] as String? ?? '').trim();
              return normalizeAverageScore(
                _readDouble(row['avg_score']) ?? 0.0,
                difficulty: difficulty,
                subject: subject,
              );
            })
            .toList(growable: false);
        final passRates = entry.value
            .map<double>((row) => _readDouble(row['pass_rate_pct']) ?? 0.0)
            .toList(growable: false);

        return <String, dynamic>{
          'gradelvl': sample['gradelvl'] as String? ?? '',
          'subject': sample['subject'] as String? ?? '',
          'active_students': totalStudents,
          'avg_score': _weightedAverage(avgScores, studentWeights),
          'pass_rate_pct': _weightedAverage(passRates, attemptWeights),
        };
      })
      .toList(growable: false);
}

Map<String, dynamic>? _deriveOverall(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return null;
  final attempts = rows
      .map<int>(
        (row) =>
            _readInt(row['total_attempts']) ?? _readInt(row['attempts']) ?? 0,
      )
      .toList(growable: false);
  final totalAttempts = attempts.fold<int>(0, (sum, value) => sum + value);
  if (totalAttempts <= 0) return null;
  final weights = attempts
      .map((value) => value.toDouble())
      .toList(growable: false);
  final avgScores = rows
      .map<double>((row) {
        final subject = (row['subject'] as String? ?? '').trim();
        final difficulty = (row['difficulty'] as String? ?? '').trim();
        return normalizeAverageScore(
          _readDouble(row['avg_score']) ?? 0.0,
          difficulty: difficulty,
          subject: subject,
        );
      })
      .toList(growable: false);
  final passRates = rows
      .map<double>((row) => _readDouble(row['pass_rate_pct']) ?? 0.0)
      .toList(growable: false);
  return <String, dynamic>{
    'average_score': _weightedAverage(avgScores, weights),
    'pass_rate_pct': _weightedAverage(passRates, weights),
  };
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
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
