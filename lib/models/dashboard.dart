class DashboardData {
  final int totalStudents;
  final int totalSessions;
  final int activeDevices;
  final List<AgeGroupProgress> ageGroupProgress;
  final List<RecentSync> recentSyncs;

  const DashboardData({
    required this.totalStudents,
    required this.totalSessions,
    required this.activeDevices,
    required this.ageGroupProgress,
    required this.recentSyncs,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        totalStudents: j['total_students'] as int? ?? 0,
        totalSessions: j['total_sessions'] as int? ?? 0,
        activeDevices: j['active_devices'] as int? ?? 0,
        ageGroupProgress: (j['age_group_progress'] as List? ?? [])
            .map((e) => AgeGroupProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentSyncs: (j['recent_syncs'] as List? ?? [])
            .map((e) => RecentSync.fromJson(e as Map<String, dynamic>))
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
        gradelvl: j['gradelvl'] as String? ?? '',
        subject: j['subject'] as String? ?? '',
        activeStudents: j['active_students'] as int? ?? 0,
        avgScore: (j['avg_score'] as num?)?.toDouble() ?? 0.0,
        passRatePct: (j['pass_rate_pct'] as num?)?.toDouble() ?? 0.0,
      );
}

class RecentSync {
  final String deviceUuid;
  final String deviceName;
  final String lastSyncedAt;
  final int studentsSynced;

  const RecentSync({
    required this.deviceUuid,
    required this.deviceName,
    required this.lastSyncedAt,
    required this.studentsSynced,
  });

  factory RecentSync.fromJson(Map<String, dynamic> j) => RecentSync(
        deviceUuid: j['device_uuid'] as String? ?? '',
        deviceName: j['device_name'] as String? ?? 'Unknown Device',
        lastSyncedAt: j['last_synced_at'] as String? ?? '',
        studentsSynced: j['students_synced'] as int? ?? 0,
      );
}
