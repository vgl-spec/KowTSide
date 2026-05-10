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

  // Keep Question Bank behavior deterministic:
  // collect all filtered rows from the backend, then paginate/sort/search locally.
  final allRows = await _fetchAllRowsForFilter(filter);
  return _localPage(allRows, filter);
});

QuestionPage _localPage(List<Question> source, QuestionFilter filter) {
  final filtered = _applyLocalFilters(source, filter);
  final total = filtered.length;
  final totalPages = total == 0 ? 1 : ((total + filter.limit - 1) ~/ filter.limit);
  final safePage = filter.page > totalPages ? totalPages : filter.page;
  final start = (safePage - 1) * filter.limit;
  final pageItems = filtered.skip(start).take(filter.limit).toList();
  return QuestionPage(
    page: safePage,
    limit: filter.limit,
    total: total,
    totalPages: totalPages,
    questions: pageItems,
  );
}

List<Question> _applyLocalFilters(List<Question> source, QuestionFilter filter) {
  final needle = filter.searchQuery.trim().toLowerCase();
  final filtered = source.where((question) {
    if (filter.subjectId != null && question.subjectId != filter.subjectId) {
      return false;
    }
    if (filter.gradelvlId != null &&
        question.gradelvlId != filter.gradelvlId) {
      return false;
    }
    if (filter.diffId != null && question.diffId != filter.diffId) {
      return false;
    }
    if (!filter.showInactive && !question.isActive) {
      return false;
    }
    if (needle.isEmpty) {
      return true;
    }
    final haystack = [
      question.questionTxt,
      question.subPrompt,
      question.funFact,
      question.wordType,
      question.optionA,
      question.optionB,
      question.optionC,
      question.optionD,
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }).toList();

  int compareByCreatedAsc(Question a, Question b) =>
      _compareQuestionDateAsc(a, b, preferUpdatedFallback: true);
  int compareByCreatedDesc(Question a, Question b) =>
      _compareQuestionDateDesc(a, b, preferUpdatedFallback: true);
  int compareByUpdatedDesc(Question a, Question b) =>
      _compareQuestionDateDesc(a, b, preferUpdatedFallback: false);
  int compareByPool(Question a, Question b) {
    final gradeCompare = a.gradelvlId.compareTo(b.gradelvlId);
    if (gradeCompare != 0) return gradeCompare;
    final subjectCompare = a.subjectId.compareTo(b.subjectId);
    if (subjectCompare != 0) return subjectCompare;
    final diffCompare = a.diffId.compareTo(b.diffId);
    if (diffCompare != 0) return diffCompare;
    return a.questionId.compareTo(b.questionId);
  }

  switch (filter.sortOrder) {
    case 'created_asc':
      filtered.sort(compareByCreatedAsc);
      break;
    case 'updated_desc':
      filtered.sort(compareByUpdatedDesc);
      break;
    case 'pool':
      filtered.sort(compareByPool);
      break;
    case 'created_desc':
    default:
      filtered.sort(compareByCreatedDesc);
      break;
  }
  return filtered;
}

DateTime _parseDate(String value) =>
    DateTime.tryParse(value.trim()) ??
    _parseOracleDate(value.trim()) ??
    DateTime.fromMillisecondsSinceEpoch(0);

DateTime _parseDateTime(String date, String time) {
  final d = date.trim();
  if (d.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

  final direct = DateTime.tryParse(d);
  if (direct != null) return direct;

  final oracleDate = _parseOracleDate(d);
  if (oracleDate != null) {
    final t = time.trim();
    if (t.isEmpty) return oracleDate;
    final tm = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(t);
    if (tm == null) return oracleDate;
    final hour = int.tryParse(tm.group(1) ?? '') ?? 0;
    final minute = int.tryParse(tm.group(2) ?? '') ?? 0;
    final second = int.tryParse(tm.group(3) ?? '') ?? 0;
    return DateTime(
      oracleDate.year,
      oracleDate.month,
      oracleDate.day,
      hour,
      minute,
      second,
    );
  }

  return _parseDate(d);
}

DateTime _resolveQuestionDate(
  Question q, {
  required bool preferUpdatedFallback,
}) {
  final primary = _parseDateTime(q.createdDate, q.createdTime);
  if (preferUpdatedFallback &&
      primary == DateTime.fromMillisecondsSinceEpoch(0)) {
    return _parseDateTime(q.updatedDate, q.updatedTime);
  }
  if (!preferUpdatedFallback) {
    return _parseDateTime(q.updatedDate, q.updatedTime);
  }
  return primary;
}

int _compareQuestionDateAsc(
  Question a,
  Question b, {
  required bool preferUpdatedFallback,
}) {
  final left = _resolveQuestionDate(a, preferUpdatedFallback: preferUpdatedFallback);
  final right = _resolveQuestionDate(
    b,
    preferUpdatedFallback: preferUpdatedFallback,
  );
  final dateCompare = left.compareTo(right);
  if (dateCompare != 0) return dateCompare;
  return a.questionId.compareTo(b.questionId);
}

int _compareQuestionDateDesc(
  Question a,
  Question b, {
  required bool preferUpdatedFallback,
}) {
  final left = _resolveQuestionDate(a, preferUpdatedFallback: preferUpdatedFallback);
  final right = _resolveQuestionDate(
    b,
    preferUpdatedFallback: preferUpdatedFallback,
  );
  final dateCompare = right.compareTo(left);
  if (dateCompare != 0) return dateCompare;
  return b.questionId.compareTo(a.questionId);
}

DateTime? _parseOracleDate(String value) {
  final match = RegExp(r'^(\d{1,2})-([A-Za-z]{3})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final day = int.tryParse(match.group(1) ?? '');
  final monthToken = (match.group(2) ?? '').toUpperCase();
  final yearTwo = int.tryParse(match.group(3) ?? '');
  if (day == null || yearTwo == null) return null;
  const monthMap = {
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };
  final month = monthMap[monthToken];
  if (month == null) return null;
  final year = yearTwo >= 70 ? 1900 + yearTwo : 2000 + yearTwo;
  return DateTime(year, month, day);
}

Future<List<Question>> _fetchAllRowsForFilter(QuestionFilter filter) async {
  const perPage = 500;
  final collected = <Question>[];
  final seenQuestionIds = <int>{};
  var page = 1;
  var totalPages = 1;

  do {
    final params = <String, dynamic>{
      'page': page,
      'limit': perPage,
    };
    if (filter.subjectId != null) params['subject_id'] = filter.subjectId;
    if (filter.gradelvlId != null) params['gradelvl_id'] = filter.gradelvlId;
    if (filter.diffId != null) params['diff_id'] = filter.diffId;
    if (!filter.showInactive) params['is_active'] = 1;

    final resp = await dio.get(
      ApiConstants.questions,
      queryParameters: params,
    );
    final pageData = QuestionPage.fromJson(resp.data as Map<String, dynamic>);
    for (final question in pageData.questions) {
      if (seenQuestionIds.add(question.questionId)) {
        collected.add(question);
      }
    }
    totalPages = pageData.totalPages < 1 ? 1 : pageData.totalPages;
    page += 1;
  } while (page <= totalPages);

  return collected;
}

Future<List<Question>> fetchQuestionsForExport(QuestionFilter filter) async {
  if (ApiConstants.frontendOnly) {
    return MockData.filteredQuestions(
      subjectId: filter.subjectId,
      gradelvlId: filter.gradelvlId,
      diffId: filter.diffId,
      showInactive: filter.showInactive,
      search: filter.searchQuery,
      sortOrder: filter.sortOrder,
    );
  }

  final params = <String, dynamic>{};
  if (filter.subjectId != null) params['subject_id'] = filter.subjectId;
  if (filter.gradelvlId != null) params['gradelvl_id'] = filter.gradelvlId;
  if (filter.diffId != null) params['diff_id'] = filter.diffId;
  if (!filter.showInactive) params['is_active'] = 1;
  params['sort'] = filter.sortOrder;
  params['page'] = 1;
  params['limit'] = 5000;
  if (filter.searchQuery.trim().isNotEmpty) {
    params['search'] = filter.searchQuery.trim();
  }

  final resp = await dio.get(
    ApiConstants.questions,
    queryParameters: params.isEmpty ? null : params,
  );
  final page = QuestionPage.fromJson(resp.data as Map<String, dynamic>);
  return page.questions;
}

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
