import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/activity_log.dart';
import '../providers/activity_logs_provider.dart';
import '../widgets/flareline_components.dart';

const _actionAliases = <String, String>{
  'LOGIN_SUCCESS': 'Log In',
  'LOGIN_FAILED': 'Log In Failed',
  'LOGOUT': 'Log Out',
  'MFA_SETUP': 'Set Up Verification',
  'MFA_VERIFY': 'Verify Sign-In',
  'TEACHER_CREATE': 'Register Teacher',
  'TEACHER_UPDATE': 'Update Teacher',
  'PASSWORD_RESET': 'Reset Password',
  'ACCOUNT_STATUS_CHANGE': 'Change Account Status',
  'QUESTION_CREATE': 'Add Question',
  'QUESTION_UPDATE': 'Update Question',
  'QUESTION_DELETE': 'Hide Question',
  'IMAGE_UPLOAD': 'Upload Image',
  'AI_IMPORT_GENERATE': 'Generate Import Preview',
  'AI_IMPORT_COMMIT': 'Save Imported Questions',
  'SYSTEM_HEALTH_VIEW': 'View System Health',
  'SYNC_LOG_VIEW': 'View Sync Logs',
  'DEVICE_VIEW': 'View Devices',
};

class ActivityLogsScreen extends ConsumerStatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  ConsumerState<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends ConsumerState<ActivityLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _status = 'All';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(activityLogsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlarePageHeader(
              title: 'Activity Logs',
              subtitle:
                  'A clear audit trail of sign-ins, question changes, uploads, imports, and account actions.',
              actions: [
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(activityLogsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FlareSurfaceCard(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 340,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search user, role, or activity...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const ['All', 'success', 'failed', 'pending']
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(_statusAlias(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                          _setFilter(status: value, page: 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed to load activity logs: $error')),
                data: (pageData) {
                  if (pageData.logs.isEmpty) {
                    return const FlareSurfaceCard(
                      child: Center(child: Text('No activity logs found.')),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(child: _ActivityLogTable(logs: pageData.logs)),
                      const SizedBox(height: 12),
                      _ActivityLogPagination(
                        page: pageData.page,
                        totalPages: pageData.totalPages,
                        totalRows: pageData.total,
                        rowsPerPage: pageData.limit,
                        onPageSelected: (page) => _setFilter(page: page),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _setFilter(actorQuery: value.trim(), page: 1);
    });
  }

  void _setFilter({int? page, String? actorQuery, String? status}) {
    final current = ref.read(activityLogFilterProvider);
    ref.read(activityLogFilterProvider.notifier).state = current.copyWith(
      page: page,
      actorQuery: actorQuery,
      status: status,
    );
  }
}

class _ActivityLogTable extends StatelessWidget {
  final List<ActivityLogEntry> logs;

  const _ActivityLogTable({required this.logs});

  @override
  Widget build(BuildContext context) {
    return FlareSurfaceCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;

          return Column(
            children: [
              if (!compact)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _ActivityLogHeaderRow(),
                ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, compact ? 16 : 0, 16, 16),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return compact
                        ? _ActivityLogCardCompact(log: log)
                        : _ActivityLogRow(log: log);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityLogHeaderRow extends StatelessWidget {
  const _ActivityLogHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Expanded(flex: 17, child: _HeaderLabel('Date')),
          SizedBox(width: 12),
          Expanded(flex: 15, child: _HeaderLabel('Time')),
          SizedBox(width: 12),
          Expanded(flex: 22, child: _HeaderLabel('User')),
          SizedBox(width: 12),
          Expanded(flex: 16, child: _HeaderLabel('Role')),
          SizedBox(width: 12),
          Expanded(flex: 24, child: _HeaderLabel('Activity')),
          SizedBox(width: 12),
          Expanded(flex: 14, child: _HeaderLabel('Status')),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;

  const _HeaderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800));
  }
}

class _ActivityLogRow extends StatelessWidget {
  final ActivityLogEntry log;

  const _ActivityLogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 17,
            child: Text(
              log.createdDate,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 15, child: Text(log.createdTime)),
          const SizedBox(width: 12),
          Expanded(
            flex: 22,
            child: Text(
              log.actorUsername.isEmpty ? 'Unknown user' : log.actorUsername,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 16, child: Text(_roleAlias(log.actorRole))),
          const SizedBox(width: 12),
          Expanded(flex: 24, child: _ActionChip(action: log.action)),
          const SizedBox(width: 12),
          Expanded(flex: 14, child: _StatusChip(status: log.status)),
        ],
      ),
    );
  }
}

class _ActivityLogCardCompact extends StatelessWidget {
  final ActivityLogEntry log;

  const _ActivityLogCardCompact({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  log.actorUsername.isEmpty
                      ? 'Unknown user'
                      : log.actorUsername,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(status: log.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              FlarePill(label: _roleAlias(log.actorRole), color: AppTheme.info),
              _ActionChip(action: log.action),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${log.createdDate} • ${log.createdTime}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ActivityLogPagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onPageSelected;

  const _ActivityLogPagination({
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages(page, totalPages);
    final startRow = totalRows == 0 ? 0 : ((page - 1) * rowsPerPage) + 1;
    final endRow = totalRows == 0
        ? 0
        : (page * rowsPerPage > totalRows ? totalRows : page * rowsPerPage);

    return FlareSurfaceCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$startRow-$endRow of $totalRows',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          OutlinedButton(
            onPressed: page > 1 ? () => onPageSelected(page - 1) : null,
            child: const Text('Previous'),
          ),
          ...pages.map(
            (item) => item == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('...'),
                  )
                : FilledButton.tonal(
                    onPressed: item == page ? null : () => onPageSelected(item),
                    child: Text('$item'),
                  ),
          ),
          OutlinedButton(
            onPressed: page < totalPages
                ? () => onPageSelected(page + 1)
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  List<int?> _visiblePages(int currentPage, int pageCount) {
    if (pageCount <= 7) {
      return List<int?>.generate(pageCount, (index) => index + 1);
    }

    final pages = <int?>[1];
    final start = currentPage <= 3 ? 2 : currentPage - 1;
    final end = currentPage >= pageCount - 2 ? pageCount - 1 : currentPage + 1;

    if (start > 2) {
      pages.add(null);
    }

    for (var value = start; value <= end; value++) {
      if (value > 1 && value < pageCount) {
        pages.add(value);
      }
    }

    if (end < pageCount - 1) {
      pages.add(null);
    }

    pages.add(pageCount);
    return pages;
  }
}

class _ActionChip extends StatelessWidget {
  final String action;

  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final normalized = action.trim().toUpperCase();
    final color = normalized.contains('LOGIN')
        ? AppTheme.primary
        : normalized.contains('FAILED')
        ? AppTheme.error
        : normalized.contains('IMPORT') || normalized.contains('QUESTION')
        ? AppTheme.tertiary
        : AppTheme.info;

    return FlarePill(label: _actionAlias(action), color: color);
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = normalized == 'failed'
        ? AppTheme.error
        : normalized == 'pending'
        ? AppTheme.warning
        : AppTheme.success;

    return FlarePill(label: _statusAlias(normalized), color: color);
  }
}

String _actionAlias(String action) {
  final normalized = action.trim().toUpperCase();
  return _actionAliases[normalized] ??
      normalized
          .toLowerCase()
          .split('_')
          .map(
            (part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' ');
}

String _roleAlias(String role) {
  switch (role.trim().toLowerCase()) {
    case 'superadmin':
      return 'Superadmin';
    case 'teacher':
      return 'Teacher';
    default:
      return role.trim().isEmpty ? 'Unknown' : role;
  }
}

String _statusAlias(String status) {
  switch (status.trim().toLowerCase()) {
    case 'success':
      return 'Success';
    case 'failed':
      return 'Failed';
    case 'pending':
      return 'Pending';
    default:
      return status;
  }
}
