import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/import_file_service.dart';
import '../core/question_image_service.dart';
import '../core/theme.dart';
import '../models/question.dart';
import '../providers/dashboard_provider.dart';
import '../providers/questions_provider.dart';
import '../widgets/flareline_components.dart';
import '../widgets/page_skeletons.dart';
import '../widgets/question_form_dialog.dart';

const _questionSortLabels = {
  'created_desc': 'Newest added',
  'created_asc': 'Oldest added',
  'updated_desc': 'Recently updated',
  'pool': 'Pool order',
};

String _answerTextForQuestion(Question question, String option) {
  switch (option) {
    case 'A':
      return question.optionA;
    case 'B':
      return question.optionB;
    case 'C':
      return question.optionC;
    case 'D':
      return question.optionD;
    default:
      return '';
  }
}

class TeacherQuestionsScreen extends ConsumerStatefulWidget {
  const TeacherQuestionsScreen({super.key});

  @override
  ConsumerState<TeacherQuestionsScreen> createState() =>
      _TeacherQuestionsScreenState();
}

class _TeacherQuestionsScreenState
    extends ConsumerState<TeacherQuestionsScreen> {
  final Set<int> _selectedQuestionIds = <int>{};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _selectionMode = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(questionFilterProvider);
    final questionsAsync = ref.watch(questionsProvider);
    final mutationState = ref.watch(questionsMutationProvider);

    return SafeArea(
      child: questionsAsync.when(
        loading: () => const QuestionsLoadingSkeleton(),
        error: (error, _) => _ErrorState(
          message: 'Failed to load the question bank: $error',
          onRetry: () => ref.invalidate(questionsProvider),
        ),
        data: (pageData) {
          final questions = pageData.questions;
          final activeCount = questions
              .where((question) => question.isActive)
              .length;
          final selectedIds = _selectedVisibleIds(questions);
          final selectedCount = selectedIds.length;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlarePageHeader(
                  title: 'Question Bank',
                  subtitle:
                      'Manage classroom content pools while preserving versioning and soft-delete behavior for audit safety.',
                  actions: _buildHeaderActions(
                    context,
                    selectedIds,
                    mutationState.isLoading,
                  ),
                ),
                const SizedBox(height: 14),
                FlareSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FlareSectionTitle(
                        title: 'Filter and Pool Controls',
                        subtitle:
                            'Search, filter, and page through question pools without loading the full bank at once.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 340,
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search questions or options',
                                hintText: 'Find words in the question or A/B/C/D choices...',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          _FilterDropdown<int>(
                            label: 'Subject',
                            value: filter.subjectId,
                            items: subjectSelectionLabels,
                            onChanged: (value) {
                              ref
                                  .read(questionFilterProvider.notifier)
                                  .state = value == null
                                  ? filter.copyWith(clearSubject: true, page: 1)
                                  : filter.copyWith(subjectId: value, page: 1);
                            },
                          ),
                          _FilterDropdown<int>(
                            label: 'Grade Level',
                            value: filter.gradelvlId,
                            items: gradelvlLabels,
                            onChanged: (value) {
                              ref
                                  .read(questionFilterProvider.notifier)
                                  .state = value == null
                                  ? filter.copyWith(clearGrade: true, page: 1)
                                  : filter.copyWith(gradelvlId: value, page: 1);
                            },
                          ),
                          _FilterDropdown<int>(
                            label: 'Difficulty',
                            value: filter.diffId,
                            items: diffLabels,
                            onChanged: (value) {
                              ref
                                  .read(questionFilterProvider.notifier)
                                  .state = value == null
                                  ? filter.copyWith(clearDiff: true, page: 1)
                                  : filter.copyWith(diffId: value, page: 1);
                            },
                          ),
                          _FilterDropdown<String>(
                            label: 'Sort',
                            value: filter.sortOrder,
                            items: _questionSortLabels,
                            onChanged: (value) {
                              if (value == null) return;
                              ref.read(questionFilterProvider.notifier).state =
                                  filter.copyWith(sortOrder: value, page: 1);
                            },
                          ),
                          FilterChip(
                            label: const Text('Show inactive'),
                            selected: filter.showInactive,
                            onSelected: (selected) {
                              ref.read(questionFilterProvider.notifier).state =
                                  filter.copyWith(showInactive: selected, page: 1);
                            },
                          ),
                        ],
                      ),
                      if (_selectionMode) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Selection mode is on. Tap active rows to mark questions to hide from students.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textHighEmphasis,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FlarePill(
                                label: '$selectedCount selected',
                                color: selectedCount > 0
                                    ? AppTheme.error
                                    : AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: FlareSurfaceCard(
                          padding: EdgeInsets.zero,
                          child: questions.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No questions match the current filter.',
                                  ),
                                )
                              : _QuestionBankList(
                                  questions: questions,
                                  selectionMode: _selectionMode,
                                  selectedQuestionIds: selectedIds,
                                  onTapQuestion: (question) =>
                                      _handleQuestionTap(context, question),
                                  onLongPressQuestion:
                                      _handleQuestionLongPress,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _QuestionPagination(
                        page: pageData.page,
                        totalPages: pageData.totalPages,
                        totalRows: pageData.total,
                        rowsPerPage: pageData.limit,
                        onPageSelected: (page) => _setFilter(page: page),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildHeaderActions(
    BuildContext context,
    Set<int> selectedIds,
    bool isMutating,
  ) {
    if (_selectionMode) {
      return [
        FilledButton.icon(
          onPressed: isMutating || selectedIds.isEmpty
              ? null
              : () => _confirmDeleteSelected(context, selectedIds),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
          label: Text('Delete All Selected (${selectedIds.length})'),
        ),
        OutlinedButton.icon(
          onPressed: isMutating ? null : _toggleSelectionMode,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('Done Selecting'),
        ),
        FilledButton.tonalIcon(
          onPressed: isMutating ? null : _refreshQuestions,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
      ];
    }

    return [
      FilledButton.icon(
        onPressed: () => _showImportDialog(context),
        icon: const Icon(Icons.upload_file_rounded, size: 18),
        label: const Text('Import Questions'),
      ),
      FilledButton.icon(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Question'),
      ),
      FilledButton.tonalIcon(
        onPressed: _refreshQuestions,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Refresh'),
      ),
      OutlinedButton.icon(
        onPressed: _toggleSelectionMode,
        icon: const Icon(Icons.checklist_rounded, size: 18),
        label: const Text('Select Multiple'),
      ),
    ];
  }

  void _refreshQuestions() {
    ref.invalidate(questionsProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(dashboardProvider);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _setFilter(searchQuery: value.trim(), page: 1);
    });
  }

  void _setFilter({
    int? page,
    String? searchQuery,
  }) {
    final current = ref.read(questionFilterProvider);
    ref.read(questionFilterProvider.notifier).state = current.copyWith(
      page: page,
      searchQuery: searchQuery,
    );
  }

  Set<int> _selectedVisibleIds(List<Question> questions) {
    final visibleIds = questions.map((question) => question.questionId).toSet();
    final visibleSelection = _selectedQuestionIds
        .where(visibleIds.contains)
        .toSet();

    if (visibleSelection.length != _selectedQuestionIds.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedQuestionIds
            ..clear()
            ..addAll(visibleSelection);
        });
      });
    }

    return visibleSelection;
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedQuestionIds.clear();
      }
    });
  }

  void _handleQuestionTap(BuildContext context, Question question) {
    if (_selectionMode) {
      _toggleQuestionSelection(question);
      return;
    }

    _showQuestionDetails(context, question);
  }

  void _handleQuestionLongPress(Question question) {
    if (_selectionMode || !question.isActive) {
      return;
    }

    setState(() {
      _selectionMode = true;
      _selectedQuestionIds.add(question.questionId);
    });
  }

  void _toggleQuestionSelection(Question question) {
    if (!question.isActive) {
      return;
    }

    setState(() {
      if (_selectedQuestionIds.contains(question.questionId)) {
        _selectedQuestionIds.remove(question.questionId);
      } else {
        _selectedQuestionIds.add(question.questionId);
      }
    });
  }

  void _showForm(BuildContext context, {Question? existing}) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestionFormDialog(existing: existing),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _QuestionImportDialog(),
    );
  }

  void _showQuestionDetails(BuildContext context, Question question) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _QuestionDetailsDialog(
        question: question,
        onEdit: () {
          Navigator.of(dialogContext).pop();
          _showForm(context, existing: question);
        },
        onDelete: question.isActive
            ? () {
                Navigator.of(dialogContext).pop();
                _confirmDelete(context, question);
              }
            : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Question question) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hide question from students?'),
        content: const Text(
          'This question will be hidden from students but kept in the admin bank for audit and recovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(questionsMutationProvider.notifier)
                  .softDelete(question.questionId, ref);
              if (!mounted || !success) {
                return;
              }
              setState(() {
                _selectedQuestionIds.remove(question.questionId);
              });
              messenger.showSnackBar(
                const SnackBar(content: Text('Question hidden from students.')),
              );
            },
            child: const Text('Hide question'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context, Set<int> selectedIds) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hide ${selectedIds.length} questions from students?'),
        content: const Text(
          'Selected questions will be hidden from students and kept in the admin bank for audit and recovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(questionsMutationProvider.notifier)
                  .softDeleteMany(selectedIds, ref);
              if (!mounted || !success) {
                return;
              }
              setState(() {
                _selectedQuestionIds.clear();
                _selectionMode = false;
              });
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Hidden ${selectedIds.length} selected question${selectedIds.length == 1 ? '' : 's'}.',
                  ),
                ),
              );
            },
            child: Text('Delete All Selected (${selectedIds.length})'),
          ),
        ],
      ),
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<T>(value: null, child: Text('All $label')),
          ...items.entries.map(
            (entry) =>
                DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FlarePill(label: '$label: $value', color: color);
  }
}

class _QuestionBankList extends StatelessWidget {
  final List<Question> questions;
  final bool selectionMode;
  final Set<int> selectedQuestionIds;
  final ValueChanged<Question> onTapQuestion;
  final ValueChanged<Question> onLongPressQuestion;

  const _QuestionBankList({
    required this.questions,
    required this.selectionMode,
    required this.selectedQuestionIds,
    required this.onTapQuestion,
    required this.onLongPressQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1080;

        return Column(
          children: [
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _QuestionBankHeaderRow(selectionMode: selectionMode),
              ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, compact ? 16 : 0, 16, 16),
                itemCount: questions.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: compact ? 10 : 8),
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _QuestionBankRow(
                    question: question,
                    compact: compact,
                    selectionMode: selectionMode,
                    selected: selectedQuestionIds.contains(question.questionId),
                    onTap: () => onTapQuestion(question),
                    onLongPress: () => onLongPressQuestion(question),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuestionBankHeaderRow extends StatelessWidget {
  final bool selectionMode;

  const _QuestionBankHeaderRow({required this.selectionMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (selectionMode)
            const SizedBox(
              width: 42,
              child: Text(
                'Pick',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(
            width: 52,
            child: Text('ID', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const Expanded(
            flex: 22,
            child: Text('Added', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const Expanded(
            flex: 28,
            child: Text('Pool', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const Expanded(
            flex: 42,
            child: Text(
              'Preview',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Expanded(
            flex: 22,
            child: Text(
              'Correct Answer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBankRow extends StatelessWidget {
  final Question question;
  final bool compact;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _QuestionBankRow({
    required this.question,
    required this.compact,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final canSelect = question.isActive;
    final borderColor = selected
        ? AppTheme.primary.withValues(alpha: 0.34)
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.38);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.10)
            : AppTheme.surfaceLow.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: selectionMode && !canSelect ? null : onTap,
          onLongPress: selectionMode || !canSelect ? null : onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: compact
                ? _QuestionBankRowCompact(
                    question: question,
                    selectionMode: selectionMode,
                    selected: selected,
                  )
                : _QuestionBankRowWide(
                    question: question,
                    selectionMode: selectionMode,
                    selected: selected,
                  ),
          ),
        ),
      ),
    );
  }
}

class _QuestionBankRowWide extends StatelessWidget {
  final Question question;
  final bool selectionMode;
  final bool selected;

  const _QuestionBankRowWide({
    required this.question,
    required this.selectionMode,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectionMode)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10),
            child: _SelectionMarker(
              selected: selected,
              enabled: question.isActive,
            ),
          ),
        SizedBox(
          width: 52,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${question.questionId}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Expanded(flex: 22, child: _QuestionAddedMeta(question: question)),
        const SizedBox(width: 12),
        Expanded(flex: 28, child: _QuestionPoolMeta(question: question)),
        const SizedBox(width: 12),
        Expanded(
          flex: 42,
          child: _QuestionPreview(
            question: question,
            promptMaxLines: 3,
            subPromptMaxLines: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 22,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _QuestionAnswerMeta(question: question),
          ),
        ),
      ],
    );
  }
}

class _QuestionBankRowCompact extends StatelessWidget {
  final Question question;
  final bool selectionMode;
  final bool selected;

  const _QuestionBankRowCompact({
    required this.question,
    required this.selectionMode,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (selectionMode) ...[
              _SelectionMarker(selected: selected, enabled: question.isActive),
              const SizedBox(width: 10),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '#${question.questionId}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Spacer(),
            _StatusChip(active: question.isActive),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CompactMetaGroup(
                label: 'Added',
                child: _QuestionAddedMeta(question: question),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactMetaGroup(
                label: 'Pool',
                child: _QuestionPoolMeta(question: question),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CompactMetaGroup(
          label: 'Preview',
          child: _QuestionPreview(
            question: question,
            promptMaxLines: 4,
            subPromptMaxLines: 2,
          ),
        ),
        const SizedBox(height: 14),
        _CompactMetaGroup(
          label: 'Correct Answer',
          child: _QuestionAnswerMeta(question: question),
        ),
      ],
    );
  }
}

class _CompactMetaGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _CompactMetaGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textLowEmphasis,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _QuestionAddedMeta extends StatelessWidget {
  final Question question;

  const _QuestionAddedMeta({required this.question});

  @override
  Widget build(BuildContext context) {
    final dateText = question.createdDate.isEmpty
        ? 'No date'
        : question.createdDate;
    final timeText = question.createdTime;
    final username = question.createdByUsername.trim().isEmpty
        ? 'Unknown user'
        : question.createdByUsername;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dateText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (timeText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            timeText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
        const SizedBox(height: 3),
        Text(
          username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textMediumEmphasis),
        ),
      ],
    );
  }
}

class _QuestionPoolMeta extends StatelessWidget {
  final Question question;

  const _QuestionPoolMeta({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gradelvlLabels[question.gradelvlId] ?? 'Unknown group',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${subjectLabels[question.subjectId] ?? 'Unknown subject'} - ${diffLabels[question.diffId] ?? 'Unknown difficulty'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _StatusChip(active: question.isActive),
      ],
    );
  }
}

class _QuestionPreview extends StatelessWidget {
  final Question question;
  final int promptMaxLines;
  final int subPromptMaxLines;
  final double imageSize;

  const _QuestionPreview({
    required this.question,
    this.promptMaxLines = 2,
    this.subPromptMaxLines = 2,
    this.imageSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.hasImage) ...[
          _QuestionThumbnail(imageUrl: question.imageUrl, size: imageSize),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.teacherPrompt,
                maxLines: promptMaxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (question.subPrompt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  question.subPrompt,
                  maxLines: subPromptMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _QuestionThumbnail({required this.imageUrl, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.surfaceLow,
      ),
      child: imageUrl.isEmpty
          ? const Icon(Icons.image_not_supported_outlined)
          : _QuestionImage(imageUrl: imageUrl),
    );
  }
}

class _QuestionImage extends StatelessWidget {
  final String imageUrl;

  const _QuestionImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      final bytes = _decodeDataUrl(imageUrl);
      if (bytes != null) {
        return Image.memory(bytes, fit: BoxFit.cover);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_outlined),
    );
  }

  Uint8List? _decodeDataUrl(String value) {
    final index = value.indexOf(',');
    if (index < 0 || index == value.length - 1) {
      return null;
    }

    try {
      return base64Decode(value.substring(index + 1));
    } catch (_) {
      return null;
    }
  }
}

class _QuestionAnswerMeta extends StatelessWidget {
  final Question question;

  const _QuestionAnswerMeta({required this.question});

  @override
  Widget build(BuildContext context) {
    final answerText = _answerTextForQuestion(question, question.correctOpt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            question.correctOpt,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            answerText.isEmpty ? 'No answer saved' : answerText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SelectionMarker extends StatelessWidget {
  final bool selected;
  final bool enabled;

  const _SelectionMarker({required this.selected, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppTheme.primary : AppTheme.textLowEmphasis;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? color
              : color.withValues(alpha: enabled ? 0.48 : 0.26),
        ),
      ),
      child: Icon(
        selected
            ? Icons.check_rounded
            : enabled
            ? Icons.add_rounded
            : Icons.block_rounded,
        size: 16,
        color: color,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.accent : AppTheme.textMediumEmphasis;
    return FlarePill(label: active ? 'Active' : 'Inactive', color: color);
  }
}

class _QuestionDetailsDialog extends StatelessWidget {
  final Question question;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _QuestionDetailsDialog({
    required this.question,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = screen.width < 900 ? screen.width - 32 : 760.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question #${question.questionId}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${gradelvlLabels[question.gradelvlId] ?? 'Unknown group'} • '
                          '${subjectLabels[question.subjectId] ?? 'Unknown subject'} • '
                          '${diffLabels[question.diffId] ?? 'Unknown difficulty'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(active: question.isActive),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FlareSurfaceCard(
                child: _QuestionPreview(
                  question: question,
                  promptMaxLines: 6,
                  subPromptMaxLines: 4,
                  imageSize: 96,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuestionDetailCard(
                    label: 'Added',
                    value:
                        '${question.createdDate}\n${question.createdTime}\n${question.createdByUsername}',
                  ),
                  _QuestionDetailCard(
                    label: 'Updated',
                    value: question.updatedDate.isEmpty
                        ? 'Not available'
                        : '${question.updatedDate}\n${question.updatedTime}\n${question.updatedByUsername}',
                  ),
                  if (question.wordType.trim().isNotEmpty)
                    _QuestionDetailCard(
                      label: 'Word Type',
                      value: question.wordType,
                    ),
                  if (question.subPrompt.trim().isNotEmpty)
                    _QuestionDetailCard(
                      label: 'Sub-prompt',
                      value: question.subPrompt,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Answer Choices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _QuestionOptionTile(
                    optionLabel: 'A',
                    text: question.optionA,
                    selected: question.correctOpt == 'A',
                  ),
                  const SizedBox(height: 10),
                  _QuestionOptionTile(
                    optionLabel: 'B',
                    text: question.optionB,
                    selected: question.correctOpt == 'B',
                  ),
                  const SizedBox(height: 10),
                  _QuestionOptionTile(
                    optionLabel: 'C',
                    text: question.optionC,
                    selected: question.correctOpt == 'C',
                  ),
                  const SizedBox(height: 10),
                  _QuestionOptionTile(
                    optionLabel: 'D',
                    text: question.optionD,
                    selected: question.correctOpt == 'D',
                  ),
                ],
              ),
              if (question.funFact.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Fun Fact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(question.funFact),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Question'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onDelete,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hide Question'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionDetailCard extends StatelessWidget {
  final String label;
  final String value;

  const _QuestionDetailCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: FlareSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textLowEmphasis,
              ),
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuestionOptionTile extends StatelessWidget {
  final String optionLabel;
  final String text;
  final bool selected;

  const _QuestionOptionTile({
    required this.optionLabel,
    required this.text,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppTheme.accent.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.38);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.accent.withValues(alpha: 0.08)
            : AppTheme.surfaceLow.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.accent.withValues(alpha: 0.18)
                  : AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              optionLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected ? AppTheme.accent : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 12),
            const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _QuestionImportDialog extends ConsumerStatefulWidget {
  const _QuestionImportDialog();

  @override
  ConsumerState<_QuestionImportDialog> createState() =>
      _QuestionImportDialogState();
}

class _QuestionImportDialogState extends ConsumerState<_QuestionImportDialog> {
  static const List<String> _generationSteps = [
    'Reading lesson file',
    'Extracting usable text',
    'Asking AI to draft questions',
    'Checking grade and difficulty fit',
    'Validating answer choices',
    'Preparing editable preview',
  ];

  bool _generated = false;
  bool _generating = false;
  bool _committing = false;
  double _generationProgress = 0;
  int _generationStepIndex = 0;
  Timer? _generationTimer;
  PickedImportFileData? _selectedFile;
  StreamSubscription<PickedImportFileData>? _dropSubscription;
  String? _errorMessage;
  String? _generatedModel;
  final Set<int> _selected = <int>{};
  final List<Map<String, dynamic>> _drafts = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _dropSubscription = watchImportFileDrops().listen((file) {
      if (!mounted) return;
      setState(() {
        _selectedFile = file;
        _generated = false;
        _errorMessage = null;
        _generatedModel = null;
      });
    });
  }

  @override
  void dispose() {
    _generationTimer?.cancel();
    _dropSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = screen.width < 980 ? screen.width - 32 : 1120.0;
    final dialogHeight = screen.height < 760 ? screen.height - 40 : 720.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Import Questions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _committing || _generating
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _generated
                    ? _buildPreview(context)
                    : _generating
                    ? _buildGeneratingProgress(context)
                    : _buildUploadPrompt(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _generated
                          ? '${_selected.length} of ${_drafts.length} drafts selected'
                          : _generating
                          ? '${_generationSteps[_generationStepIndex]}...'
                          : _selectedFile == null
                          ? 'Choose a lesson file to generate a preview.'
                          : 'Ready to generate from ${_selectedFile!.name}.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _committing || _generating
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  if (!_generated)
                    FilledButton.icon(
                      onPressed: _selectedFile == null || _generating
                          ? null
                          : _generatePreview,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        _generating ? 'Generating...' : 'Generate Preview',
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _committing || _selected.isEmpty
                          ? null
                          : _commit,
                      icon: _committing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.publish_rounded, size: 18),
                      label: Text('Commit ${_selected.length} Selected'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FlareSectionTitle(
          title: 'Batch Upload From Lesson Files',
          subtitle:
              'Click the upload field to open file manager, then generate editable draft questions before saving.',
        ),
        const SizedBox(height: 18),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pickImportFile,
          child: Container(
            height: 230,
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.32),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedFile == null
                      ? Icons.cloud_upload_outlined
                      : Icons.task_rounded,
                  size: 52,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedFile == null
                      ? 'Click to upload or drag lesson file here'
                      : _selectedFile!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedFile == null
                      ? 'Supported right now: PDF and DOCX lesson files'
                      : '${(_selectedFile!.bytes.length / 1024).toStringAsFixed(1)} KB selected',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickImportFile,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(
                    _selectedFile == null
                        ? 'Browse File'
                        : 'Choose Another File',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FlarePill(label: 'Backend AI generation', color: AppTheme.primary),
            FlarePill(label: 'Editable preview first', color: AppTheme.success),
            FlarePill(label: 'Answer key validation', color: AppTheme.tertiary),
          ],
        ),
        if (ApiConstants.frontendOnly) ...[
          const SizedBox(height: 14),
          const Text(
            'AI import is disabled in FRONTEND_ONLY mode. Run KowTSide with .env.prod or set FRONTEND_ONLY=false so the dialog can call the backend.',
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGeneratingProgress(BuildContext context) {
    final selectedFileName = _selectedFile?.name ?? 'lesson file';
    final progressLabel =
        '${(_generationProgress * 100).clamp(0, 99).round()}%';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _generationSteps[_generationStepIndex],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              selectedFileName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMediumEmphasis,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _generationProgress.clamp(0.04, 0.96),
                minHeight: 12,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  progressLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                const Text('This can take 20-60 seconds on free models'),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: List<Widget>.generate(_generationSteps.length, (index) {
                final complete = index < _generationStepIndex;
                final active = index == _generationStepIndex;
                return _GenerationStepChip(
                  label: _generationSteps[index],
                  complete: complete,
                  active: active,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlareSectionTitle(
          title: 'Generated Preview',
          subtitle: _generatedModel == null
              ? 'Select only the rows you want to save. Teachers can edit the generated questions before committing.'
              : 'Generated with $_generatedModel. Review each draft before committing.',
          trailing: FlarePill(
            label: '${_selected.length}/${_drafts.length} selected',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _drafts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _DraftQuestionCard(
                index: index,
                draft: _drafts[index],
                selected: _selected.contains(index),
                onSelectedChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(index);
                    } else {
                      _selected.remove(index);
                    }
                  });
                },
                onChanged: (field, value) {
                  _drafts[index][field] = value;
                },
                onPickImage: () => _pickImageForDraft(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickImportFile() async {
    final file = await pickImportFileData();
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _selectedFile = file;
      _generated = false;
      _errorMessage = null;
      _generatedModel = null;
    });
  }

  Future<void> _generatePreview() async {
    if (_selectedFile == null) {
      return;
    }
    if (ApiConstants.frontendOnly) {
      setState(() {
        _errorMessage =
            'AI import needs the live backend. Switch to .env.prod or set FRONTEND_ONLY=false.';
      });
      return;
    }

    setState(() {
      _generating = true;
      _generationProgress = 0.06;
      _generationStepIndex = 0;
      _errorMessage = null;
      _generated = false;
      _generatedModel = null;
      _selected.clear();
      _drafts.clear();
    });
    _startGenerationProgress();

    try {
      final response = await dio.post(
        ApiConstants.questionImportGenerate,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _selectedFile!.bytes,
            filename: _selectedFile!.name,
          ),
        }),
        options: Options(
          headers: const {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      final payload = response.data as Map<String, dynamic>;
      final generated = (payload['questions'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (generated.isEmpty) {
        throw StateError('The AI provider returned no question drafts.');
      }

      setState(() {
        _generationProgress = 1;
        _drafts
          ..clear()
          ..addAll(generated);
        _selected
          ..clear()
          ..addAll(List<int>.generate(_drafts.length, (index) => index));
        _generated = true;
        _generatedModel = payload['model'] as String?;
      });
    } on DioException catch (error) {
      final responseData = error.response?.data;
      String message = 'Failed to generate preview.';
      if (responseData is Map<String, dynamic>) {
        final apiMessage = responseData['error'] as String?;
        if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
      setState(() => _errorMessage = message);
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      _generationTimer?.cancel();
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  void _startGenerationProgress() {
    _generationTimer?.cancel();
    _generationTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted || !_generating) {
        _generationTimer?.cancel();
        return;
      }

      setState(() {
        final nextProgress = _generationProgress + 0.045;
        _generationProgress = nextProgress > 0.92 ? 0.92 : nextProgress;
        final stepCount = _generationSteps.length;
        final nextStep = (_generationProgress * stepCount).floor();
        _generationStepIndex = nextStep.clamp(0, stepCount - 1);
      });
    });
  }

  Future<void> _pickImageForDraft(int index) async {
    final imageUrl = await QuestionImageService.pickAndUploadImage();
    if (imageUrl == null || !mounted) {
      return;
    }
    setState(() {
      _drafts[index]['image_url'] = imageUrl;
    });
  }

  Future<void> _commit() async {
    if (_selected.isEmpty) {
      return;
    }
    if (ApiConstants.frontendOnly) {
      setState(() {
        _errorMessage =
            'Question import commit needs the live backend. Switch to .env.prod or set FRONTEND_ONLY=false.';
      });
      return;
    }

    setState(() {
      _committing = true;
      _errorMessage = null;
    });

    try {
      final selectedQuestions = _selected.toList()..sort();
      await dio.post(
        ApiConstants.questionImportCommit,
        data: {
          'questions': selectedQuestions
              .map((index) => Map<String, dynamic>.from(_drafts[index]))
              .toList(),
        },
      );

      ref.invalidate(questionsProvider);
      ref.invalidate(allQuestionsProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Committed ${selectedQuestions.length} AI-generated question${selectedQuestions.length == 1 ? '' : 's'}.',
          ),
        ),
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;
      String message = 'Failed to commit selected questions.';
      if (responseData is Map<String, dynamic>) {
        final apiMessage = responseData['error'] as String?;
        if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
      setState(() => _errorMessage = message);
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _committing = false);
      }
    }
  }
}

class _GenerationStepChip extends StatelessWidget {
  final String label;
  final bool complete;
  final bool active;

  const _GenerationStepChip({
    required this.label,
    required this.complete,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete || active
        ? AppTheme.primary
        : Theme.of(context).colorScheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.45 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle_rounded
                : active
                ? Icons.autorenew_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? AppTheme.textHighEmphasis
                  : AppTheme.textMediumEmphasis,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftQuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> draft;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final void Function(String field, Object? value) onChanged;
  final VoidCallback onPickImage;

  const _DraftQuestionCard({
    required this.index,
    required this.draft,
    required this.selected,
    required this.onSelectedChanged,
    required this.onChanged,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = draft['image_url'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.07)
            : AppTheme.surfaceLow.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.38)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onSelectedChanged(value ?? false),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FlarePill(
                      label: 'Draft ${index + 1}',
                      color: AppTheme.primary,
                    ),
                    _CompactDropdown<int>(
                      label: 'Subject',
                      value: draft['subject_id'] as int,
                      items: subjectLabels,
                      onChanged: (value) {
                        if (value != null) onChanged('subject_id', value);
                      },
                    ),
                    _CompactDropdown<int>(
                      label: 'Group',
                      value: draft['gradelvl_id'] as int,
                      items: gradelvlLabels,
                      onChanged: (value) {
                        if (value != null) onChanged('gradelvl_id', value);
                      },
                    ),
                    _CompactDropdown<int>(
                      label: 'Difficulty',
                      value: draft['diff_id'] as int,
                      items: diffLabels,
                      onChanged: (value) {
                        if (value != null) onChanged('diff_id', value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final editor = _QuestionDraftEditor(
                draft: draft,
                onChanged: onChanged,
              );
              final image = _DraftImagePicker(
                imageUrl: imageUrl,
                onPickImage: onPickImage,
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [image, const SizedBox(height: 12), editor],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 180, child: image),
                  const SizedBox(width: 16),
                  Expanded(child: editor),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuestionDraftEditor extends StatelessWidget {
  final Map<String, dynamic> draft;
  final void Function(String field, Object? value) onChanged;

  const _QuestionDraftEditor({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: draft['question_txt'] as String? ?? '',
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Question'),
          onChanged: (value) => onChanged('question_txt', value),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 680;
            final optionFields = [
              _OptionField(
                label: 'Option A',
                value: draft['option_a'] as String? ?? '',
                onChanged: (value) => onChanged('option_a', value),
              ),
              _OptionField(
                label: 'Option B',
                value: draft['option_b'] as String? ?? '',
                onChanged: (value) => onChanged('option_b', value),
              ),
              _OptionField(
                label: 'Option C',
                value: draft['option_c'] as String? ?? '',
                onChanged: (value) => onChanged('option_c', value),
              ),
              _OptionField(
                label: 'Option D',
                value: draft['option_d'] as String? ?? '',
                onChanged: (value) => onChanged('option_d', value),
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: optionFields
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: field,
                      ),
                    )
                    .toList(),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: optionFields
                  .map(
                    (field) => SizedBox(
                      width: (constraints.maxWidth - 10) / 2,
                      child: field,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                initialValue: draft['correct_opt'] as String? ?? 'A',
                decoration: const InputDecoration(labelText: 'Answer'),
                items: const ['A', 'B', 'C', 'D']
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onChanged('correct_opt', value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: draft['word_type'] as String? ?? '',
                decoration: const InputDecoration(labelText: 'Word type'),
                onChanged: (value) => onChanged('word_type', value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: draft['sub_prompt'] as String? ?? '',
          decoration: const InputDecoration(labelText: 'Sub-prompt'),
          onChanged: (value) => onChanged('sub_prompt', value),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: draft['fun_fact'] as String? ?? '',
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Fun fact'),
          onChanged: (value) => onChanged('fun_fact', value),
        ),
      ],
    );
  }
}

class _OptionField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _OptionField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _DraftImagePicker extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onPickImage;

  const _DraftImagePicker({required this.imageUrl, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPickImage,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.36),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 34),
                  SizedBox(height: 8),
                  Text(
                    'Add image',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  _QuestionImage(imageUrl: imageUrl),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      color: Colors.black.withValues(alpha: 0.55),
                      child: const Text(
                        'Change image',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  const _CompactDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _QuestionPagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onPageSelected;

  const _QuestionPagination({
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

    return FlareSurfaceCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$startRow-$endRow of $totalRows',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
            onPressed: page < totalPages
                ? () => onPageSelected(page + 1)
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
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
