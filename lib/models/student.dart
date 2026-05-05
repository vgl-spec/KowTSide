import '../core/student_id.dart';
import '../core/score_utils.dart';

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

  Student copyWith({
    int? studId,
    String? nickname,
    String? firstName,
    String? lastName,
    String? area,
    String? birthday,
    int? age,
    String? gradelvl,
    String? sex,
    int? totalSessions,
    double? avgScore,
    String? proficiency,
  }) {
    return Student(
      studId: studId ?? this.studId,
      nickname: nickname ?? this.nickname,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      area: area ?? this.area,
      birthday: birthday ?? this.birthday,
      age: age ?? this.age,
      gradelvl: gradelvl ?? this.gradelvl,
      sex: sex ?? this.sex,
      totalSessions: totalSessions ?? this.totalSessions,
      avgScore: avgScore ?? this.avgScore,
      proficiency: proficiency ?? this.proficiency,
    );
  }

  factory Student.fromJson(Map<String, dynamic> j) {
    final age = _readInt(j['age']) ?? 0;
    final avgScore = normalizeAverageScore(_readDouble(j['avg_score']) ?? 0.0);
    return Student(
      studId: parseStudentId(j['stud_id'] ?? j['studId']) ?? 0,
      nickname: j['nickname'] as String? ?? '',
      firstName: j['first_name'] as String? ?? '',
      lastName: j['last_name'] as String? ?? '',
      area: j['area'] as String? ?? j['barangay'] as String? ?? '',
      birthday: _dateOnly(j['birthday']),
      age: age,
      gradelvl: _normalizeGradeLevelLabel(j['gradelvl'], age: age),
      sex: _normalizeSexLabel(j['sex'] ?? j['sex_id']),
      totalSessions: _readInt(j['total_sessions']) ?? 0,
      avgScore: avgScore,
      proficiency: resolveProficiencyLabel(
        j['proficiency'] as String?,
        avgScore,
      ),
    );
  }

  String get fullName => '$firstName $lastName';
  String get displayStudId => formatStudentId(studId);
}

String _normalizeGradeLevelLabel(Object? value, {int? age}) {
  final label = (value as String?)?.trim() ?? '';
  final lower = label.toLowerCase();
  if (lower.contains('(4-5)') || lower.contains('(6-7)')) {
    return label;
  }
  if (lower.contains('binhi')) {
    return 'Binhi (4-5)';
  }
  if (lower.contains('punla')) {
    return 'Punla (6-7)';
  }
  if (label.isEmpty && age != null) {
    if (age >= 4 && age <= 5) return 'Binhi (4-5)';
    if (age >= 6 && age <= 7) return 'Punla (6-7)';
  }
  return label;
}

String _normalizeSexLabel(Object? value) {
  if (value is num) {
    return switch (value.toInt()) {
      1 => 'Male',
      2 => 'Female',
      _ => '',
    };
  }

  final label = (value as String?)?.trim() ?? '';
  final lower = label.toLowerCase();
  if (lower == '2' || lower == 'f' || lower == 'female') {
    return 'Female';
  }
  if (lower == '1' || lower == 'm' || lower == 'male') {
    return 'Male';
  }
  if (lower.contains('female')) {
    return 'Female';
  }
  if (lower.contains('male')) return 'Male';
  return label;
}

String _dateOnly(Object? value) {
  final raw = (value as String?)?.trim() ?? '';
  if (raw.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
    return raw.substring(0, 10);
  }
  return raw;
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
    profile: Student.fromJson(
      _readMap(j['profile']).isNotEmpty ? _readMap(j['profile']) : j,
    ),
    progress: _readList(j['progress']).map(SubjectProgress.fromJson).toList(),
    analytics: _readList(
      j['analytics'],
    ).map(SubjectAnalytics.fromJson).toList(),
    recentScores: _readStudentScoreList(j).map(ScoreRecord.fromJson).toList(),
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
    gradelvl: _normalizeGradeLevelLabel(j['gradelvl']),
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
    lowestScore: normalizeAverageScore(_readDouble(j['lowest_score']) ?? 0.0),
    averageScore: normalizeAverageScore(_readDouble(j['average_score']) ?? 0.0),
    highestScore: normalizeAverageScore(_readDouble(j['highest_score']) ?? 0.0),
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
    gradelvl: _normalizeGradeLevelLabel(j['gradelvl']),
    difficulty: _normalizeDifficultyLabel(j['difficulty'] ?? j['diff_id']),
    score: normalizeScoreValue(
      _readDouble(j['score']) ?? 0.0,
      sourceMax: (_readInt(j['total_items']) ?? 0).toDouble(),
    ),
    totalItems: normalizeScoreTotalItems(_readInt(j['total_items']) ?? 0),
    passed: _readPassedFlag(j),
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

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _readStudentScoreList(Map<String, dynamic> json) {
  const candidates = [
    'recent_scores',
    'scores',
    'score_history',
    'recentScores',
  ];

  for (final key in candidates) {
    final rows = _readList(json[key]);
    if (rows.isNotEmpty) {
      return rows;
    }
  }

  return const <Map<String, dynamic>>[];
}

String _normalizeDifficultyLabel(Object? value) {
  if (value is num) {
    return switch (value.toInt()) {
      1 => 'Easy',
      2 => 'Average',
      3 => 'Hard',
      _ => '',
    };
  }

  final label = (value as String?)?.trim() ?? '';
  final lower = label.toLowerCase();
  if (lower.contains('easy')) return 'Easy';
  if (lower.contains('average')) return 'Average';
  if (lower.contains('hard')) return 'Hard';
  return label;
}

bool _readPassedFlag(Map<String, dynamic> json) {
  final explicit =
      (_readInt(json['passed']) ?? 0) == 1 || json['passed'] == true;
  if (explicit) {
    return true;
  }

  final score = normalizeScoreValue(
    _readDouble(json['score']) ?? 0.0,
    sourceMax: (_readInt(json['total_items']) ?? 0).toDouble(),
  );
  return isPassingFivePointScore(score);
}
