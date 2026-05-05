import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../core/score_utils.dart';
import '../models/student.dart';

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.students();
  }
  final timer = Timer.periodic(const Duration(seconds: 20), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final resp = await dio.get(ApiConstants.students);
  final list =
      resp.data['students'] as List? ??
      resp.data['data'] as List? ??
      const <dynamic>[];
  final students = list
      .map((e) => Student.fromJson(e as Map<String, dynamic>))
      .toList();
  return students;
});

final studentDetailProvider = FutureProvider.family<StudentDetail, int>((
  ref,
  id,
) async {
  if (ApiConstants.frontendOnly) {
    return MockData.studentDetail(id);
  }
  try {
    final resp = await dio.get(ApiConstants.student(id));
    final data =
        resp.data['data'] as Map<String, dynamic>? ??
        resp.data as Map<String, dynamic>;
    final detail = StudentDetail.fromJson(data);
    return _enrichStudentDetail(ref, id, detail);
  } on DioException catch (error) {
    if (error.response?.statusCode != 404) {
      rethrow;
    }
    return _fallbackStudentDetail(ref, id);
  }
});

Future<StudentDetail> _fallbackStudentDetail(Ref ref, int id) async {
  final students = await ref.read(studentsProvider.future);
  final matching = students.where((student) => student.studId == id);
  if (matching.isEmpty) {
    throw DioException(
      requestOptions: RequestOptions(path: ApiConstants.student(id)),
      response: Response(
        requestOptions: RequestOptions(path: ApiConstants.student(id)),
        statusCode: 404,
        data: {'message': 'Learner not found'},
      ),
    );
  }

  return _enrichStudentDetail(
    ref,
    id,
    StudentDetail(
      profile: matching.first,
      progress: const [],
      analytics: const [],
      recentScores: const [],
    ),
  );
}

Future<StudentDetail> _enrichStudentDetail(
  Ref ref,
  int id,
  StudentDetail detail,
) async {
  Student? summaryProfile;
  try {
    final students = await ref.read(studentsProvider.future);
    summaryProfile = students
        .where((student) => student.studId == id)
        .cast<Student?>()
        .firstWhere((student) => student != null, orElse: () => null);
  } catch (_) {
    summaryProfile = null;
  }

  final mergedProfile = _mergeProfile(
    detail.profile,
    summaryProfile,
    detail.recentScores,
  );
  final recentScores = detail.recentScores;
  final derivedProgress = _deriveProgressFromScores(
    recentScores,
    mergedProfile.gradelvl,
  );
  final derivedAnalytics = _deriveAnalyticsFromScores(
    recentScores,
    mergedProfile.gradelvl,
  );

  return StudentDetail(
    profile: mergedProfile,
    progress: detail.progress.isNotEmpty ? detail.progress : derivedProgress,
    analytics: detail.analytics.isNotEmpty
        ? detail.analytics
        : derivedAnalytics,
    recentScores: recentScores,
  );
}

Student _mergeProfile(
  Student detailProfile,
  Student? summaryProfile,
  List<ScoreRecord> recentScores,
) {
  final scoreAverage = averageScoreFromValues(
    recentScores.map((score) => score.score),
  );
  final effectiveSessions =
      summaryProfile?.totalSessions ??
      (detailProfile.totalSessions > 0
          ? detailProfile.totalSessions
          : recentScores.length);
  final effectiveAverage =
      summaryProfile?.avgScore ??
      (detailProfile.avgScore > 0 ? detailProfile.avgScore : scoreAverage);

  final merged = (summaryProfile ?? detailProfile).copyWith(
    studId: detailProfile.studId != 0
        ? detailProfile.studId
        : summaryProfile?.studId,
    nickname: detailProfile.nickname.isNotEmpty
        ? detailProfile.nickname
        : summaryProfile?.nickname,
    firstName: detailProfile.firstName.isNotEmpty
        ? detailProfile.firstName
        : summaryProfile?.firstName,
    lastName: detailProfile.lastName.isNotEmpty
        ? detailProfile.lastName
        : summaryProfile?.lastName,
    area: detailProfile.area.isNotEmpty
        ? detailProfile.area
        : summaryProfile?.area,
    birthday: detailProfile.birthday.isNotEmpty
        ? detailProfile.birthday
        : summaryProfile?.birthday,
    age: detailProfile.age != 0 ? detailProfile.age : summaryProfile?.age,
    gradelvl: detailProfile.gradelvl.isNotEmpty
        ? detailProfile.gradelvl
        : summaryProfile?.gradelvl,
    sex: detailProfile.sex.isNotEmpty ? detailProfile.sex : summaryProfile?.sex,
    totalSessions: effectiveSessions,
    avgScore: effectiveAverage,
  );

  return merged.copyWith(
    proficiency: resolveProficiencyLabel(merged.proficiency, merged.avgScore),
  );
}

List<SubjectProgress> _deriveProgressFromScores(
  List<ScoreRecord> scores,
  String fallbackGradeLevel,
) {
  if (scores.isEmpty) {
    return const <SubjectProgress>[];
  }

  final grouped = <String, List<ScoreRecord>>{};
  for (final score in scores) {
    final key =
        '${score.subject}|${score.gradelvl.isNotEmpty ? score.gradelvl : fallbackGradeLevel}';
    grouped.putIfAbsent(key, () => <ScoreRecord>[]).add(score);
  }

  return grouped.entries
      .map((entry) {
        final rows = entry.value;
        final latest = rows.first;
        final highestDiffPassed = rows
            .where((score) => score.passed)
            .map((score) => _difficultyRank(score.difficulty))
            .fold<int>(0, (max, value) => value > max ? value : max);

        return SubjectProgress(
          subject: latest.subject,
          gradelvl: latest.gradelvl.isNotEmpty
              ? latest.gradelvl
              : fallbackGradeLevel,
          highestDiffPassed: highestDiffPassed,
          totalTimePlayed: 0,
          lastPlayedAt: latest.playedAt,
        );
      })
      .toList(growable: false);
}

List<SubjectAnalytics> _deriveAnalyticsFromScores(
  List<ScoreRecord> scores,
  String fallbackGradeLevel,
) {
  if (scores.isEmpty) {
    return const <SubjectAnalytics>[];
  }

  final grouped = <String, List<ScoreRecord>>{};
  for (final score in scores) {
    final key =
        '${score.subject}|${score.gradelvl.isNotEmpty ? score.gradelvl : fallbackGradeLevel}';
    grouped.putIfAbsent(key, () => <ScoreRecord>[]).add(score);
  }

  return grouped.entries
      .map((entry) {
        final rows = entry.value;
        final values = rows.map((score) => score.score).toList(growable: false);
        final first = rows.first;
        return SubjectAnalytics(
          subject: first.subject,
          gradelvl: first.gradelvl.isNotEmpty
              ? first.gradelvl
              : fallbackGradeLevel,
          lowestScore: values.reduce((a, b) => a < b ? a : b),
          averageScore: averageScoreFromValues(values),
          highestScore: values.reduce((a, b) => a > b ? a : b),
          totalAttempts: rows.length,
        );
      })
      .toList(growable: false);
}

int _difficultyRank(String difficulty) {
  switch (difficulty.trim().toLowerCase()) {
    case 'easy':
      return 1;
    case 'average':
      return 2;
    case 'hard':
      return 3;
    default:
      return 0;
  }
}
