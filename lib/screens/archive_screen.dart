import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../providers/admin_users_provider.dart';
import '../providers/questions_provider.dart';
import '../providers/students_provider.dart';
import '../widgets/flareline_components.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  bool _loading = false;
  bool _restoring = false;
  String _query = '';
  String _entityType = 'all';
  List<_ArchiveEventRow> _events = const <_ArchiveEventRow>[];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final response = await dio.get(
        ApiConstants.archiveEvents,
        queryParameters: {
          'page': 1,
          'limit': 200,
          if (_query.trim().isNotEmpty) 'search': _query.trim(),
          if (_entityType != 'all') 'entity_type': _entityType,
        },
      );

      final rawList =
          (response.data['events'] as List?)?.cast<Map<dynamic, dynamic>>() ??
          const <Map<dynamic, dynamic>>[];
      final parsed = rawList
          .map((row) => _ArchiveEventRow.fromJson(row))
          .toList(growable: false);
      if (!mounted) return;
      setState(() => _events = parsed);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _restore(_ArchiveEventRow event) async {
    if (_restoring) return;
    setState(() => _restoring = true);
    try {
      await dio.post(
        ApiConstants.archiveRestore,
        data: {'archive_id': event.archiveId},
      );

      ref.invalidate(studentsProvider);
      ref.read(adminUsersProvider.notifier).load();
      ref.invalidate(questionsProvider);
      ref.invalidate(allQuestionsProvider);
      await _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restored ${event.entityType} ${event.entityId} from archive.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final payload = error.response?.data;
      final message = payload is Map && payload['message'] is String
          ? payload['message'] as String
          : 'Failed to restore item from archive.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlarePageHeader(
              title: 'Archive',
              subtitle: 'Superadmin-only restore console for archived users and questions.',
              actions: [
                FilledButton.tonalIcon(
                  onPressed: _loading ? null : _loadEvents,
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
                children: [
                  SizedBox(
                    width: 340,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search entity id, type, or actor...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _entityType,
                      decoration: const InputDecoration(labelText: 'Entity'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: 'question',
                          child: Text('Question'),
                        ),
                        DropdownMenuItem(
                          value: 'admin_account',
                          child: Text('Admin Account'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _entityType = value);
                        }
                      },
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _loadEvents,
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: const Text('Apply'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FlareSurfaceCard(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _events.isEmpty
                    ? const Center(child: Text('No archive events found.'))
                    : ListView.separated(
                        itemCount: _events.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final canRestore = event.action == 'archive';
                          return ListTile(
                            title: Text(
                              '${event.entityType} • ${event.entityId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'Action: ${event.action} • By: ${event.actorUsername.isEmpty ? 'unknown' : event.actorUsername} • ${event.createdAtRaw}',
                            ),
                            trailing: FilledButton.tonal(
                              onPressed: canRestore && !_restoring
                                  ? () => _restore(event)
                                  : null,
                              child: const Text('Restore'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveEventRow {
  final int archiveId;
  final String entityType;
  final String entityId;
  final String action;
  final String actorUsername;
  final String createdAtRaw;

  const _ArchiveEventRow({
    required this.archiveId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.actorUsername,
    required this.createdAtRaw,
  });

  factory _ArchiveEventRow.fromJson(Map<dynamic, dynamic> json) {
    final map = json.map((key, value) => MapEntry('$key', value));
    return _ArchiveEventRow(
      archiveId: int.tryParse('${map['archive_id'] ?? 0}') ?? 0,
      entityType: '${map['entity_type'] ?? ''}',
      entityId: '${map['entity_id'] ?? ''}',
      action: '${map['action'] ?? ''}',
      actorUsername: '${map['actor_username'] ?? ''}',
      createdAtRaw: '${map['created_at'] ?? ''}',
    );
  }
}
