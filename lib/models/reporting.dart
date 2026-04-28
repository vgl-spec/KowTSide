import '../core/student_id.dart';
import 'dashboard.dart';
import 'student.dart';

class LeaderboardEntry {
  final int rank;
  final int studId;
  final String nickname;
  final String fullName;
  final String gradelvl;
  final double totalScore;
  final int sessions;

  const LeaderboardEntry({
    required this.rank,
    required this.studId,
    required this.nickname,
    required this.fullName,
    required this.gradelvl,
    required this.totalScore,
    required this.sessions,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final computedName = '$firstName $lastName'.trim();

    return LeaderboardEntry(
      rank: _readInt(json['rank']) ?? 0,
      studId: parseStudentId(json['stud_id'] ?? json['student_id']) ?? 0,
      nickname: json['nickname'] as String? ?? '',
      fullName:
          json['full_name'] as String? ??
          (computedName.isEmpty ? 'Unknown Student' : computedName),
      gradelvl: _normalizeGradeLevelLabel(json['gradelvl']),
      totalScore:
          _readDouble(json['total_score']) ??
          _readDouble(json['totalScore']) ??
          0.0,
      sessions:
          _readInt(json['sessions']) ?? _readInt(json['total_sessions']) ?? 0,
    );
  }
}

class ReportsSnapshot {
  final DashboardData dashboard;
  final List<Student> students;
  final List<LeaderboardEntry> leaderboard;

  const ReportsSnapshot({
    required this.dashboard,
    required this.students,
    required this.leaderboard,
  });
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

String _normalizeGradeLevelLabel(Object? value) {
  final label = (value as String?)?.trim() ?? '';
  final lower = label.toLowerCase();
  if (lower.contains('punla')) {
    return 'Punla (4-5)';
  }
  if (lower.contains('binhi')) {
    return 'Binhi (6-7)';
  }
  if (lower.isEmpty || lower == 'unknown') {
    return 'Binhi (6-7)';
  }
  return label;
}
