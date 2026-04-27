class ActivityLogEntry {
  final int logId;
  final String actorUsername;
  final String actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final String status;
  final String createdDate;
  final String createdTime;
  final String summary;

  const ActivityLogEntry({
    required this.logId,
    required this.actorUsername,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.status,
    required this.createdDate,
    required this.createdTime,
    required this.summary,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      logId: _readInt(json['log_id']) ?? 0,
      actorUsername: json['actor_username'] as String? ?? '',
      actorRole: json['actor_role'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id']?.toString() ?? '',
      status: json['status'] as String? ?? 'success',
      createdDate: json['created_date'] as String? ?? '',
      createdTime: json['created_time'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}

class ActivityLogPage {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<ActivityLogEntry> logs;

  const ActivityLogPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.logs,
  });

  factory ActivityLogPage.fromJson(Map<String, dynamic> json) {
    final list = json['logs'] as List? ?? const <dynamic>[];
    final total = _readInt(json['total']) ?? list.length;
    final limit = _readInt(json['limit']) ?? 100;
    final totalPages =
        _readInt(json['total_pages']) ??
        (total == 0 ? 1 : ((total + limit - 1) ~/ limit));

    return ActivityLogPage(
      page: _readInt(json['page']) ?? 1,
      limit: limit,
      total: total,
      totalPages: totalPages < 1 ? 1 : totalPages,
      logs: list
          .map(
            (item) => ActivityLogEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
