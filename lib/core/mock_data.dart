import '../models/dashboard.dart';
import '../models/device.dart';
import '../models/question.dart';
import '../models/student.dart';

class MockData {
  static final List<Student> _students = [
    const Student(
      studId: 1001,
      nickname: 'Mari',
      firstName: 'Maria',
      lastName: 'Santos',
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
      age: 4,
      gradelvl: 'Punla (3-5)',
      sex: 'Female',
      totalSessions: 6,
      avgScore: 6.2,
      proficiency: 'Needs support',
    ),
  ];

  static final List<Question> _questions = [
    const Question(
      questionId: 2001,
      subjectId: 1,
      gradelvlId: 1,
      diffId: 1,
      questionTxt: 'What comes after number 2?',
      optionA: '1',
      optionB: '3',
      optionC: '4',
      optionD: '5',
      correctOpt: 'B',
      isActive: true,
    ),
    const Question(
      questionId: 2002,
      subjectId: 2,
      gradelvlId: 2,
      diffId: 2,
      questionTxt: 'Which part of the plant absorbs water?',
      optionA: 'Roots',
      optionB: 'Leaves',
      optionC: 'Flower',
      optionD: 'Stem',
      correctOpt: 'A',
      isActive: true,
    ),
    const Question(
      questionId: 2003,
      subjectId: 4,
      gradelvlId: 2,
      diffId: 1,
      questionTxt: 'Choose the correct spelling.',
      optionA: 'Apel',
      optionB: 'Aple',
      optionC: 'Apple',
      optionD: 'Appel',
      correctOpt: 'C',
      isActive: true,
    ),
  ];

  static int _nextQuestionId = 3000;

  static DashboardData dashboard() => DashboardData(
        totalStudents: _students.length,
        totalSessions: _students.fold<int>(
          0,
          (sum, s) => sum + s.totalSessions,
        ),
        activeDevices: 3,
        ageGroupProgress: const [
          AgeGroupProgress(
            gradelvl: 'Punla (3-5)',
            subject: 'Mathematics',
            activeStudents: 2,
            avgScore: 7.9,
            passRatePct: 75.0,
          ),
          AgeGroupProgress(
            gradelvl: 'Binhi (6-8)',
            subject: 'Science',
            activeStudents: 1,
            avgScore: 9.1,
            passRatePct: 100.0,
          ),
          AgeGroupProgress(
            gradelvl: 'Punla (3-5)',
            subject: 'English',
            activeStudents: 2,
            avgScore: 6.8,
            passRatePct: 60.0,
          ),
        ],
        recentSyncs: const [
          RecentSync(
            deviceUuid: 'DEV-0001',
            deviceName: 'Barangay Sauyo Tablet 1',
            lastSyncedAt: '2026-04-11 08:45',
            studentsSynced: 7,
          ),
          RecentSync(
            deviceUuid: 'DEV-0002',
            deviceName: 'Barangay Sauyo Tablet 2',
            lastSyncedAt: '2026-04-11 08:30',
            studentsSynced: 5,
          ),
        ],
      );

  static List<Student> students() => List<Student>.from(_students);

  static StudentDetail studentDetail(int id) {
    final profile = _students.firstWhere(
      (s) => s.studId == id,
      orElse: () => _students.first,
    );

    return StudentDetail(
      profile: profile,
      progress: const [
        SubjectProgress(
          subject: 'Mathematics',
          gradelvl: 'Punla (3-5)',
          highestDiffPassed: 2,
          totalTimePlayed: 520,
        ),
        SubjectProgress(
          subject: 'Science',
          gradelvl: 'Punla (3-5)',
          highestDiffPassed: 1,
          totalTimePlayed: 330,
        ),
      ],
      analytics: const [
        SubjectAnalytics(
          subject: 'Mathematics',
          gradelvl: 'Punla (3-5)',
          lowestScore: 5,
          averageScore: 7.8,
          highestScore: 10,
          totalAttempts: 8,
        ),
        SubjectAnalytics(
          subject: 'Science',
          gradelvl: 'Punla (3-5)',
          lowestScore: 4,
          averageScore: 7.1,
          highestScore: 9,
          totalAttempts: 6,
        ),
      ],
      recentScores: const [
        ScoreRecord(
          subject: 'Mathematics',
          difficulty: 'Average',
          score: 8,
          passed: true,
          playedAt: '2026-04-10 10:20',
        ),
        ScoreRecord(
          subject: 'Science',
          difficulty: 'Easy',
          score: 6,
          passed: false,
          playedAt: '2026-04-09 09:10',
        ),
      ],
    );
  }

  static List<Question> filteredQuestions({
    int? subjectId,
    int? gradelvlId,
    int? diffId,
    bool showInactive = false,
  }) {
    return _questions.where((q) {
      if (subjectId != null && q.subjectId != subjectId) {
        return false;
      }
      if (gradelvlId != null && q.gradelvlId != gradelvlId) {
        return false;
      }
      if (diffId != null && q.diffId != diffId) {
        return false;
      }
      if (!showInactive && !q.isActive) {
        return false;
      }
      return true;
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
        optionA: body['option_a'] as String? ?? '',
        optionB: body['option_b'] as String? ?? '',
        optionC: body['option_c'] as String? ?? '',
        optionD: body['option_d'] as String? ?? '',
        correctOpt: body['correct_opt'] as String? ?? 'A',
        isActive: true,
      ),
    );
  }

  static void updateQuestion(int id, Map<String, dynamic> body) {
    final idx = _questions.indexWhere((q) => q.questionId == id);
    if (idx < 0) return;
    _questions[idx] = _questions[idx].copyWith(
      subjectId: body['subject_id'] as int?,
      gradelvlId: body['gradelvl_id'] as int?,
      diffId: body['diff_id'] as int?,
      questionTxt: body['question_txt'] as String?,
      optionA: body['option_a'] as String?,
      optionB: body['option_b'] as String?,
      optionC: body['option_c'] as String?,
      optionD: body['option_d'] as String?,
      correctOpt: body['correct_opt'] as String?,
    );
  }

  static void softDeleteQuestion(int id) {
    final idx = _questions.indexWhere((q) => q.questionId == id);
    if (idx < 0) return;
    _questions[idx] = _questions[idx].copyWith(isActive: false);
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
        Device(
          deviceUuid: 'DEV-0003',
          deviceName: 'Barangay Sauyo Tablet 3',
          registeredAt: '2026-03-15 09:00',
          lastSyncedAt: null,
          studentsOnDevice: 0,
        ),
      ];
}
