import '../core/score_utils.dart';

class DashboardData {
  final int totalStudents;
  final int totalScores;
  final double averageScore;
  final double passRatePct;
  final String contentVersion;
  final List<AgeGroupProgress> ageGroupProgress;
  final List<PoolHealthEntry> poolHealth;

  const DashboardData({
    required this.totalStudents,
    required this.totalScores,
    required this.averageScore,
    required this.passRatePct,
    required this.contentVersion,
    required this.ageGroupProgress,
    required this.poolHealth,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    totalStudents: _readInt(j['total_students']) ?? 0,
    totalScores:
        _readInt(j['total_scores']) ?? _readInt(j['total_sessions']) ?? 0,
    averageScore: normalizeAverageScore(
      _readDouble(j['average_score']) ?? _readDouble(j['avg_score']) ?? 0.0,
    ),
    passRatePct: _readDouble(j['pass_rate_pct']) ?? 0.0,
    contentVersion:
        j['content_version'] as String? ?? j['version_tag'] as String? ?? 'v0',
    ageGroupProgress: _readAgeGroupProgress(j),
    poolHealth: (j['pool_health'] as List? ?? [])
        .map((e) => PoolHealthEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

List<AgeGroupProgress> _readAgeGroupProgress(Map<String, dynamic> json) {
  final directRows = _readList(
    json['age_group_progress'],
  ).map((e) => AgeGroupProgress.fromJson(e)).toList();
  if (directRows.isNotEmpty) {
    return directRows;
  }

  final summaryRows = _readList(
    json['subject_level_summary'],
  ).map((e) => _AgeGroupProgressSeed.fromJson(e)).toList();
  if (summaryRows.isEmpty) {
    return const [];
  }

  final grouped = <String, List<_AgeGroupProgressSeed>>{};
  for (final row in summaryRows) {
    final key = '${row.gradelvl}|${row.subject}';
    grouped.putIfAbsent(key, () => <_AgeGroupProgressSeed>[]).add(row);
  }

  return grouped.entries.map((entry) {
    final rows = entry.value;
    final totalStudents = rows.fold<int>(
      0,
      (sum, row) => sum + row.activeStudents,
    );
    final avgScore = _weightedAverage(
      values: rows.map((row) => row.avgScore).toList(),
      weights: rows.map((row) => row.activeStudents.toDouble()).toList(),
    );
    final passRate = _weightedAverage(
      values: rows.map((row) => row.passRatePct).toList(),
      weights: rows.map((row) => row.activeStudents.toDouble()).toList(),
    );

    final sample = rows.first;
    return AgeGroupProgress(
      gradelvl: sample.gradelvl,
      subject: sample.subject,
      activeStudents: totalStudents,
      avgScore: avgScore,
      passRatePct: passRate,
    );
  }).toList();
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
    avgScore: normalizeAverageScore(_readDouble(j['avg_score']) ?? 0.0),
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
  if (lower.contains('(4-5)') || lower.contains('(6-7)')) {
    return label;
  }
  if (lower.contains('binhi')) {
    return 'Binhi (4-5)';
  }
  if (lower.contains('punla')) {
    return 'Punla (6-7)';
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

List<Map<String, dynamic>> _readList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }
  return const [];
}

double _weightedAverage({
  required List<double> values,
  required List<double> weights,
}) {
  if (values.isEmpty || weights.isEmpty || values.length != weights.length) {
    return 0.0;
  }

  final totalWeight = weights.fold<double>(0.0, (sum, weight) => sum + weight);
  if (totalWeight <= 0) {
    return values.fold<double>(0.0, (sum, value) => sum + value) /
        values.length;
  }

  var weightedSum = 0.0;
  for (var index = 0; index < values.length; index++) {
    weightedSum += values[index] * weights[index];
  }
  return weightedSum / totalWeight;
}

class _AgeGroupProgressSeed {
  final String gradelvl;
  final String subject;
  final int activeStudents;
  final double avgScore;
  final double passRatePct;

  const _AgeGroupProgressSeed({
    required this.gradelvl,
    required this.subject,
    required this.activeStudents,
    required this.avgScore,
    required this.passRatePct,
  });

  factory _AgeGroupProgressSeed.fromJson(Map<String, dynamic> json) {
    return _AgeGroupProgressSeed(
      gradelvl: _normalizeGradeLevelLabel(json['gradelvl']),
      subject: json['subject'] as String? ?? '',
      activeStudents:
          _readInt(json['student_groups']) ??
          _readInt(json['active_students']) ??
          0,
      avgScore: normalizeAverageScore(_readDouble(json['avg_score']) ?? 0.0),
      passRatePct: _readDouble(json['pass_rate_pct']) ?? 0.0,
    );
  }
}
