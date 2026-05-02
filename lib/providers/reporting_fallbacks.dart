import '../models/reporting.dart';
import '../models/student.dart';

List<LeaderboardEntry> buildLeaderboardFromStudents(List<Student> students) {
  final ranked = [...students]
    ..sort((a, b) {
      final scoreCompare = _estimatedTotalScore(
        b,
      ).compareTo(_estimatedTotalScore(a));
      if (scoreCompare != 0) return scoreCompare;
      return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
    });

  return ranked
      .asMap()
      .entries
      .map((entry) {
        final student = entry.value;
        return LeaderboardEntry(
          rank: entry.key + 1,
          studId: student.studId,
          nickname: student.nickname,
          fullName: student.fullName.trim().isEmpty
              ? student.nickname
              : student.fullName.trim(),
          gradelvl: student.gradelvl,
          totalScore: _estimatedTotalScore(student),
          sessions: student.totalSessions,
        );
      })
      .toList(growable: false);
}

Student studentFromLeaderboard(LeaderboardEntry entry) {
  final nameParts = entry.fullName.trim().split(RegExp(r'\s+'));
  final firstName = nameParts.isNotEmpty ? nameParts.first : entry.nickname;
  final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
  final avgScore = entry.sessions <= 0
      ? 0.0
      : entry.totalScore / entry.sessions;

  return Student(
    studId: entry.studId,
    nickname: entry.nickname,
    firstName: firstName,
    lastName: lastName,
    area: '',
    birthday: '',
    age: 0,
    gradelvl: entry.gradelvl,
    sex: '',
    totalSessions: entry.sessions,
    avgScore: avgScore,
    proficiency: proficiencyForAverage(avgScore),
  );
}

String proficiencyForAverage(double avgScore) {
  if (avgScore >= 9.0) return 'Excelling';
  if (avgScore >= 7.0) return 'On track';
  if (avgScore >= 5.0) return 'Needs support';
  return 'Needs significant support';
}

double _estimatedTotalScore(Student student) {
  if (student.totalSessions <= 0) {
    return student.avgScore;
  }
  return student.avgScore * student.totalSessions;
}
