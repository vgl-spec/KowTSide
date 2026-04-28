class DashboardData {
  final int totalStudents;
  final int totalScores;
  final double averageScore;
  final String contentVersion;
  final List<AgeGroupProgress> ageGroupProgress;
  final List<PoolHealthEntry> poolHealth;

  const DashboardData({
    required this.totalStudents,
    required this.totalScores,
    required this.averageScore,
    required this.contentVersion,
    required this.ageGroupProgress,
    required this.poolHealth,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    totalStudents: _readInt(j['total_students']) ?? 0,
    totalScores:
        _readInt(j['total_scores']) ?? _readInt(j['total_sessions']) ?? 0,
    averageScore:
        _readDouble(j['average_score']) ?? _readDouble(j['avg_score']) ?? 0.0,
    contentVersion:
        j['content_version'] as String? ?? j['version_tag'] as String? ?? 'v0',
    ageGroupProgress: (j['age_group_progress'] as List? ?? [])
        .map((e) => AgeGroupProgress.fromJson(e as Map<String, dynamic>))
        .toList(),
    poolHealth: (j['pool_health'] as List? ?? [])
        .map((e) => PoolHealthEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class AgeGroupProgress {
  final String gradelvl;
  final String subject;
  final int activeStudents;
  final double avgScore;
  final double passRatePct;

  const AgeGroupProgress({
    required this.gradelvl,
    required this.subject,
    required this.activeStudents,
    required this.avgScore,
    required this.passRatePct,
  });

  factory AgeGroupProgress.fromJson(Map<String, dynamic> j) => AgeGroupProgress(
    gradelvl: _normalizeGradeLevelLabel(j['gradelvl']),
    subject: j['subject'] as String? ?? '',
    activeStudents: _readInt(j['active_students']) ?? 0,
    avgScore: _readDouble(j['avg_score']) ?? 0.0,
    passRatePct: _readDouble(j['pass_rate_pct']) ?? 0.0,
  );
}

class PoolHealthEntry {
  final int gradelvlId;
  final int subjectId;
  final int diffId;
  final String gradelvl;
  final String subject;
  final String difficulty;
  final int questionCount;

  const PoolHealthEntry({
    required this.gradelvlId,
    required this.subjectId,
    required this.diffId,
    required this.gradelvl,
    required this.subject,
    required this.difficulty,
    required this.questionCount,
  });

  factory PoolHealthEntry.fromJson(Map<String, dynamic> j) => PoolHealthEntry(
    gradelvlId: _readInt(j['gradelvl_id']) ?? 0,
    subjectId: _readInt(j['subject_id']) ?? 0,
    diffId: _readInt(j['diff_id']) ?? 0,
    gradelvl: _normalizeGradeLevelLabel(j['gradelvl']),
    subject: j['subject'] as String? ?? '',
    difficulty: j['difficulty'] as String? ?? '',
    questionCount: _readInt(j['question_count']) ?? 0,
  );

  String get healthLabel {
    if (questionCount >= 8) return 'Healthy';
    if (questionCount >= 5) return 'Low';
    return 'Critical';
  }
}

String _normalizeGradeLevelLabel(Object? value) {
  final label = (value as String?)?.trim() ?? '';
  final lower = label.toLowerCase();
  if (lower.contains('punla')) {
    return 'Punla (3-5)';
  }
  if (lower.contains('binhi')) {
    return 'Binhi (6-8)';
  }
  return label;
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
