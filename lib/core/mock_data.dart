import 'dart:convert';

import '../models/dashboard.dart';
import '../models/device.dart';
import '../models/question.dart';
import '../models/reporting.dart';
import '../models/student.dart';

class MockData {
  static final List<Student> _students = [
    const Student(
      studId: 1001,
      nickname: 'Mari',
      firstName: 'Maria',
      lastName: 'Santos',
      area: 'Sauyo',
      birthday: '2021-04-14',
      age: 5,
      gradelvl: 'Punla (3-5)',
      sex: 'Female',
      totalSessions: 14,
      avgScore: 8.6,
      proficiency: 'On track',
    ),
    const Student(
      studId: 1002,
      nickname: 'Jose',
      firstName: 'Jose',
      lastName: 'Reyes',
      area: 'Sauyo',
      birthday: '2019-09-08',
      age: 7,
      gradelvl: 'Binhi (6-8)',
      sex: 'Male',
      totalSessions: 10,
      avgScore: 9.1,
      proficiency: 'Excelling',
    ),
    const Student(
      studId: 1003,
      nickname: 'Ana',
      firstName: 'Ana',
      lastName: 'Dela Cruz',
      area: 'Sauyo',
      birthday: '2022-01-20',
      age: 4,
      gradelvl: 'Punla (3-5)',
      sex: 'Female',
      totalSessions: 6,
      avgScore: 6.2,
      proficiency: 'Needs support',
    ),
    const Student(
      studId: 1004,
      nickname: 'Liam',
      firstName: 'Liam',
      lastName: 'Garcia',
      area: 'Sauyo',
      birthday: '2020-06-18',
      age: 6,
      gradelvl: 'Binhi (6-8)',
      sex: 'Male',
      totalSessions: 9,
      avgScore: 7.4,
      proficiency: 'On track',
    ),
  ];

  static final List<Question> _questions = [
    Question(
      questionId: 2001,
      subjectId: 1,
      gradelvlId: 1,
      diffId: 1,
      questionTxt: "What's in the picture?",
      imageUrl: _svgDataUrl(
        label: 'DOG',
        background: '#FFE08A',
        accent: '#7C4D29',
      ),
      funFact: 'Dogs use their noses to explore the world.',
      wordType: '',
      subPrompt: '',
      optionA: 'Cat',
      optionB: 'Dog',
      optionC: 'Bird',
      optionD: 'Fish',
      correctOpt: 'B',
      isActive: true,
    ),
    Question(
      questionId: 2002,
      subjectId: 1,
      gradelvlId: 1,
      diffId: 1,
      questionTxt: "What's in the picture?",
      imageUrl: _svgDataUrl(
        label: 'SUN',
        background: '#C6F1FF',
        accent: '#FFAA00',
      ),
      funFact: 'The sun gives us light and warmth.',
      wordType: '',
      subPrompt: '',
      optionA: 'Moon',
      optionB: 'Cloud',
      optionC: 'Sun',
      optionD: 'Star',
      correctOpt: 'C',
      isActive: true,
    ),
    const Question(
      questionId: 2003,
      subjectId: 1,
      gradelvlId: 1,
      diffId: 2,
      questionTxt: 'Which number comes after 4?',
      imageUrl: '',
      funFact: 'Counting in order helps us solve bigger math problems.',
      wordType: 'Counting',
      subPrompt: 'What is the correct next number?',
      optionA: '5',
      optionB: '3',
      optionC: '6',
      optionD: '2',
      correctOpt: 'A',
      isActive: true,
    ),
    Question(
      questionId: 2004,
      subjectId: 2,
      gradelvlId: 1,
      diffId: 1,
      questionTxt: "What's in the picture?",
      imageUrl: _svgDataUrl(
        label: 'PLANT',
        background: '#DDF7D8',
        accent: '#2C7A3F',
      ),
      funFact: 'Plants need water, sunlight, and soil to grow.',
      wordType: '',
      subPrompt: '',
      optionA: 'Plant',
      optionB: 'Chair',
      optionC: 'Car',
      optionD: 'Clock',
      correctOpt: 'A',
      isActive: true,
    ),
    const Question(
      questionId: 2005,
      subjectId: 2,
      gradelvlId: 2,
      diffId: 2,
      questionTxt: 'The part of the plant that absorbs water from the soil.',
      imageUrl: '',
      funFact: 'Roots help anchor plants to the ground.',
      wordType: 'Science',
      subPrompt: 'What word is described in the statement?',
      optionA: 'Leaves',
      optionB: 'Roots',
      optionC: 'Flowers',
      optionD: 'Seeds',
      correctOpt: 'B',
      isActive: true,
    ),
    const Question(
      questionId: 2006,
      subjectId: 4,
      gradelvlId: 1,
      diffId: 2,
      questionTxt: 'A word that names a person, place, or thing.',
      imageUrl: '',
      funFact: 'Nouns are one of the first word types children learn.',
      wordType: 'Noun',
      subPrompt: 'What is the word described in the statement?',
      optionA: 'Run',
      optionB: 'Blue',
      optionC: 'Teacher',
      optionD: 'Quickly',
      correctOpt: 'C',
      isActive: true,
    ),
    const Question(
      questionId: 2007,
      subjectId: 4,
      gradelvlId: 2,
      diffId: 3,
      questionTxt:
          'A word or phrase that compares two things using "like" or "as".',
      imageUrl: '',
      funFact: 'Similes make writing more vivid and descriptive.',
      wordType: 'Literary Device',
      subPrompt: 'What literary device is being described?',
      optionA: 'Metaphor',
      optionB: 'Simile',
      optionC: 'Noun',
      optionD: 'Verb',
      correctOpt: 'B',
      isActive: true,
    ),
    const Question(
      questionId: 2008,
      subjectId: 3,
      gradelvlId: 1,
      diffId: 2,
      questionTxt: 'Salitang tumutukoy sa kilos o galaw.',
      imageUrl: '',
      funFact: 'Pandiwa ang tawag sa mga salitang kilos.',
      wordType: 'Pandiwa',
      subPrompt: 'Anong salitang inilalarawan ng pahayag?',
      optionA: 'Maganda',
      optionB: 'Tumakbo',
      optionC: 'Mesa',
      optionD: 'Mabilis',
      correctOpt: 'B',
      isActive: true,
    ),
    const Question(
      questionId: 2009,
      subjectId: 3,
      gradelvlId: 2,
      diffId: 3,
      questionTxt: 'Pahayag na may magkatulad na tunog sa hulihan ng salita.',
      imageUrl: '',
      funFact: 'Tugma ang nagpapaganda sa mga tula at awitin.',
      wordType: 'Panitikan',
      subPrompt: 'Anong katangian ng tula ang inilalarawan?',
      optionA: 'Tugma',
      optionB: 'Sukat',
      optionC: 'Simula',
      optionD: 'Paksa',
      correctOpt: 'A',
      isActive: true,
    ),
    const Question(
      questionId: 2010,
      subjectId: 1,
      gradelvlId: 2,
      diffId: 2,
      questionTxt:
          'If you have 3 apples and get 2 more, how many apples do you have?',
      imageUrl: '',
      funFact: 'Addition helps us combine groups of objects.',
      wordType: 'Addition',
      subPrompt: 'Which answer solves the story problem?',
      optionA: '4',
      optionB: '5',
      optionC: '6',
      optionD: '7',
      correctOpt: 'B',
      isActive: true,
    ),
    const Question(
      questionId: 2011,
      subjectId: 2,
      gradelvlId: 2,
      diffId: 3,
      questionTxt:
          'A change from liquid water into water vapor because of heat.',
      imageUrl: '',
      funFact: 'Evaporation is part of the water cycle.',
      wordType: 'Science',
      subPrompt: 'What process is described?',
      optionA: 'Condensation',
      optionB: 'Evaporation',
      optionC: 'Freezing',
      optionD: 'Melting',
      correctOpt: 'B',
      isActive: true,
    ),
    const Question(
      questionId: 2012,
      subjectId: 4,
      gradelvlId: 2,
      diffId: 2,
      questionTxt: 'A word that describes a noun.',
      imageUrl: '',
      funFact: 'Adjectives tell us more about people, places, and things.',
      wordType: 'Adjective',
      subPrompt: 'What is the word described in the statement?',
      optionA: 'Jump',
      optionB: 'Slowly',
      optionC: 'Colorful',
      optionD: 'Teacher',
      correctOpt: 'C',
      isActive: true,
    ),
    const Question(
      questionId: 2013,
      subjectId: 1,
      gradelvlId: 2,
      diffId: 3,
      questionTxt: 'A shape with four equal sides and four right angles.',
      imageUrl: '',
      funFact: 'Squares are special rectangles with equal side lengths.',
      wordType: 'Geometry',
      subPrompt: 'Which shape is being described?',
      optionA: 'Triangle',
      optionB: 'Circle',
      optionC: 'Square',
      optionD: 'Oval',
      correctOpt: 'C',
      isActive: false,
    ),
  ];

  static int _nextQuestionId = 3000;

  static DashboardData dashboard() {
    final totalScores = _students.fold<int>(
      0,
      (sum, student) => sum + student.totalSessions,
    );
    final weightedTotal = _students.fold<double>(
      0,
      (sum, student) => sum + (student.avgScore * student.totalSessions),
    );
    final averageScore = totalScores == 0 ? 0.0 : weightedTotal / totalScores;

    return DashboardData(
      totalStudents: _students.length,
      totalScores: totalScores,
      averageScore: averageScore,
      contentVersion: 'v43',
      ageGroupProgress: const [
        AgeGroupProgress(
          gradelvl: 'Punla (3-5)',
          subject: 'Mathematics',
          activeStudents: 2,
          avgScore: 7.9,
          passRatePct: 75.0,
        ),
        AgeGroupProgress(
          gradelvl: 'Punla (3-5)',
          subject: 'English',
          activeStudents: 2,
          avgScore: 6.8,
          passRatePct: 60.0,
        ),
        AgeGroupProgress(
          gradelvl: 'Binhi (6-8)',
          subject: 'Science',
          activeStudents: 2,
          avgScore: 8.9,
          passRatePct: 91.0,
        ),
        AgeGroupProgress(
          gradelvl: 'Binhi (6-8)',
          subject: 'Filipino',
          activeStudents: 2,
          avgScore: 6.3,
          passRatePct: 54.0,
        ),
      ],
      poolHealth: poolHealth(),
    );
  }

  static List<Student> students() => List<Student>.from(_students);

  static List<Question> questions() => List<Question>.from(_questions);

  static StudentDetail studentDetail(int id) {
    final profile = _students.firstWhere(
      (student) => student.studId == id,
      orElse: () => _students.first,
    );

    switch (id) {
      case 1002:
        return StudentDetail(
          profile: profile,
          progress: const [
            SubjectProgress(
              subject: 'Mathematics',
              gradelvl: 'Binhi (6-8)',
              highestDiffPassed: 3,
              totalTimePlayed: 1180,
              lastPlayedAt: '2026-04-18',
            ),
            SubjectProgress(
              subject: 'Science',
              gradelvl: 'Binhi (6-8)',
              highestDiffPassed: 2,
              totalTimePlayed: 940,
              lastPlayedAt: '2026-04-18',
            ),
          ],
          analytics: const [],
          recentScores: const [
            ScoreRecord(
              subject: 'Mathematics',
              gradelvl: 'Binhi (6-8)',
              difficulty: 'Hard',
              score: 9,
              totalItems: 10,
              passed: true,
              playedAt: '2026-04-18',
            ),
            ScoreRecord(
              subject: 'Science',
              gradelvl: 'Binhi (6-8)',
              difficulty: 'Average',
              score: 8,
              totalItems: 10,
              passed: true,
              playedAt: '2026-04-17',
            ),
          ],
        );
      case 1003:
        return StudentDetail(
          profile: profile,
          progress: const [
            SubjectProgress(
              subject: 'English',
              gradelvl: 'Punla (3-5)',
              highestDiffPassed: 1,
              totalTimePlayed: 260,
              lastPlayedAt: '2026-04-16',
            ),
            SubjectProgress(
              subject: 'Filipino',
              gradelvl: 'Punla (3-5)',
              highestDiffPassed: 0,
              totalTimePlayed: 180,
              lastPlayedAt: '2026-04-15',
            ),
          ],
          analytics: const [],
          recentScores: const [
            ScoreRecord(
              subject: 'English',
              gradelvl: 'Punla (3-5)',
              difficulty: 'Easy',
              score: 7,
              totalItems: 10,
              passed: true,
              playedAt: '2026-04-16',
            ),
            ScoreRecord(
              subject: 'Filipino',
              gradelvl: 'Punla (3-5)',
              difficulty: 'Easy',
              score: 5,
              totalItems: 10,
              passed: false,
              playedAt: '2026-04-15',
            ),
          ],
        );
      default:
        return StudentDetail(
          profile: profile,
          progress: const [
            SubjectProgress(
              subject: 'Mathematics',
              gradelvl: 'Punla (3-5)',
              highestDiffPassed: 2,
              totalTimePlayed: 520,
              lastPlayedAt: '2026-04-18',
            ),
            SubjectProgress(
              subject: 'Science',
              gradelvl: 'Punla (3-5)',
              highestDiffPassed: 1,
              totalTimePlayed: 330,
              lastPlayedAt: '2026-04-17',
            ),
          ],
          analytics: const [],
          recentScores: const [
            ScoreRecord(
              subject: 'Mathematics',
              gradelvl: 'Punla (3-5)',
              difficulty: 'Average',
              score: 8,
              totalItems: 10,
              passed: true,
              playedAt: '2026-04-18',
            ),
            ScoreRecord(
              subject: 'Science',
              gradelvl: 'Punla (3-5)',
              difficulty: 'Easy',
              score: 6,
              totalItems: 10,
              passed: false,
              playedAt: '2026-04-17',
            ),
          ],
        );
    }
  }

  static List<Question> filteredQuestions({
    int? subjectId,
    int? gradelvlId,
    int? diffId,
    bool showInactive = false,
    String search = '',
    String sortOrder = 'created_desc',
  }) {
    final needle = search.trim().toLowerCase();
    final filtered = _questions.where((question) {
      if (subjectId != null && question.subjectId != subjectId) {
        return false;
      }
      if (gradelvlId != null && question.gradelvlId != gradelvlId) {
        return false;
      }
      if (diffId != null && question.diffId != diffId) {
        return false;
      }
      if (!showInactive && !question.isActive) {
        return false;
      }
      if (needle.isNotEmpty) {
        final haystack = [
          question.questionTxt,
          question.optionA,
          question.optionB,
          question.optionC,
          question.optionD,
        ].join(' ').toLowerCase();
        if (!haystack.contains(needle)) {
          return false;
        }
      }
      return true;
    }).toList();

    int compareByDateDesc(Question a, Question b) =>
        b.questionId.compareTo(a.questionId);
    int compareByDateAsc(Question a, Question b) =>
        a.questionId.compareTo(b.questionId);
    int compareByPool(Question a, Question b) {
      final subjectCompare = a.subjectId.compareTo(b.subjectId);
      if (a.gradelvlId != b.gradelvlId) {
        return a.gradelvlId.compareTo(b.gradelvlId);
      }
      if (subjectCompare != 0) {
        return subjectCompare;
      }
      if (a.diffId != b.diffId) {
        return a.diffId.compareTo(b.diffId);
      }
      return a.questionId.compareTo(b.questionId);
    }

    switch (sortOrder) {
      case 'created_asc':
        filtered.sort(compareByDateAsc);
        break;
      case 'updated_desc':
      case 'created_desc':
        filtered.sort(compareByDateDesc);
        break;
      default:
        filtered.sort(compareByPool);
        break;
    }

    return filtered;
  }

  static List<PoolHealthEntry> poolHealth() {
    final activeQuestions = _questions.where((question) => question.isActive);
    final counts = <String, int>{};

    for (final question in activeQuestions) {
      counts.update(question.poolKey, (value) => value + 1, ifAbsent: () => 1);
    }

    final entries = <PoolHealthEntry>[];
    for (final grade in gradelvlLabels.entries) {
      for (final subject in subjectLabels.entries) {
        for (final difficulty in diffLabels.entries) {
          final key = '${grade.key}-${subject.key}-${difficulty.key}';
          entries.add(
            PoolHealthEntry(
              gradelvlId: grade.key,
              subjectId: subject.key,
              diffId: difficulty.key,
              gradelvl: grade.value,
              subject: subject.value,
              difficulty: difficulty.value,
              questionCount: counts[key] ?? 0,
            ),
          );
        }
      }
    }

    return entries;
  }

  static List<LeaderboardEntry> leaderboard() {
    final raw = [
      (student: _students[1], totalScore: 91.0),
      (student: _students[0], totalScore: 81.0),
      (student: _students[3], totalScore: 67.0),
      (student: _students[2], totalScore: 37.0),
    ];

    return raw.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      return LeaderboardEntry(
        rank: index + 1,
        studId: value.student.studId,
        nickname: value.student.nickname,
        fullName: value.student.fullName,
        gradelvl: value.student.gradelvl,
        totalScore: value.totalScore,
        sessions: value.student.totalSessions,
      );
    }).toList();
  }

  static void addQuestion(Map<String, dynamic> body) {
    _questions.add(
      Question(
        questionId: _nextQuestionId++,
        subjectId: body['subject_id'] as int? ?? 1,
        gradelvlId: body['gradelvl_id'] as int? ?? 1,
        diffId: body['diff_id'] as int? ?? 1,
        questionTxt: body['question_txt'] as String? ?? '',
        imageUrl: body['image_url'] as String? ?? '',
        funFact: body['fun_fact'] as String? ?? '',
        wordType: body['word_type'] as String? ?? '',
        subPrompt: body['sub_prompt'] as String? ?? '',
        optionA: body['option_a'] as String? ?? '',
        optionB: body['option_b'] as String? ?? '',
        optionC: body['option_c'] as String? ?? '',
        optionD: body['option_d'] as String? ?? '',
        correctOpt: body['correct_opt'] as String? ?? 'A',
        isActive: (body['is_active'] as int? ?? 1) == 1,
      ),
    );
  }

  static void updateQuestion(int id, Map<String, dynamic> body) {
    final index = _questions.indexWhere(
      (question) => question.questionId == id,
    );
    if (index < 0) return;

    _questions[index] = _questions[index].copyWith(
      subjectId: body['subject_id'] as int?,
      gradelvlId: body['gradelvl_id'] as int?,
      diffId: body['diff_id'] as int?,
      questionTxt: body['question_txt'] as String?,
      imageUrl: body['image_url'] as String?,
      funFact: body['fun_fact'] as String?,
      wordType: body['word_type'] as String?,
      subPrompt: body['sub_prompt'] as String?,
      optionA: body['option_a'] as String?,
      optionB: body['option_b'] as String?,
      optionC: body['option_c'] as String?,
      optionD: body['option_d'] as String?,
      correctOpt: body['correct_opt'] as String?,
      isActive: body.containsKey('is_active')
          ? (body['is_active'] as int? ?? 1) == 1
          : null,
    );
  }

  static void softDeleteQuestion(int id) {
    final index = _questions.indexWhere(
      (question) => question.questionId == id,
    );
    if (index < 0) return;
    _questions[index] = _questions[index].copyWith(isActive: false);
  }

  static List<Device> devices() => const [
    Device(
      deviceUuid: 'DEV-0001',
      deviceName: 'Barangay Sauyo Tablet 1',
      registeredAt: '2026-03-12 09:00',
      lastSyncedAt: '2026-04-11 08:45',
      studentsOnDevice: 12,
    ),
    Device(
      deviceUuid: 'DEV-0002',
      deviceName: 'Barangay Sauyo Tablet 2',
      registeredAt: '2026-03-13 09:00',
      lastSyncedAt: '2026-04-11 08:30',
      studentsOnDevice: 9,
    ),
  ];
}

String _svgDataUrl({
  required String label,
  required String background,
  required String accent,
}) {
  final svg =
      '''
<svg xmlns="http://www.w3.org/2000/svg" width="320" height="200" viewBox="0 0 320 200">
  <rect width="320" height="200" rx="28" fill="$background" />
  <circle cx="82" cy="72" r="34" fill="$accent" opacity="0.18" />
  <circle cx="248" cy="132" r="46" fill="$accent" opacity="0.14" />
  <rect x="40" y="46" width="240" height="108" rx="24" fill="white" fill-opacity="0.82" />
  <text x="160" y="112" text-anchor="middle" font-family="Arial" font-size="34" font-weight="700" fill="$accent">$label</text>
</svg>
''';

  return Uri.dataFromString(
    svg,
    mimeType: 'image/svg+xml',
    encoding: utf8,
  ).toString();
}
