import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/question.dart';

// Filter state
class QuestionFilter {
  final int? subjectId;
  final int? gradelvlId;
  final int? diffId;
  final bool showInactive;

  const QuestionFilter({
    this.subjectId,
    this.gradelvlId,
    this.diffId,
    this.showInactive = false,
  });

  QuestionFilter copyWith({
    int? subjectId,
    int? gradelvlId,
    int? diffId,
    bool? showInactive,
    bool clearSubject = false,
    bool clearGrade = false,
    bool clearDiff = false,
  }) => QuestionFilter(
        subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
        gradelvlId: clearGrade ? null : (gradelvlId ?? this.gradelvlId),
        diffId: clearDiff ? null : (diffId ?? this.diffId),
        showInactive: showInactive ?? this.showInactive,
      );
}

final questionFilterProvider =
    StateProvider<QuestionFilter>((ref) => const QuestionFilter());

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final filter = ref.watch(questionFilterProvider);
  if (ApiConstants.frontendOnly) {
    return MockData.filteredQuestions(
      subjectId: filter.subjectId,
      gradelvlId: filter.gradelvlId,
      diffId: filter.diffId,
      showInactive: filter.showInactive,
    );
  }
  final params = <String, dynamic>{};
  if (filter.subjectId != null) params['subject_id'] = filter.subjectId;
  if (filter.gradelvlId != null) params['gradelvl_id'] = filter.gradelvlId;
  if (filter.diffId != null) params['diff_id'] = filter.diffId;
  if (!filter.showInactive) params['is_active'] = 1;

  final resp = await dio.get(
    ApiConstants.questions,
    queryParameters: params.isEmpty ? null : params,
  );
  final list = resp.data['questions'] as List? ?? resp.data as List? ?? [];
  return list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
});

// Notifier for CRUD mutations
class QuestionsMutationNotifier extends StateNotifier<AsyncValue<void>> {
  QuestionsMutationNotifier() : super(const AsyncValue.data(null));

  Future<bool> add(Map<String, dynamic> body, WidgetRef ref) async {
    state = const AsyncValue.loading();
    try {
      if (ApiConstants.frontendOnly) {
        MockData.addQuestion(body);
        ref.invalidate(questionsProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      await dio.post(ApiConstants.questions, data: body);
      ref.invalidate(questionsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> body, WidgetRef ref) async {
    state = const AsyncValue.loading();
    try {
      if (ApiConstants.frontendOnly) {
        MockData.updateQuestion(id, body);
        ref.invalidate(questionsProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      await dio.put(ApiConstants.question(id), data: body);
      ref.invalidate(questionsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> softDelete(int id, WidgetRef ref) async {
    state = const AsyncValue.loading();
    try {
      if (ApiConstants.frontendOnly) {
        MockData.softDeleteQuestion(id);
        ref.invalidate(questionsProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      await dio.delete(ApiConstants.question(id));
      ref.invalidate(questionsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

// ignore: non_constant_identifier_names
final questionsMutationProvider =
    StateNotifierProvider<QuestionsMutationNotifier, AsyncValue<void>>(
  (ref) => QuestionsMutationNotifier(),
);

