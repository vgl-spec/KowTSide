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
    final createdRaw = _readString(
      json['created_at'],
      json['created_datetime'] ?? json['created_ts'],
    );
    final date = _readString(json['created_date']);
    final time = _readString(json['created_time']);
    return ActivityLogEntry(
      logId: _readInt(json['log_id']) ?? 0,
      actorUsername: json['actor_username'] as String? ?? '',
      actorRole: json['actor_role'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id']?.toString() ?? '',
      status: json['status'] as String? ?? 'success',
      createdDate: date.isNotEmpty ? date : _extractDatePart(createdRaw),
      createdTime: time.isNotEmpty ? time : _extractTimePart(createdRaw),
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

String _readString([Object? first, Object? second]) {
  String normalize(Object? value) => value?.toString().trim() ?? '';
  final a = normalize(first);
  if (a.isNotEmpty) return a;
  return normalize(second);
}

String _extractDatePart(String raw) {
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }
  final oracleDate = _parseOracleDate(raw);
  if (oracleDate != null) {
    final month = oracleDate.month.toString().padLeft(2, '0');
    final day = oracleDate.day.toString().padLeft(2, '0');
    return '${oracleDate.year}-$month-$day';
  }
  if (raw.contains('T')) return raw.split('T').first.trim();
  if (raw.contains(' ')) return raw.split(' ').first.trim();
  return raw;
}

String _extractTimePart(String raw) {
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final second = parsed.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
  final oracleDate = _parseOracleDate(raw);
  if (oracleDate != null) {
    final hour = oracleDate.hour.toString().padLeft(2, '0');
    final minute = oracleDate.minute.toString().padLeft(2, '0');
    final second = oracleDate.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
  final value = raw.contains('T') ? raw.split('T').last : raw.split(' ').last;
  final clean = value.trim();
  if (clean.isEmpty || clean == raw) return '';
  return clean.split('.').first.replaceAll('Z', '');
}

DateTime? _parseOracleDate(String value) {
  final match = RegExp(
    r'^(\d{1,2})-([A-Za-z]{3})-(\d{2})(?:\s+(\d{2}):(\d{2}):(\d{2}))?$',
  ).firstMatch(value.trim());
  if (match == null) return null;

  final day = int.tryParse(match.group(1) ?? '');
  final monthToken = (match.group(2) ?? '').toUpperCase();
  final yearTwo = int.tryParse(match.group(3) ?? '');
  if (day == null || yearTwo == null) return null;

  const monthMap = {
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };
  final month = monthMap[monthToken];
  if (month == null) return null;

  final year = yearTwo >= 70 ? 1900 + yearTwo : 2000 + yearTwo;
  final hour = int.tryParse(match.group(4) ?? '') ?? 0;
  final minute = int.tryParse(match.group(5) ?? '') ?? 0;
  final second = int.tryParse(match.group(6) ?? '') ?? 0;
  return DateTime(year, month, day, hour, minute, second);
}
