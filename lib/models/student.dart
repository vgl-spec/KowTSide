import '../core/student_id.dart';

class Student {
  final int studId;
  final String nickname;
  final String firstName;
  final String lastName;
  final String area;
  final String birthday;
  final int age;
  final String gradelvl;
  final String sex;
  final int totalSessions;
  final double avgScore;
  final String proficiency;

  const Student({
    required this.studId,
    required this.nickname,
    required this.firstName,
    required this.lastName,
    required this.area,
    required this.birthday,
    required this.age,
    required this.gradelvl,
    required this.sex,
    required this.totalSessions,
    required this.avgScore,
    required this.proficiency,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
    studId: parseStudentId(j['stud_id'] ?? j['studId']) ?? 0,
    nickname: j['nickname'] as String? ?? '',
    firstName: j['first_name'] as String? ?? '',
    lastName: j['last_name'] as String? ?? '',
    area: j['area'] as String? ?? j['barangay'] as String? ?? '',
    birthday: j['birthday'] as String? ?? '',
    age: _readInt(j['age']) ?? 0,
    gradelvl: _normalizeGradeLevelLabel(j['gradelvl']),
    sex: j['sex'] as String? ?? '',
    totalSessions: _readInt(j['total_sessions']) ?? 0,
    avgScore: _readDouble(j['avg_score']) ?? 0.0,
    proficiency: j['proficiency'] as String? ?? 'On track',
  );

  String get fullName => '$firstName $lastName';
  String get displayStudId => formatStudentId(studId);
}

String _normalizeGradeLevelLabel(Object? value) {
  final label = (value as String?)?.trim() ?? '';
  final lower = label.toLowerCase();
  if (lower.contains('punla')) {
    return 'Punla (4-5)';
  }
  if (lower.contains('binhi')) {
    return 'Binhi (6-8)';
  }
  return label;
}

class StudentPage {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<Student> students;

  const StudentPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.students,
  });

  factory StudentPage.fromJson(Map<String, dynamic> json) {
    final list =
        json['students'] as List? ?? json['data'] as List? ?? const <dynamic>[];
    final total = _readInt(json['total']) ?? list.length;
    final rawLimit = _readInt(json['limit']) ?? list.length;
    final limit = rawLimit <= 0 ? 1 : rawLimit;
    final totalPages =
        _readInt(json['total_pages']) ??
        (total == 0 ? 1 : ((total + limit - 1) ~/ limit));

    return StudentPage(
      page: _readInt(json['page']) ?? 1,
      limit: limit,
      total: total,
      totalPages: totalPages < 1 ? 1 : totalPages,
      students: list
          .map((item) => Student.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------- Detail models (GET /api/admin/students/:id) ----------

class StudentDetail {
  final Student profile;
  final List<SubjectProgress> progress;
  final List<SubjectAnalytics> analytics;
  final List<ScoreRecord> recentScores;

  const StudentDetail({
    required this.profile,
    required this.progress,
    required this.analytics,
    required this.recentScores,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> j) => StudentDetail(
    profile: Student.fromJson(j['profile'] as Map<String, dynamic>),
    progress: (j['progress'] as List? ?? [])
        .map((e) => SubjectProgress.fromJson(e as Map<String, dynamic>))
        .toList(),
    analytics: (j['analytics'] as List? ?? [])
        .map((e) => SubjectAnalytics.fromJson(e as Map<String, dynamic>))
        .toList(),
    recentScores:
        (j['recent_scores'] as List? ??
                j['scores'] as List? ??
                const <dynamic>[])
            .map((e) => ScoreRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
  );
}

class SubjectProgress {
  final String subject;
  final String gradelvl;
  final int highestDiffPassed;
  final int totalTimePlayed;
  final String lastPlayedAt;

  const SubjectProgress({
    required this.subject,
    required this.gradelvl,
    required this.highestDiffPassed,
    required this.totalTimePlayed,
    required this.lastPlayedAt,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> j) => SubjectProgress(
    subject: j['subject'] as String? ?? '',
    gradelvl: j['gradelvl'] as String? ?? '',
    highestDiffPassed: _readInt(j['highest_diff_passed']) ?? 0,
    totalTimePlayed: _readInt(j['total_time_played']) ?? 0,
    lastPlayedAt:
        j['last_played_at'] as String? ?? j['last_played'] as String? ?? '',
  );

  String get diffLabel {
    switch (highestDiffPassed) {
      case 1:
        return 'Easy';
      case 2:
        return 'Average';
      case 3:
        return 'Hard';
      default:
        return 'None';
    }
  }

  String get timeLabel {
    final m = totalTimePlayed ~/ 60;
    final s = totalTimePlayed % 60;
    return '${m}m ${s}s';
  }
}

class SubjectAnalytics {
  final String subject;
  final String gradelvl;
  final double lowestScore;
  final double averageScore;
  final double highestScore;
  final int totalAttempts;

  const SubjectAnalytics({
    required this.subject,
    required this.gradelvl,
    required this.lowestScore,
    required this.averageScore,
    required this.highestScore,
    required this.totalAttempts,
  });

  factory SubjectAnalytics.fromJson(Map<String, dynamic> j) => SubjectAnalytics(
    subject: j['subject'] as String? ?? '',
    gradelvl: j['gradelvl'] as String? ?? '',
    lowestScore: _readDouble(j['lowest_score']) ?? 0.0,
    averageScore: _readDouble(j['average_score']) ?? 0.0,
    highestScore: _readDouble(j['highest_score']) ?? 0.0,
    totalAttempts: _readInt(j['total_attempts']) ?? 0,
  );
}

class ScoreRecord {
  final String subject;
  final String gradelvl;
  final String difficulty;
  final double score;
  final int totalItems;
  final bool passed;
  final String playedAt;

  const ScoreRecord({
    required this.subject,
    required this.gradelvl,
    required this.difficulty,
    required this.score,
    required this.totalItems,
    required this.passed,
    required this.playedAt,
  });

  factory ScoreRecord.fromJson(Map<String, dynamic> j) => ScoreRecord(
    subject: j['subject'] as String? ?? '',
    gradelvl: j['gradelvl'] as String? ?? '',
    difficulty: j['difficulty'] as String? ?? '',
    score: _readDouble(j['score']) ?? 0.0,
    totalItems: _readInt(j['total_items']) ?? 10,
    passed: (_readInt(j['passed']) ?? 0) == 1 || j['passed'] == true,
    playedAt: j['played_at'] as String? ?? '',
  );
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
