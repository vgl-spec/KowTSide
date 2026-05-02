import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
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
    return StudentDetail.fromJson(data);
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

  return StudentDetail(
    profile: matching.first,
    progress: const [],
    analytics: const [],
    recentScores: const [],
  );
}
