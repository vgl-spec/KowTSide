class Question {
  final int questionId;
  final int subjectId;
  final int gradelvlId;
  final int diffId;
  final String questionTxt;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOpt;
  final bool isActive;

  const Question({
    required this.questionId,
    required this.subjectId,
    required this.gradelvlId,
    required this.diffId,
    required this.questionTxt,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOpt,
    required this.isActive,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        questionId: j['question_id'] as int? ?? 0,
        subjectId: j['subject_id'] as int? ?? 0,
        gradelvlId: j['gradelvl_id'] as int? ?? 0,
        diffId: j['diff_id'] as int? ?? 0,
        questionTxt: j['question_txt'] as String? ?? '',
        optionA: j['option_a'] as String? ?? '',
        optionB: j['option_b'] as String? ?? '',
        optionC: j['option_c'] as String? ?? '',
        optionD: j['option_d'] as String? ?? '',
        correctOpt: j['correct_opt'] as String? ?? 'A',
        isActive: (j['is_active'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'gradelvl_id': gradelvlId,
        'diff_id': diffId,
        'question_txt': questionTxt,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_opt': correctOpt,
      };

  Question copyWith({
    int? questionId,
    int? subjectId,
    int? gradelvlId,
    int? diffId,
    String? questionTxt,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOpt,
    bool? isActive,
  }) => Question(
        questionId: questionId ?? this.questionId,
        subjectId: subjectId ?? this.subjectId,
        gradelvlId: gradelvlId ?? this.gradelvlId,
        diffId: diffId ?? this.diffId,
        questionTxt: questionTxt ?? this.questionTxt,
        optionA: optionA ?? this.optionA,
        optionB: optionB ?? this.optionB,
        optionC: optionC ?? this.optionC,
        optionD: optionD ?? this.optionD,
        correctOpt: correctOpt ?? this.correctOpt,
        isActive: isActive ?? this.isActive,
      );
}

// Reference maps used by dropdowns
const subjectLabels = {1: 'Mathematics', 2: 'Science', 3: 'Filipino', 4: 'English'};
const gradelvlLabels = {1: 'Punla (3-5)', 2: 'Binhi (6-8)'};
const diffLabels = {1: 'Easy', 2: 'Average', 3: 'Hard'};
