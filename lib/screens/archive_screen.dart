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
      await ref.read(adminUsersProvider.notifier).load();
      await ref.read(studentsProvider.future);
      ref.invalidate(questionsProvider);
      ref.invalidate(allQuestionsProvider);
      await _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored ${event.entityLabel} ${event.entityId}.'),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final payload = error.response?.data;
      final message = payload is Map && payload['message'] is String
          ? payload['message'] as String
          : 'Failed to restore item from archive.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  List<_ArchiveEventRow> get _currentlyArchived {
    final latestByEntity = <String, _ArchiveEventRow>{};
    for (final event in _events) {
      final key = event.entityKey;
      if (!latestByEntity.containsKey(key)) {
        latestByEntity[key] = event;
      }
    }

    return latestByEntity.values
        .where((event) => event.action.trim().toLowerCase() == 'archive')
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final currentArchives = _currentlyArchived;
    final sections = <_ArchiveSection>[
      _ArchiveSection(
        title: 'Archived Superadmins',
        emptyText: 'No archived superadmins.',
        events: currentArchives
            .where((event) => event.entityType == 'superadmin_account')
            .toList(growable: false),
      ),
      _ArchiveSection(
        title: 'Archived Teachers',
        emptyText: 'No archived teachers.',
        events: currentArchives
            .where((event) => event.entityType == 'teacher_account')
            .toList(growable: false),
      ),
      _ArchiveSection(
        title: 'Archived Students',
        emptyText: 'No archived students.',
        events: currentArchives
            .where((event) => event.entityType == 'student')
            .toList(growable: false),
      ),
      _ArchiveSection(
        title: 'Archived Questions',
        emptyText: 'No archived questions.',
        events: currentArchives
            .where((event) => event.entityType == 'question')
            .toList(growable: false),
      ),
      _ArchiveSection(
        title: 'Other Archived Accounts',
        emptyText: 'No other archived accounts.',
        events: currentArchives
            .where((event) => event.entityType == 'admin_account')
            .toList(growable: false),
      ),
    ].where((section) {
      if (_entityType == 'all') return true;
      return section.events.isNotEmpty;
    }).toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlarePageHeader(
              title: 'Archive',
              subtitle:
                  'Superadmin-only restore console for currently archived records.',
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
                          value: 'superadmin_account',
                          child: Text('Superadmin'),
                        ),
                        DropdownMenuItem(
                          value: 'teacher_account',
                          child: Text('Teacher'),
                        ),
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
                          child: Text('Other Admin'),
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
                    : currentArchives.isEmpty
                    ? const Center(child: Text('No archived records found.'))
                    : ListView(
                        children: [
                          for (final section in sections)
                            _ArchiveSectionView(
                              section: section,
                              restoring: _restoring,
                              onRestore: _restore,
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveSection {
  final String title;
  final String emptyText;
  final List<_ArchiveEventRow> events;

  const _ArchiveSection({
    required this.title,
    required this.emptyText,
    required this.events,
  });
}

class _ArchiveSectionView extends StatelessWidget {
  final _ArchiveSection section;
  final bool restoring;
  final ValueChanged<_ArchiveEventRow> onRestore;

  const _ArchiveSectionView({
    required this.section,
    required this.restoring,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              '${section.title} (${section.events.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (section.events.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: Text(section.emptyText),
            )
          else
            ...section.events.map(
              (event) => Column(
                children: [
                  ListTile(
                    title: Text(
                      event.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(event.displaySubtitle),
                    trailing: FilledButton.tonal(
                      onPressed: restoring ? null : () => onRestore(event),
                      child: const Text('Restore'),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ArchiveEventRow {
  final int archiveId;
  final String entityType;
  final String entityId;
  final String action;
  final Map<String, dynamic> payload;
  final String actorUsername;
  final String createdAtRaw;

  const _ArchiveEventRow({
    required this.archiveId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.actorUsername,
    required this.createdAtRaw,
  });

  String get entityKey => '${entityType.trim().toLowerCase()}:$entityId';

  String get entityLabel {
    switch (entityType.trim().toLowerCase()) {
      case 'student':
        return 'Student';
      case 'question':
        return 'Question';
      case 'teacher_account':
        return 'Teacher Account';
      case 'superadmin_account':
        return 'Superadmin Account';
      case 'admin_account':
        return 'Admin Account';
      default:
        return entityType;
    }
  }

  String get username {
    final value = _readPayloadText(['username', 'nickname']);
    return value.isNotEmpty ? value : entityId;
  }

  String get fullName {
    final stored = _readPayloadText(['full_name', 'name']);
    if (stored.isNotEmpty) return stored;

    final firstName = _readPayloadText(['first_name']);
    final middleInitial = _readPayloadText(['middle_initial']);
    final lastName = _readPayloadText(['last_name']);
    return [firstName, middleInitial, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String get displayTitle {
    final name = fullName;
    return name.isEmpty ? '$entityLabel $entityId' : name;
  }

  String get displaySubtitle {
    final parts = <String>[
      '$entityLabel ID: $entityId',
      if (username.isNotEmpty) 'Username: $username',
      'Archived by ${actorUsername.isEmpty ? 'unknown' : actorUsername}',
      createdAtRaw,
    ];
    return parts.join(' • ');
  }

  String _readPayloadText(List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  factory _ArchiveEventRow.fromJson(Map<dynamic, dynamic> json) {
    final map = json.map((key, value) => MapEntry('$key', value));
    final rawPayload = map['payload'];
    final payload = rawPayload is Map
        ? rawPayload.map((key, value) => MapEntry('$key', value))
        : <String, dynamic>{};
    return _ArchiveEventRow(
      archiveId: int.tryParse('${map['archive_id'] ?? 0}') ?? 0,
      entityType: '${map['entity_type'] ?? ''}'.trim().toLowerCase(),
      entityId: '${map['entity_id'] ?? ''}',
      action: '${map['action'] ?? ''}'.trim().toLowerCase(),
      payload: payload,
      actorUsername: '${map['actor_username'] ?? ''}',
      createdAtRaw: '${map['created_at'] ?? ''}',
    );
  }
}
