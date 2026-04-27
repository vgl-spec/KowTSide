import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/activity_log.dart';

class ActivityLogFilter {
  final int page;
  final int limit;
  final String actorQuery;
  final String status;

  const ActivityLogFilter({
    this.page = 1,
    this.limit = 100,
    this.actorQuery = '',
    this.status = 'All',
  });

  ActivityLogFilter copyWith({
    int? page,
    int? limit,
    String? actorQuery,
    String? status,
  }) {
    return ActivityLogFilter(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      actorQuery: actorQuery ?? this.actorQuery,
      status: status ?? this.status,
    );
  }
}

final activityLogFilterProvider = StateProvider<ActivityLogFilter>(
  (ref) => const ActivityLogFilter(),
);

final activityLogsProvider = FutureProvider<ActivityLogPage>((ref) async {
  final filter = ref.watch(activityLogFilterProvider);

  if (ApiConstants.frontendOnly) {
    return _buildDemoPage(filter);
  }

  final response = await dio.get(
    ApiConstants.activityLogs,
    queryParameters: {
      'page': filter.page,
      'limit': filter.limit,
      if (filter.actorQuery.trim().isNotEmpty)
        'actor': filter.actorQuery.trim(),
      if (filter.status != 'All') 'status': filter.status,
    },
  );
  return ActivityLogPage.fromJson(response.data as Map<String, dynamic>);
});

ActivityLogPage _buildDemoPage(ActivityLogFilter filter) {
  final filtered = _demoLogs.where((log) {
    final matchesStatus = filter.status == 'All' || log.status == filter.status;
    final actorNeedle = filter.actorQuery.trim().toLowerCase();
    final matchesActor = actorNeedle.isEmpty
        ? true
        : [
            log.actorUsername,
            log.actorRole,
            log.action,
          ].join(' ').toLowerCase().contains(actorNeedle);
    return matchesStatus && matchesActor;
  }).toList();

  final total = filtered.length;
  final totalPages = total == 0
      ? 1
      : ((total + filter.limit - 1) ~/ filter.limit);
  final safePage = filter.page > totalPages ? totalPages : filter.page;
  final start = (safePage - 1) * filter.limit;
  final pageItems = filtered.skip(start).take(filter.limit).toList();

  return ActivityLogPage(
    page: safePage,
    limit: filter.limit,
    total: total,
    totalPages: totalPages,
    logs: pageItems,
  );
}

const _demoLogs = <ActivityLogEntry>[
  ActivityLogEntry(
    logId: 8108,
    actorUsername: 'kow_admin',
    actorRole: 'superadmin',
    action: 'TEACHER_CREATE',
    targetType: 'adminTb',
    targetId: '12',
    status: 'success',
    createdDate: '2026-04-26',
    createdTime: '09:42 AM',
    summary: 'Registered teacher account for Ms. Liza Cruz.',
  ),
  ActivityLogEntry(
    logId: 8107,
    actorUsername: 'teacher_mary',
    actorRole: 'teacher',
    action: 'AI_IMPORT_GENERATE',
    targetType: 'questionTb',
    targetId: 'preview',
    status: 'success',
    createdDate: '2026-04-26',
    createdTime: '09:28 AM',
    summary: 'Generated 8 draft questions from a DOCX lesson handout.',
  ),
  ActivityLogEntry(
    logId: 8106,
    actorUsername: 'teacher_mary',
    actorRole: 'teacher',
    action: 'QUESTION_UPDATE',
    targetType: 'questionTb',
    targetId: '2005',
    status: 'success',
    createdDate: '2026-04-26',
    createdTime: '09:13 AM',
    summary: 'Updated fun fact and answer options for a Science item.',
  ),
  ActivityLogEntry(
    logId: 8105,
    actorUsername: 'kow_admin',
    actorRole: 'superadmin',
    action: 'SYSTEM_HEALTH_VIEW',
    targetType: 'system',
    targetId: 'backend',
    status: 'success',
    createdDate: '2026-04-26',
    createdTime: '08:51 AM',
    summary: 'Viewed system health, Oracle pool, and runtime checks.',
  ),
  ActivityLogEntry(
    logId: 8104,
    actorUsername: 'teacher_mary',
    actorRole: 'teacher',
    action: 'LOGIN_SUCCESS',
    targetType: 'adminSessionTb',
    targetId: 'session',
    status: 'success',
    createdDate: '2026-04-26',
    createdTime: '08:30 AM',
    summary: 'Signed in using protected admin session.',
  ),
  ActivityLogEntry(
    logId: 8103,
    actorUsername: 'unknown',
    actorRole: '',
    action: 'LOGIN_FAILED',
    targetType: 'adminTb',
    targetId: 'teacher_mary',
    status: 'failed',
    createdDate: '2026-04-25',
    createdTime: '04:12 PM',
    summary: 'Rejected login attempt because of an incorrect password.',
  ),
];
