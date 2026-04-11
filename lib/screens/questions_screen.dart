import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/questions_provider.dart';
import '../models/question.dart';

class QuestionsScreen extends ConsumerWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(questionFilterProvider);
    final async = ref.watch(questionsProvider);

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
                  onPressed: () => _showQuestionDialog(context, ref, null),
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
                    _FilterDropdown<int>(
                      label: 'Subject',
                      value: filter.subjectId,
                      items: subjectLabels,
                      onChanged: (v) =>
                          ref
                              .read(questionFilterProvider.notifier)
                              .state = v == null
                          ? filter.copyWith(clearSubject: true)
                          : filter.copyWith(subjectId: v),
                    ),
                    _FilterDropdown<int>(
                      label: 'Grade Level',
                      value: filter.gradelvlId,
                      items: gradelvlLabels,
                      onChanged: (v) =>
                          ref
                              .read(questionFilterProvider.notifier)
                              .state = v == null
                          ? filter.copyWith(clearGrade: true)
                          : filter.copyWith(gradelvlId: v),
                    ),
                    _FilterDropdown<int>(
                      label: 'Difficulty',
                      value: filter.diffId,
                      items: diffLabels,
                      onChanged: (v) =>
                          ref
                              .read(questionFilterProvider.notifier)
                              .state = v == null
                          ? filter.copyWith(clearDiff: true)
                          : filter.copyWith(diffId: v),
                    ),
                    FilterChip(
                      label: const Text('Show inactive'),
                      selected: filter.showInactive,
                      onSelected: (v) =>
                          ref.read(questionFilterProvider.notifier).state =
                              filter.copyWith(showInactive: v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Card(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                  data: (questions) => questions.isEmpty
                      ? const Center(child: Text('No questions found.'))
                      : Padding(
                          padding: const EdgeInsets.all(10),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                showCheckboxColumn: false,
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Subject')),
                                  DataColumn(label: Text('Level')),
                                  DataColumn(label: Text('Difficulty')),
                                  DataColumn(label: Text('Question')),
                                  DataColumn(label: Text('Answer')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: questions.map((question) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${question.questionId}')),
                                      DataCell(
                                        Text(
                                          subjectLabels[question.subjectId] ??
                                              '?',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          gradelvlLabels[question.gradelvlId] ??
                                              '?',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          diffLabels[question.diffId] ?? '?',
                                        ),
                                      ),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 320,
                                          ),
                                          child: Text(
                                            question.questionTxt,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${question.correctOpt}: ${_optionText(question, question.correctOpt)}',
                                        ),
                                      ),
                                      DataCell(
                                        _StatusChip(active: question.isActive),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              tooltip: 'Edit',
                                              onPressed: () =>
                                                  _showQuestionDialog(
                                                    context,
                                                    ref,
                                                    question,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: AppTheme.error,
                                              ),
                                              tooltip: 'Soft delete',
                                              onPressed: () => _confirmDelete(
                                                context,
                                                ref,
                                                question,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  void _showQuestionDialog(
    BuildContext context,
    WidgetRef ref,
    Question? existing,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestionFormDialog(existing: existing, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Question q) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text(
          'This will soft-delete question #${q.questionId}.\n\n'
          '"${q.questionTxt}"\n\nIt will be hidden from devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(questionsMutationProvider.notifier)
                  .softDelete(q.questionId, ref);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------- Filter Dropdown ----------

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

// ---------- Status chip ----------

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) => active
      ? const Chip(
          label: Text('Active'),
          backgroundColor: Color(0xFFE8F5E9),
          labelStyle: TextStyle(color: Colors.green, fontSize: 12),
          padding: EdgeInsets.zero,
        )
      : const Chip(
          label: Text('Inactive'),
          backgroundColor: Color(0xFFEEEEEE),
          labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
          padding: EdgeInsets.zero,
        );
}

// ---------- Question Form Dialog ----------

class QuestionFormDialog extends StatefulWidget {
  final Question? existing;
  final WidgetRef ref;
  const QuestionFormDialog({super.key, this.existing, required this.ref});

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _txtCtrl;
  late final TextEditingController _aCtrl;
  late final TextEditingController _bCtrl;
  late final TextEditingController _cCtrl;
  late final TextEditingController _dCtrl;
  late int _subjectId;
  late int _gradelvlId;
  late int _diffId;
  late String _correctOpt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _txtCtrl = TextEditingController(text: q?.questionTxt ?? '');
    _aCtrl = TextEditingController(text: q?.optionA ?? '');
    _bCtrl = TextEditingController(text: q?.optionB ?? '');
    _cCtrl = TextEditingController(text: q?.optionC ?? '');
    _dCtrl = TextEditingController(text: q?.optionD ?? '');
    _subjectId = q?.subjectId ?? 1;
    _gradelvlId = q?.gradelvlId ?? 1;
    _diffId = q?.diffId ?? 1;
    _correctOpt = q?.correctOpt ?? 'A';
  }

  @override
  void dispose() {
    _txtCtrl.dispose();
    _aCtrl.dispose();
    _bCtrl.dispose();
    _cCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'subject_id': _subjectId,
      'gradelvl_id': _gradelvlId,
      'diff_id': _diffId,
      'question_txt': _txtCtrl.text.trim(),
      'option_a': _aCtrl.text.trim(),
      'option_b': _bCtrl.text.trim(),
      'option_c': _cCtrl.text.trim(),
      'option_d': _dCtrl.text.trim(),
      'correct_opt': _correctOpt,
    };

    bool ok;
    if (widget.existing == null) {
      ok = await widget.ref
          .read(questionsMutationProvider.notifier)
          .add(body, widget.ref);
    } else {
      ok = await widget.ref
          .read(questionsMutationProvider.notifier)
          .update(widget.existing!.questionId, body, widget.ref);
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null ? 'Question added.' : 'Question updated.',
          ),
        ),
      );
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save question.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Question' : 'Add Question',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Classification row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _subjectId,
                                decoration: const InputDecoration(
                                  labelText: 'Subject',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: subjectLabels.entries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _subjectId = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _gradelvlId,
                                decoration: const InputDecoration(
                                  labelText: 'Grade Level',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: gradelvlLabels.entries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _gradelvlId = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _diffId,
                                decoration: const InputDecoration(
                                  labelText: 'Difficulty',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: diffLabels.entries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _diffId = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Question text
                        TextFormField(
                          controller: _txtCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Question Text',
                            border: OutlineInputBorder(),
                          ),
                          validator: _req,
                        ),
                        const SizedBox(height: 12),

                        // Options
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _aCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Option A',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: _req,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _bCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Option B',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: _req,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Option C',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: _req,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _dCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Option D',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: _req,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Correct answer
                        DropdownButtonFormField<String>(
                          initialValue: _correctOpt,
                          decoration: const InputDecoration(
                            labelText: 'Correct Answer',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: ['A', 'B', 'C', 'D']
                              .map(
                                (o) =>
                                    DropdownMenuItem(value: o, child: Text(o)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _correctOpt = v!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEdit ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
