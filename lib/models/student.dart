class Student {
  final int studId;
  final String nickname;
  final String firstName;
  final String lastName;
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
    required this.age,
    required this.gradelvl,
    required this.sex,
    required this.totalSessions,
    required this.avgScore,
    required this.proficiency,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        studId: j['stud_id'] as int? ?? 0,
        nickname: j['nickname'] as String? ?? '',
        firstName: j['first_name'] as String? ?? '',
        lastName: j['last_name'] as String? ?? '',
        age: j['age'] as int? ?? 0,
        gradelvl: j['gradelvl'] as String? ?? '',
        sex: j['sex'] as String? ?? '',
        totalSessions: j['total_sessions'] as int? ?? 0,
        avgScore: (j['avg_score'] as num?)?.toDouble() ?? 0.0,
        proficiency: j['proficiency'] as String? ?? 'On track',
      );

  String get fullName => '$firstName $lastName';
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
        recentScores: (j['recent_scores'] as List? ?? [])
            .map((e) => ScoreRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SubjectProgress {
  final String subject;
  final String gradelvl;
  final int highestDiffPassed;
  final int totalTimePlayed;

  const SubjectProgress({
    required this.subject,
    required this.gradelvl,
    required this.highestDiffPassed,
    required this.totalTimePlayed,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> j) => SubjectProgress(
        subject: j['subject'] as String? ?? '',
        gradelvl: j['gradelvl'] as String? ?? '',
        highestDiffPassed: j['highest_diff_passed'] as int? ?? 0,
        totalTimePlayed: j['total_time_played'] as int? ?? 0,
      );

  String get diffLabel {
    switch (highestDiffPassed) {
      case 1: return 'Easy';
      case 2: return 'Average';
      case 3: return 'Hard';
      default: return 'None';
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
        lowestScore: (j['lowest_score'] as num?)?.toDouble() ?? 0.0,
        averageScore: (j['average_score'] as num?)?.toDouble() ?? 0.0,
        highestScore: (j['highest_score'] as num?)?.toDouble() ?? 0.0,
        totalAttempts: j['total_attempts'] as int? ?? 0,
      );
}

class ScoreRecord {
  final String subject;
  final String difficulty;
  final double score;
  final bool passed;
  final String playedAt;

  const ScoreRecord({
    required this.subject,
    required this.difficulty,
    required this.score,
    required this.passed,
    required this.playedAt,
  });

  factory ScoreRecord.fromJson(Map<String, dynamic> j) => ScoreRecord(
        subject: j['subject'] as String? ?? '',
        difficulty: j['difficulty'] as String? ?? '',
        score: (j['score'] as num?)?.toDouble() ?? 0.0,
        passed: (j['passed'] as int? ?? 0) == 1,
        playedAt: j['played_at'] as String? ?? '',
      );
}
