import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/reporting.dart';
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
  if (students.isNotEmpty) {
    return students;
  }

  final leaderboardResp = await dio.get(ApiConstants.leaderboard);
  final leaderboard =
      leaderboardResp.data['leaderboard'] as List? ??
      leaderboardResp.data['data'] as List? ??
      const <dynamic>[];
  return leaderboard
      .map(
        (entry) => _studentFromLeaderboard(
          LeaderboardEntry.fromJson(entry as Map<String, dynamic>),
        ),
      )
      .toList();
});

final studentDetailProvider = FutureProvider.family<StudentDetail, int>((
  ref,
  id,
) async {
  if (ApiConstants.frontendOnly) {
    return MockData.studentDetail(id);
  }
  final resp = await dio.get(ApiConstants.student(id));
  final data =
      resp.data['data'] as Map<String, dynamic>? ??
      resp.data as Map<String, dynamic>;
  return StudentDetail.fromJson(data);
});

Student _studentFromLeaderboard(LeaderboardEntry entry) {
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
}

String _proficiencyFor(double avgScore) {
  if (avgScore >= 9.0) return 'Excelling';
  if (avgScore >= 7.0) return 'On track';
  if (avgScore >= 5.0) return 'Needs support';
  return 'Needs significant support';
}
