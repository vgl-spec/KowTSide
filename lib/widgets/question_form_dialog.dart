import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/question_image_service.dart';
import '../core/theme.dart';
import '../models/question.dart';
import '../providers/questions_provider.dart';

class QuestionFormDialog extends ConsumerStatefulWidget {
  final Question? existing;

  const QuestionFormDialog({super.key, this.existing});

  @override
  ConsumerState<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends ConsumerState<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _questionCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _funFactCtrl;
  late final TextEditingController _wordTypeCtrl;
  late final TextEditingController _subPromptCtrl;
  late final TextEditingController _optionACtrl;
  late final TextEditingController _optionBCtrl;
  late final TextEditingController _optionCCtrl;
  late final TextEditingController _optionDCtrl;

  late int _subjectId;
  late int _gradelvlId;
  late int _diffId;
  late String _correctOpt;
  late bool _isActive;

  bool _saving = false;
  bool _uploading = false;
  String? _imageError;

  bool get _hasImage => _imageUrlCtrl.text.trim().isNotEmpty;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final question = widget.existing;
    _subjectId = question?.subjectId ?? 1;
    _gradelvlId = question?.gradelvlId ?? 1;
    _diffId = question?.diffId ?? 1;
    _correctOpt = question?.correctOpt ?? 'A';
    _isActive = question?.isActive ?? true;

    _questionCtrl = TextEditingController(
      text: question?.questionTxt ?? _defaultQuestionText(_diffId),
    );
    _imageUrlCtrl = TextEditingController(text: question?.imageUrl ?? '');
    _funFactCtrl = TextEditingController(text: question?.funFact ?? '');
    _wordTypeCtrl = TextEditingController(text: question?.wordType ?? '');
    _subPromptCtrl = TextEditingController(text: question?.subPrompt ?? '');
    _optionACtrl = TextEditingController(text: question?.optionA ?? '');
    _optionBCtrl = TextEditingController(text: question?.optionB ?? '');
    _optionCCtrl = TextEditingController(text: question?.optionC ?? '');
    _optionDCtrl = TextEditingController(text: question?.optionD ?? '');
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _imageUrlCtrl.dispose();
    _funFactCtrl.dispose();
    _wordTypeCtrl.dispose();
    _subPromptCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    super.dispose();
  }

  String _defaultQuestionText(int diffId) {
    if (diffId == 1) {
      return "What's in the picture?";
    }
    return '';
  }

  Future<void> _pickImage() async {
    setState(() {
      _uploading = true;
      _imageError = null;
    });

    try {
      final imageUrl = await QuestionImageService.pickAndUploadImage();
      if (!mounted) return;
      if (imageUrl == null || imageUrl.isEmpty) {
        setState(() {
          _uploading = false;
          _imageError = 'No image was selected.';
        });
        return;
      }

      setState(() {
        _uploading = false;
        _imageUrlCtrl.text = imageUrl;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _imageError =
            'Image upload failed. You can still paste an image URL manually.';
      });
    }
  }

  int _poolCount(List<Question> questions) {
    return questions
        .where(
          (question) =>
              question.gradelvlId == _gradelvlId &&
              question.subjectId == _subjectId &&
              question.diffId == _diffId &&
              question.isActive,
        )
        .length;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _onDifficultyChanged(int? value) {
    if (value == null) return;
    setState(() {
      _diffId = value;
      if (_questionCtrl.text.trim().isEmpty) {
        _questionCtrl.text = _defaultQuestionText(value);
      }
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _saving = true);

    final body = {
      'subject_id': _subjectId,
      'gradelvl_id': _gradelvlId,
      'diff_id': _diffId,
      'question_txt': _questionCtrl.text.trim(),
      'image_url': _imageUrlCtrl.text.trim(),
      'fun_fact': _funFactCtrl.text.trim(),
      'word_type': _wordTypeCtrl.text.trim(),
      'sub_prompt': _subPromptCtrl.text.trim(),
      'option_a': _optionACtrl.text.trim(),
      'option_b': _optionBCtrl.text.trim(),
      'option_c': _optionCCtrl.text.trim(),
      'option_d': _optionDCtrl.text.trim(),
      'correct_opt': _correctOpt,
      'is_active': _isActive ? 1 : 0,
    };

    final notifier = ref.read(questionsMutationProvider.notifier);
    final success = _isEdit
        ? await notifier.update(widget.existing!.questionId, body, ref)
        : await notifier.add(body, ref);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Question updated. Content version will refresh on devices.'
                : 'Question added. Content version will refresh on devices.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = false);
    final failureMessage =
        notifier.lastErrorMessage ?? 'Failed to save the question.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allQuestionsAsync = ref.watch(allQuestionsProvider);
    final poolCount = allQuestionsAsync.maybeWhen(
      data: _poolCount,
      orElse: () => 0,
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _isEdit ? 'Edit Question' : 'Add Question',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _PoolStatusChip(count: poolCount),
                    Chip(
                      label: Text(
                        'Content version updates automatically',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionCard(
                          title: 'Step 1: Select the target pool',
                          subtitle:
                              'Every question belongs to one grade + subject + difficulty cell.',
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _gradelvlId,
                                  decoration: const InputDecoration(
                                    labelText: 'Grade Level',
                                  ),
                                  items: gradelvlLabels.entries
                                      .map(
                                        (entry) => DropdownMenuItem<int>(
                                          value: entry.key,
                                          child: Text(entry.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _gradelvlId = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 260,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _subjectId,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject',
                                  ),
                                  items: subjectSelectionLabels.entries
                                      .map(
                                        (entry) => DropdownMenuItem<int>(
                                          value: entry.key,
                                          child: Text(entry.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _subjectId = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _diffId,
                                  decoration: const InputDecoration(
                                    labelText: 'Difficulty',
                                  ),
                                  items: diffLabels.entries
                                      .map(
                                        (entry) => DropdownMenuItem<int>(
                                          value: entry.key,
                                          child: Text(entry.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _onDifficultyChanged,
                                ),
                              ),
                              SizedBox(
                                width: 230,
                                child: _InlineInfoCard(
                                  label: 'Current pool',
                                  value:
                                      '$poolCount active question${poolCount == 1 ? '' : 's'}',
                                  helper: '5 are drawn per quiz session.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Step 2: Question content',
                          subtitle:
                              'Images are optional for every difficulty. Add one when it helps the learner, or leave it blank for text-only questions.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _ImagePreviewCard(
                                      imageUrl: _imageUrlCtrl.text.trim(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: FilledButton.tonalIcon(
                                            onPressed: _uploading
                                                ? null
                                                : _pickImage,
                                            icon: _uploading
                                                ? const SizedBox(
                                                    height: 16,
                                                    width: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.upload_rounded,
                                                  ),
                                            label: const Text(
                                              'Upload or choose image',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _imageUrlCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Image URL',
                                            helperText:
                                                'Optional for Easy, Average, and Hard questions.',
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        if (_imageError != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            _imageError!,
                                            style: const TextStyle(
                                              color: AppTheme.error,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _questionCtrl,
                                maxLines: _hasImage ? 3 : 4,
                                decoration: InputDecoration(
                                  labelText: _diffId == 1
                                      ? 'Prompt'
                                      : 'Statement or Definition',
                                  helperText: _hasImage
                                      ? 'This text will appear together with the image.'
                                      : 'Teachers can customize the learning prompt per pool.',
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 12),
                              if (_diffId != 1) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _wordTypeCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Word Type or Category',
                                          helperText: 'Optional',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _subPromptCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Sub-prompt',
                                          helperText: 'Optional',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _funFactCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Fun Fact',
                                  helperText:
                                      'Optional. Shown after the student answers the question.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Step 3: Answer choices',
                          subtitle:
                              'Use clear distractors and mark only one correct answer.',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _optionACtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Option A',
                                      ),
                                      validator: _required,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _optionBCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Option B',
                                      ),
                                      validator: _required,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _optionCCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Option C',
                                      ),
                                      validator: _required,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _optionDCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Option D',
                                      ),
                                      validator: _required,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _correctOpt,
                                      decoration: const InputDecoration(
                                        labelText: 'Correct Answer',
                                      ),
                                      items: const ['A', 'B', 'C', 'D']
                                          .map(
                                            (option) =>
                                                DropdownMenuItem<String>(
                                                  value: option,
                                                  child: Text(option),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() => _correctOpt = value);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SwitchListTile(
                                      value: _isActive,
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Active for students'),
                                      subtitle: const Text(
                                        'Inactive questions stay in the bank but are hidden from devices.',
                                      ),
                                      onChanged: (value) {
                                        setState(() => _isActive = value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEdit ? 'Save changes' : 'Create question'),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _InlineInfoCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(helper, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PoolStatusChip extends StatelessWidget {
  final int count;

  const _PoolStatusChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final color = count >= 8
        ? AppTheme.accent
        : count >= 5
        ? AppTheme.tertiary
        : AppTheme.error;

    return Chip(
      backgroundColor: color.withValues(alpha: 0.16),
      label: Text(
        'Pool health: ${count >= 8
            ? 'healthy'
            : count >= 5
            ? 'low'
            : 'critical'}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  final String imageUrl;

  const _ImagePreviewCard({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: imageUrl.isEmpty
          ? const Center(
              child: Text(
                'No image selected.\nQuestions can still be saved without one.',
                textAlign: TextAlign.center,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _QuestionImage(imageUrl: imageUrl),
            ),
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
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Text('Image preview unavailable')),
    );
  }

  Uint8List? _decodeDataUrl(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0 || commaIndex == value.length - 1) {
      return null;
    }

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
