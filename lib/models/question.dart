class Question {
  final int questionId;
  final int subjectId;
  final int gradelvlId;
  final int diffId;
  final String questionTxt;
  final String imageUrl;
  final String funFact;
  final String wordType;
  final String subPrompt;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOpt;
  final bool isActive;
  final String createdDate;
  final String createdTime;
  final String updatedDate;
  final String updatedTime;
  final String createdByUsername;
  final String updatedByUsername;

  const Question({
    required this.questionId,
    required this.subjectId,
    required this.gradelvlId,
    required this.diffId,
    required this.questionTxt,
    required this.imageUrl,
    required this.funFact,
    required this.wordType,
    required this.subPrompt,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOpt,
    required this.isActive,
    this.createdDate = '',
    this.createdTime = '',
    this.updatedDate = '',
    this.updatedTime = '',
    this.createdByUsername = 'System import',
    this.updatedByUsername = 'System import',
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    questionId: _readInt(j['question_id']) ?? 0,
    subjectId: _readInt(j['subject_id']) ?? 0,
    gradelvlId: _readInt(j['gradelvl_id']) ?? 0,
    diffId: _readInt(j['diff_id']) ?? 0,
    questionTxt: j['question_txt'] as String? ?? '',
    imageUrl: j['image_url'] as String? ?? '',
    funFact: j['fun_fact'] as String? ?? '',
    wordType: j['word_type'] as String? ?? '',
    subPrompt: j['sub_prompt'] as String? ?? '',
    optionA: j['option_a'] as String? ?? '',
    optionB: j['option_b'] as String? ?? '',
    optionC: j['option_c'] as String? ?? '',
    optionD: j['option_d'] as String? ?? '',
    correctOpt: j['correct_opt'] as String? ?? 'A',
    isActive: (_readInt(j['is_active']) ?? 1) == 1,
    createdDate:
        j['created_date'] as String? ?? j['created_at'] as String? ?? '',
    createdTime: j['created_time'] as String? ?? '',
    updatedDate:
        j['updated_date'] as String? ?? j['updated_at'] as String? ?? '',
    updatedTime: j['updated_time'] as String? ?? '',
    createdByUsername: j['created_by_username'] as String? ?? 'System import',
    updatedByUsername: j['updated_by_username'] as String? ?? 'System import',
  );

  Map<String, dynamic> toJson() => {
    'subject_id': subjectId,
    'gradelvl_id': gradelvlId,
    'diff_id': diffId,
    'question_txt': questionTxt,
    'image_url': imageUrl.isEmpty ? null : imageUrl,
    'fun_fact': funFact,
    'word_type': wordType.isEmpty ? null : wordType,
    'sub_prompt': subPrompt.isEmpty ? null : subPrompt,
    'option_a': optionA,
    'option_b': optionB,
    'option_c': optionC,
    'option_d': optionD,
    'correct_opt': correctOpt,
    'is_active': isActive ? 1 : 0,
  };

  Question copyWith({
    int? questionId,
    int? subjectId,
    int? gradelvlId,
    int? diffId,
    String? questionTxt,
    String? imageUrl,
    String? funFact,
    String? wordType,
    String? subPrompt,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOpt,
    bool? isActive,
    String? createdDate,
    String? createdTime,
    String? updatedDate,
    String? updatedTime,
    String? createdByUsername,
    String? updatedByUsername,
  }) => Question(
    questionId: questionId ?? this.questionId,
    subjectId: subjectId ?? this.subjectId,
    gradelvlId: gradelvlId ?? this.gradelvlId,
    diffId: diffId ?? this.diffId,
    questionTxt: questionTxt ?? this.questionTxt,
    imageUrl: imageUrl ?? this.imageUrl,
    funFact: funFact ?? this.funFact,
    wordType: wordType ?? this.wordType,
    subPrompt: subPrompt ?? this.subPrompt,
    optionA: optionA ?? this.optionA,
    optionB: optionB ?? this.optionB,
    optionC: optionC ?? this.optionC,
    optionD: optionD ?? this.optionD,
    correctOpt: correctOpt ?? this.correctOpt,
    isActive: isActive ?? this.isActive,
    createdDate: createdDate ?? this.createdDate,
    createdTime: createdTime ?? this.createdTime,
    updatedDate: updatedDate ?? this.updatedDate,
    updatedTime: updatedTime ?? this.updatedTime,
    createdByUsername: createdByUsername ?? this.createdByUsername,
    updatedByUsername: updatedByUsername ?? this.updatedByUsername,
  );

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get usesImage => hasImage;

  String get teacherPrompt {
    if (hasImage) {
      return questionTxt.isEmpty ? "What's in the picture?" : questionTxt;
    }
    return questionTxt;
  }

  String get previewText {
    if (hasImage) {
      return 'Image-based prompt';
    }
    return questionTxt;
  }

  String get poolKey => '$gradelvlId-$subjectId-$diffId';
}

class QuestionPage {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<Question> questions;

  const QuestionPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.questions,
  });

  factory QuestionPage.fromJson(Map<String, dynamic> json) {
    final list = json['questions'] as List? ?? const <dynamic>[];
    final total = _readInt(json['total']) ?? list.length;
    final limit = _readInt(json['limit']) ?? 100;
    final totalPages =
        _readInt(json['total_pages']) ??
        (total == 0 ? 1 : ((total + limit - 1) ~/ limit));

    return QuestionPage(
      page: _readInt(json['page']) ?? 1,
      limit: limit,
      total: total,
      totalPages: totalPages < 1 ? 1 : totalPages,
      questions: list
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Reference maps used by dropdowns
const subjectLabels = {
  1: 'Mathematics',
  2: 'Science',
  3: 'Filipino',
  4: 'English',
};
const subjectSelectionLabels = {
  1: 'Mathematics',
  2: 'Science',
  3: 'Writing (Filipino)',
  4: 'Reading (English)',
};
const gradelvlLabels = {1: 'Punla (4-5)', 2: 'Binhi (6-7)'};
const diffLabels = {1: 'Easy', 2: 'Average', 3: 'Hard'};

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
