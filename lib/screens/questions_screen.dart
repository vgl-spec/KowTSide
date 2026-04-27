import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/question.dart';
import '../providers/questions_provider.dart';
import '../widgets/page_skeletons.dart';
import '../widgets/question_form_dialog.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({super.key});

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(questionFilterProvider);
    final async = ref.watch(questionsProvider);

    if (async.isLoading) {
      return const SafeArea(child: QuestionsLoadingSkeleton());
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Question Bank',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Question'),
                  onPressed: () => _showQuestionDialog(context, null),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(questionsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search questions and options',
                          hintText: 'Find words in the prompt or A/B/C/D...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    _FilterDropdown<int>(
                      label: 'Subject',
                      value: filter.subjectId,
                      items: subjectLabels,
                      onChanged: (v) =>
                          ref.read(questionFilterProvider.notifier).state =
                              v == null
                              ? filter.copyWith(clearSubject: true, page: 1)
                              : filter.copyWith(subjectId: v, page: 1),
                    ),
                    _FilterDropdown<int>(
                      label: 'Grade Level',
                      value: filter.gradelvlId,
                      items: gradelvlLabels,
                      onChanged: (v) =>
                          ref.read(questionFilterProvider.notifier).state =
                              v == null
                              ? filter.copyWith(clearGrade: true, page: 1)
                              : filter.copyWith(gradelvlId: v, page: 1),
                    ),
                    _FilterDropdown<int>(
                      label: 'Difficulty',
                      value: filter.diffId,
                      items: diffLabels,
                      onChanged: (v) =>
                          ref.read(questionFilterProvider.notifier).state =
                              v == null
                              ? filter.copyWith(clearDiff: true, page: 1)
                              : filter.copyWith(diffId: v, page: 1),
                    ),
                    FilterChip(
                      label: const Text('Show inactive'),
                      selected: filter.showInactive,
                      onSelected: (v) =>
                          ref.read(questionFilterProvider.notifier).state =
                              filter.copyWith(showInactive: v, page: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Card(
                child: async.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text('$error'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref.invalidate(questionsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (pageData) {
                    final questions = pageData.questions;
                    if (questions.isEmpty) {
                      return const Center(child: Text('No questions found.'));
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: ListView.separated(
                              itemCount: questions.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final question = questions[index];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () =>
                                      _showQuestionDialog(context, question),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: Text(
                                            question.questionTxt,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '${subjectLabels[question.subjectId]}\n${gradelvlLabels[question.gradelvlId]} - ${diffLabels[question.diffId]}',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${question.correctOpt}: ${_optionText(question, question.correctOpt)}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        _StatusChip(active: question.isActive),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: _QuestionPaginationBar(
                            page: pageData.page,
                            totalPages: pageData.totalPages,
                            totalRows: pageData.total,
                            rowsPerPage: pageData.limit,
                            onPageSelected: (page) {
                              ref.read(questionFilterProvider.notifier).state =
                                  filter.copyWith(page: page);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final filter = ref.read(questionFilterProvider);
      ref.read(questionFilterProvider.notifier).state = filter.copyWith(
        searchQuery: value.trim(),
        page: 1,
      );
    });
  }

  String _optionText(Question q, String opt) {
    switch (opt) {
      case 'A':
        return q.optionA;
      case 'B':
        return q.optionB;
      case 'C':
        return q.optionC;
      case 'D':
        return q.optionD;
      default:
        return '';
    }
  }

  void _showQuestionDialog(BuildContext context, Question? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestionFormDialog(existing: existing),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButton<T?>(
    hint: Text(label),
    value: value,
    underline: const SizedBox(),
    isDense: true,
    items: [
      DropdownMenuItem<T?>(value: null, child: Text('All $label')),
      ...items.entries.map(
        (e) => DropdownMenuItem<T?>(value: e.key, child: Text(e.value)),
      ),
    ],
    onChanged: onChanged,
  );
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) => active
      ? Chip(
          label: const Text('Active'),
          backgroundColor: AppTheme.success.withValues(alpha: 0.16),
          labelStyle: const TextStyle(color: AppTheme.success, fontSize: 12),
          padding: EdgeInsets.zero,
        )
      : Chip(
          label: const Text('Inactive'),
          backgroundColor: AppTheme.surfaceHigh,
          labelStyle: TextStyle(
            color: AppTheme.textMediumEmphasis,
            fontSize: 12,
          ),
          padding: EdgeInsets.zero,
        );
}

class _QuestionPaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onPageSelected;

  const _QuestionPaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages(page, totalPages);
    final startRow = totalRows == 0 ? 0 : ((page - 1) * rowsPerPage) + 1;
    final endRow = totalRows == 0
        ? 0
        : (page * rowsPerPage > totalRows ? totalRows : page * rowsPerPage);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$startRow-$endRow of $totalRows'),
        OutlinedButton(
          onPressed: page > 1 ? () => onPageSelected(page - 1) : null,
          child: const Text('Previous'),
        ),
        ...pages.map(
          (item) => item == null
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...'),
                )
              : FilledButton.tonal(
                  onPressed: item == page ? null : () => onPageSelected(item),
                  child: Text('$item'),
                ),
        ),
        OutlinedButton(
          onPressed: page < totalPages ? () => onPageSelected(page + 1) : null,
          child: const Text('Next'),
        ),
      ],
    );
  }

  List<int?> _visiblePages(int currentPage, int pageCount) {
    if (pageCount <= 7) {
      return List<int?>.generate(pageCount, (index) => index + 1);
    }

    final pages = <int?>[1];
    final start = currentPage <= 3 ? 2 : currentPage - 1;
    final end = currentPage >= pageCount - 2 ? pageCount - 1 : currentPage + 1;

    if (start > 2) {
      pages.add(null);
    }

    for (var value = start; value <= end; value++) {
      if (value > 1 && value < pageCount) {
        pages.add(value);
      }
    }

    if (end < pageCount - 1) {
      pages.add(null);
    }

    pages.add(pageCount);
    return pages;
  }
}
