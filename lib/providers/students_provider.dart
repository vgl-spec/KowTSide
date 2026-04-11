import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/student.dart';

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.students();
  }
  final resp = await dio.get(ApiConstants.students);
  final list = (resp.data['students'] as List? ?? []);
  return list.map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
});

final studentDetailProvider =
    FutureProvider.family<StudentDetail, int>((ref, id) async {
  if (ApiConstants.frontendOnly) {
    return MockData.studentDetail(id);
  }
  final resp = await dio.get(ApiConstants.student(id));
  return StudentDetail.fromJson(resp.data as Map<String, dynamic>);
});
