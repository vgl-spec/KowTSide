import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/question.dart';
import 'dashboard_provider.dart';

// Filter state
class QuestionFilter {
  final int? subjectId;
  final int? gradelvlId;
  final int? diffId;
  final bool showInactive;
  final String sortOrder;
  final int page;
  final int limit;
  final String searchQuery;

  const QuestionFilter({
    this.subjectId,
    this.gradelvlId,
    this.diffId,
    this.showInactive = false,
    this.sortOrder = 'created_desc',
    this.page = 1,
    this.limit = 100,
    this.searchQuery = '',
  });

  QuestionFilter copyWith({
    int? subjectId,
    int? gradelvlId,
    int? diffId,
    bool? showInactive,
    String? sortOrder,
    int? page,
    int? limit,
    String? searchQuery,
    bool clearSubject = false,
    bool clearGrade = false,
    bool clearDiff = false,
  }) => QuestionFilter(
    subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
    gradelvlId: clearGrade ? null : (gradelvlId ?? this.gradelvlId),
    diffId: clearDiff ? null : (diffId ?? this.diffId),
    showInactive: showInactive ?? this.showInactive,
    sortOrder: sortOrder ?? this.sortOrder,
    page: page ?? this.page,
    limit: limit ?? this.limit,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

final questionFilterProvider = StateProvider<QuestionFilter>(
  (ref) => const QuestionFilter(),
);

final allQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.questions();
  }

  final resp = await dio.get(ApiConstants.questions);
  final list =
      resp.data['questions'] as List? ??
      resp.data as List? ??
      const <dynamic>[];
  return list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
});

final questionsProvider = FutureProvider<QuestionPage>((ref) async {
  final filter = ref.watch(questionFilterProvider);
  if (ApiConstants.frontendOnly) {
    final questions = MockData.filteredQuestions(
      subjectId: filter.subjectId,
      gradelvlId: filter.gradelvlId,
      diffId: filter.diffId,
      showInactive: filter.showInactive,
      search: filter.searchQuery,
      sortOrder: filter.sortOrder,
    );
    final total = questions.length;
    final totalPages = total == 0 ? 1 : ((total + filter.limit - 1) ~/ filter.limit);
    final safePage = filter.page > totalPages ? totalPages : filter.page;
    final start = (safePage - 1) * filter.limit;
    final pageItems = questions.skip(start).take(filter.limit).toList();
    return QuestionPage(
      page: safePage,
      limit: filter.limit,
      total: total,
      totalPages: totalPages,
      questions: pageItems,
    );
  }
  final params = <String, dynamic>{};
  if (filter.subjectId != null) params['subject_id'] = filter.subjectId;
  if (filter.gradelvlId != null) params['gradelvl_id'] = filter.gradelvlId;
  if (filter.diffId != null) params['diff_id'] = filter.diffId;
  if (!filter.showInactive) params['is_active'] = 1;
  params['sort'] = filter.sortOrder;
  params['page'] = filter.page;
  params['limit'] = filter.limit;
  if (filter.searchQuery.trim().isNotEmpty) {
    params['search'] = filter.searchQuery.trim();
  }

  final resp = await dio.get(
    ApiConstants.questions,
    queryParameters: params.isEmpty ? null : params,
  );
  return QuestionPage.fromJson(resp.data as Map<String, dynamic>);
});

// Notifier for CRUD mutations
class QuestionsMutationNotifier extends StateNotifier<AsyncValue<void>> {
  QuestionsMutationNotifier() : super(const AsyncValue.data(null));

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  Future<bool> add(Map<String, dynamic> body, WidgetRef ref) async {
    state = const AsyncValue.loading();
    _lastErrorMessage = null;
    try {
      if (ApiConstants.frontendOnly) {
        MockData.addQuestion(body);
        ref.invalidate(questionsProvider);
        ref.invalidate(allQuestionsProvider);
        ref.invalidate(dashboardProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      await dio.post(ApiConstants.questions, data: body);
      ref.invalidate(questionsProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      _lastErrorMessage = _toReadableError(e);
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> body, WidgetRef ref) async {
    state = const AsyncValue.loading();
    _lastErrorMessage = null;
    try {
      if (ApiConstants.frontendOnly) {
        MockData.updateQuestion(id, body);
        ref.invalidate(questionsProvider);
        ref.invalidate(allQuestionsProvider);
        ref.invalidate(dashboardProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      await dio.put(ApiConstants.question(id), data: body);
      ref.invalidate(questionsProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      _lastErrorMessage = _toReadableError(e);
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> softDelete(int id, WidgetRef ref) async {
    state = const AsyncValue.loading();
    _lastErrorMessage = null;
    try {
      if (ApiConstants.frontendOnly) {
        MockData.softDeleteQuestion(id);
        ref.invalidate(questionsProvider);
        ref.invalidate(allQuestionsProvider);
        ref.invalidate(dashboardProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      await dio.delete(ApiConstants.question(id));
      ref.invalidate(questionsProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      _lastErrorMessage = _toReadableError(e);
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> softDeleteMany(Iterable<int> ids, WidgetRef ref) async {
    final targets = ids.toSet().toList()..sort();
    if (targets.isEmpty) {
      return true;
    }

    state = const AsyncValue.loading();
    _lastErrorMessage = null;
    try {
      if (ApiConstants.frontendOnly) {
        for (final id in targets) {
          MockData.softDeleteQuestion(id);
        }
      } else {
        for (final id in targets) {
          await dio.delete(ApiConstants.question(id));
        }
      }

      ref.invalidate(questionsProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      _lastErrorMessage = _toReadableError(e);
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  String _toReadableError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final details = data['details'];
        if (details is List && details.isNotEmpty) {
          final first = details.first;
          if (first is Map<String, dynamic>) {
            final path = first['path'];
            final message = first['message'];
            if (path != null && message != null) {
              return '$path: $message';
            }
            if (message != null) return '$message';
          }
        }

        final message = data['message'] ?? data['error'] ?? data['code'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }
    return 'The server rejected the request. Please review the form and try again.';
  }
}

// ignore: non_constant_identifier_names
final questionsMutationProvider =
    StateNotifierProvider<QuestionsMutationNotifier, AsyncValue<void>>(
      (ref) => QuestionsMutationNotifier(),
    );
