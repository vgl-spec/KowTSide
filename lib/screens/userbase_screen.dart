import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/admin_user.dart';
import '../models/student.dart';
import '../providers/admin_users_provider.dart';
import '../providers/areas_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/students_provider.dart';
import '../widgets/flareline_components.dart';

class UserbaseScreen extends ConsumerWidget {
  const UserbaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminUsersProvider);
    final studentsAsync = ref.watch(studentsProvider);

    if (adminAsync.isLoading || studentsAsync.isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (adminAsync.hasError) {
      return SafeArea(
        child: Center(
          child: Text('Failed to load admin users: ${adminAsync.error}'),
        ),
      );
    }
    if (studentsAsync.hasError) {
      return SafeArea(
        child: Center(
          child: Text('Failed to load students: ${studentsAsync.error}'),
        ),
      );
    }

    final admins = adminAsync.value ?? const <AdminUser>[];
    final students = studentsAsync.value ?? const <Student>[];
    final entries = <_UserbaseEntry>[
      ...admins.map(_UserbaseEntry.admin),
      ...students.map(_UserbaseEntry.student),
    ].where((entry) => entry.kind != '__hidden__').toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: _UserbaseBody(entries: entries),
      ),
    );
  }
}

class _UserbaseBody extends ConsumerStatefulWidget {
  final List<_UserbaseEntry> entries;
  const _UserbaseBody({required this.entries});

  @override
  ConsumerState<_UserbaseBody> createState() => _UserbaseBodyState();
}

class _UserbaseBodyState extends ConsumerState<_UserbaseBody> {
  String _query = '';
  String _type = 'All';
  int _page = 1;
  static const int _rowsPerPage = 100;
  DateTime? _lastRefreshAt;
  bool _isEditDialogOpen = false;
  bool _isEditDialogFetching = false;
  final Set<String> _selectedEntryKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final canArchiveAccounts = ref.watch(authProvider).isSuperadmin;
    final filtered = widget.entries.where((entry) {
      final needle = _query.trim().toLowerCase();
      final matchesQuery =
          needle.isEmpty ||
          entry.displayName.toLowerCase().contains(needle) ||
          entry.username.toLowerCase().contains(needle);
      final matchesType = _type == 'All' || entry.kind == _type;
      return matchesQuery && matchesType;
    }).toList();

    final totalRows = filtered.length;
    final totalPages = totalRows == 0
        ? 1
        : ((totalRows + _rowsPerPage - 1) ~/ _rowsPerPage);
    if (_page > totalPages) {
      _page = totalPages;
    }
    if (_page < 1) {
      _page = 1;
    }
    final startIndex = totalRows == 0 ? 0 : (_page - 1) * _rowsPerPage;
    final endIndex = totalRows == 0
        ? 0
        : ((startIndex + _rowsPerPage) > totalRows
              ? totalRows
              : (startIndex + _rowsPerPage));
    final pageRows = totalRows == 0
        ? const <_UserbaseEntry>[]
        : filtered.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlarePageHeader(
          title: 'Userbase',
          subtitle: 'Manage superadmin, teacher, and student accounts.',
          actions: [
            if (_selectedEntryKeys.isNotEmpty && canArchiveAccounts)
              FilledButton.tonalIcon(
                onPressed: _batchArchiveSelected,
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: Text('Archive Selected (${_selectedEntryKeys.length})'),
              ),
            FilledButton.icon(
              onPressed: () => _showTeacherDialog(context, ref),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Register Account'),
            ),
            FilledButton.tonalIcon(
              onPressed: _handleRefresh,
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
                    hintText: 'Search user or username...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() {
                    _query = value;
                    _page = 1;
                    _selectedEntryKeys.clear();
                  }),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const ['All', 'Superadmin', 'Teacher', 'Student']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                        _page = 1;
                        _selectedEntryKeys.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FlareSurfaceCard(
                child: pageRows.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Username')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: pageRows.map((entry) {
                                final rowKey = _entryKey(entry);
                                final isSelected = _selectedEntryKeys.contains(
                                  rowKey,
                                );
                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedEntryKeys.add(rowKey);
                                      } else {
                                        _selectedEntryKeys.remove(rowKey);
                                      }
                                    });
                                  },
                                  cells: [
                                    DataCell(Text(entry.displayName)),
                                    DataCell(Text(entry.username)),
                                    DataCell(
                                      FlarePill(
                                        label: entry.kind,
                                        color: _kindColor(entry.kind),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed:
                                                (_isEditDialogOpen ||
                                                    _isEditDialogFetching)
                                                ? null
                                                : () => _openEditDialogForEntry(
                                                    context,
                                                    entry,
                                                  ),
                                          ),
                                          if (entry.admin != null)
                                            IconButton(
                                              tooltip: 'Reset password',
                                              icon: const Icon(
                                                Icons.lock_reset,
                                              ),
                                              onPressed: () => showDialog<void>(
                                                context: context,
                                                builder: (_) =>
                                                    _ResetPasswordDialog(
                                                      user: entry.admin!,
                                                    ),
                                              ),
                                            ),
                                          if (entry.admin != null &&
                                              canArchiveAccounts)
                                            IconButton(
                                              tooltip: 'Archive account',
                                              icon: const Icon(
                                                Icons.archive_outlined,
                                              ),
                                              onPressed: entry.admin!.isActive
                                                  ? () => _archiveTeacher(
                                                      entry.admin!,
                                                    )
                                                  : null,
                                            ),
                                          if (entry.student != null &&
                                              canArchiveAccounts)
                                            IconButton(
                                              tooltip: 'Archive learner',
                                              icon: const Icon(
                                                Icons.archive_outlined,
                                              ),
                                              onPressed: () => _archiveStudent(
                                                entry.student!,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Showing ${totalRows == 0 ? 0 : startIndex + 1}-$endIndex of $totalRows',
            ),
            OutlinedButton(
              onPressed: _page > 1 ? () => setState(() => _page -= 1) : null,
              child: const Text('Previous'),
            ),
            Text('Page $_page of $totalPages'),
            OutlinedButton(
              onPressed: _page < totalPages
                  ? () => setState(() => _page += 1)
                  : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showStudentDialog(BuildContext context, Student student) async {
    final areaOptions = await _loadAreaOptions();
    var profileBirthday = student.birthday;
    var profileSex = student.sex;

    final firstName = TextEditingController(text: student.firstName);
    final lastName = TextEditingController(text: student.lastName);
    final nickname = TextEditingController(text: student.nickname);
    final birthday = TextEditingController(text: profileBirthday);
    final area = TextEditingController(text: student.area.trim());
    int? selectedAreaId = student.areaId;
    if (selectedAreaId == null && areaOptions.isNotEmpty) {
      final match = areaOptions
          .where(
            (entry) =>
                entry.areaName.toLowerCase() == area.text.trim().toLowerCase(),
          )
          .cast<AreaOption?>()
          .firstWhere((entry) => entry != null, orElse: () => null);
      selectedAreaId = match?.areaId ?? areaOptions.first.areaId;
      if (area.text.trim().isEmpty) {
        area.text = match?.areaName ?? areaOptions.first.areaName;
      }
    }
    String sex = profileSex == 'Female' ? 'Female' : 'Male';
    final formKey = GlobalKey<FormState>();
    final initialSnapshot =
        '${firstName.text}|${lastName.text}|${nickname.text}|${birthday.text}|${area.text}|$sex';

    Future<bool> confirmDiscardIfDirty(BuildContext dialogContext) async {
      final currentSnapshot =
          '${firstName.text}|${lastName.text}|${nickname.text}|${birthday.text}|${area.text}|$sex';
      if (currentSnapshot == initialSnapshot) {
        return true;
      }
      final discard = await showDialog<bool>(
        context: dialogContext,
        builder: (confirmContext) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Do you want to close without saving?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext, false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(confirmContext, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return discard == true;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final canClose = await confirmDiscardIfDirty(dialogContext);
          if (canClose && dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        },
        child: AlertDialog(
          title: const Text('Edit Student'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: 'First name'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nickname,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: birthday,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Birthday',
                      suffixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final initial =
                          DateTime.tryParse(birthday.text.trim()) ??
                          DateTime(now.year - 6, now.month, now.day);
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: initial,
                        firstDate: DateTime(1990, 1, 1),
                        lastDate: now,
                      );
                      if (picked != null) {
                        final month = picked.month.toString().padLeft(2, '0');
                        final day = picked.day.toString().padLeft(2, '0');
                        birthday.text = '${picked.year}-$month-$day';
                      }
                    },
                    validator: (value) {
                      final bday = (value ?? '').trim();
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(bday)) {
                        return 'Birthday must be YYYY-MM-DD.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (areaOptions.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: selectedAreaId,
                      decoration: const InputDecoration(labelText: 'Area'),
                      items: areaOptions
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.areaId,
                              child: Text(entry.areaName),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        selectedAreaId = value;
                        if (value == null) return;
                        final selected = areaOptions.firstWhere(
                          (entry) => entry.areaId == value,
                        );
                        area.text = selected.areaName;
                      },
                      validator: (value) {
                        if (value == null) return 'Please select area.';
                        return null;
                      },
                    )
                  else
                    TextFormField(
                      controller: area,
                      decoration: const InputDecoration(labelText: 'Area'),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty ||
                            v.toLowerCase() == 'unspecified area') {
                          return 'Please specify area.';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: sex,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      if (value != null) sex = value;
                    },
                    decoration: const InputDecoration(labelText: 'Sex'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final canClose = await confirmDiscardIfDirty(dialogContext);
                if (canClose && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                try {
                  await _updateStudentProfile(
                    studentId: student.studId,
                    firstName: firstName.text.trim(),
                    lastName: lastName.text.trim(),
                    username: nickname.text.trim(),
                    birthday: birthday.text.trim(),
                    sex: sex,
                    area: area.text.trim(),
                    areaId: selectedAreaId,
                  );
                  if (!mounted) return;
                  ref.invalidate(studentsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student profile updated.')),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (error) {
                  if (!mounted) return;
                  final message = _extractApiErrorMessage(
                    error,
                    fallback: 'Failed to update student profile.',
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialogForEntry(
    BuildContext context,
    _UserbaseEntry entry,
  ) async {
    if (_isEditDialogOpen || _isEditDialogFetching) return;
    setState(() => _isEditDialogFetching = true);
    try {
      _isEditDialogOpen = true;
      if (entry.admin != null) {
        await _showTeacherDialog(context, ref, existing: entry.admin);
      } else if (entry.student != null) {
        await _showStudentDialog(context, entry.student!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEditDialogFetching = false;
          _isEditDialogOpen = false;
        });
      } else {
        _isEditDialogFetching = false;
        _isEditDialogOpen = false;
      }
    }
  }

  Future<void> _showTeacherDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminUser? existing,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TeacherFormDialog(existing: existing),
    );
  }

  Future<void> _archiveTeacher(
    AdminUser user, {
    bool askConfirmation = true,
    bool showFeedback = true,
  }) async {
    final auth = ref.read(authProvider);
    final isSelf = auth.adminId == user.adminId;
    if (isSelf) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot archive your own account.')),
      );
      return;
    }
    final isTargetSuperadmin = user.role.trim().toLowerCase() == 'superadmin';
    if (isTargetSuperadmin) {
      final admins = ref.read(adminUsersProvider).value ?? const <AdminUser>[];
      final activeSuperadmins = admins
          .where(
            (entry) =>
                entry.role.trim().toLowerCase() == 'superadmin' &&
                entry.isActive,
          )
          .length;
      if (activeSuperadmins <= 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot archive the last active superadmin.'),
          ),
        );
        return;
      }
    }

    final confirmed = askConfirmation
        ? await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Archive Account'),
              content: Text(
                'Archive ${user.username}? This will disable account access.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Archive'),
                ),
              ],
            ),
          )
        : true;
    if (confirmed != true) return;

    await ref.read(adminUsersProvider.notifier).setActive(user, false);
    if (!mounted || !showFeedback) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Archived ${user.username}')));
  }

  Future<void> _archiveStudent(
    Student student, {
    bool askConfirmation = true,
    bool showFeedback = true,
  }) async {
    final confirmed = askConfirmation
        ? await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Archive Learner'),
              content: Text(
                'Archive ${student.fullName} (${student.displayStudId})?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.error,
                  ),
                  child: const Text('Archive'),
                ),
              ],
            ),
          )
        : true;
    if (confirmed != true) return;

    await dio.delete('${ApiConstants.baseUrl}/api/users/${student.studId}');
    if (!mounted) return;
    ref.invalidate(studentsProvider);
    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archived ${student.displayStudId}')),
      );
    }
  }

  void _handleRefresh() {
    final now = DateTime.now();
    final shouldPrompt =
        _lastRefreshAt == null ||
        now.difference(_lastRefreshAt!).inSeconds >= 2;
    _lastRefreshAt = now;
    ref.read(adminUsersProvider.notifier).load();
    ref.invalidate(studentsProvider);
    setState(() => _selectedEntryKeys.clear());
    if (shouldPrompt) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are UpToDate')));
    }
  }

  String _entryKey(_UserbaseEntry entry) {
    if (entry.admin != null) {
      return 'admin:${entry.admin!.adminId}';
    }
    if (entry.student != null) {
      return 'student:${entry.student!.studId}';
    }
    return 'unknown:${entry.username}';
  }

  Future<void> _batchArchiveSelected() async {
    if (_selectedEntryKeys.isEmpty) return;
    final selectedEntries = widget.entries
        .where((entry) => _selectedEntryKeys.contains(_entryKey(entry)))
        .toList(growable: false);
    if (selectedEntries.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive Selected Accounts'),
        content: Text(
          'Archive ${selectedEntries.length} selected account(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    var successCount = 0;
    final failures = <String>[];
    for (final entry in selectedEntries) {
      try {
        if (entry.admin != null) {
          await _archiveTeacher(
            entry.admin!,
            askConfirmation: false,
            showFeedback: false,
          );
        } else if (entry.student != null) {
          await _archiveStudent(
            entry.student!,
            askConfirmation: false,
            showFeedback: false,
          );
        }
        successCount += 1;
      } catch (_) {
        failures.add(entry.username);
      }
    }

    if (!mounted) return;
    setState(() => _selectedEntryKeys.clear());
    final message = failures.isEmpty
        ? 'Archived $successCount account(s).'
        : 'Archived $successCount account(s), failed: ${failures.join(', ')}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<List<AreaOption>> _loadAreaOptions() async {
    try {
      final options = await ref.read(areaOptionsProvider.future);
      if (options.isNotEmpty) {
        return options;
      }
    } catch (_) {}

    final students = ref.read(studentsProvider).value ?? const <Student>[];
    final names =
        students
            .map((entry) => entry.area.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [
      for (var index = 0; index < names.length; index++)
        AreaOption(areaId: index + 1, areaName: names[index]),
    ];
  }
}

Future<void> _updateStudentProfile({
  required int studentId,
  required String firstName,
  required String lastName,
  required String username,
  required String birthday,
  required String sex,
  required String area,
  int? areaId,
}) async {
  final sexId = sex == 'Female' ? 2 : 1;
  final endpoint = '${ApiConstants.baseUrl}/api/users/$studentId/profile';
  final payloadSnake = <String, dynamic>{
    'first_name': firstName,
    'last_name': lastName,
    'username': username,
    'nickname': username,
    'birthday': birthday,
    'sex_id': sexId,
    'barangay_id': 1,
    'area': area,
    'area_name': area,
    if (areaId != null) 'area_id': areaId,
  };
  final payloadCamel = <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'birthday': birthday,
    'sexId': sexId,
    'barangayId': 1,
    'area': area,
    'areaName': area,
    if (areaId != null) 'areaId': areaId,
  };

  try {
    await dio.put(endpoint, data: payloadSnake);
    return;
  } on DioException catch (error) {
    final code = error.response?.statusCode ?? 0;
    if (code != 404 && code != 405 && code != 500) rethrow;
  }

  await dio.put(endpoint, data: payloadCamel);
}

class _UserbaseEntry {
  final String kind;
  final String displayName;
  final String username;
  final AdminUser? admin;
  final Student? student;

  const _UserbaseEntry._({
    required this.kind,
    required this.displayName,
    required this.username,
    this.admin,
    this.student,
  });

  factory _UserbaseEntry.admin(AdminUser user) {
    final role = user.role.toLowerCase();
    if (role != 'teacher' && role != 'superadmin') {
      return const _UserbaseEntry._(
        kind: '__hidden__',
        displayName: '',
        username: '',
      );
    }
    return _UserbaseEntry._(
      kind: role == 'superadmin' ? 'Superadmin' : 'Teacher',
      displayName: user.fullName.isEmpty ? user.username : user.fullName,
      username: user.username,
      admin: user,
    );
  }

  factory _UserbaseEntry.student(Student student) {
    return _UserbaseEntry._(
      kind: 'Student',
      displayName: student.fullName,
      username: student.nickname,
      student: student,
    );
  }
}

Color _kindColor(String kind) {
  switch (kind) {
    case 'Superadmin':
      return AppTheme.tertiary;
    case 'Teacher':
      return AppTheme.primary;
    case 'Admin':
      return AppTheme.tertiary;
    default:
      return AppTheme.success;
  }
}

class _TeacherFormDialog extends ConsumerStatefulWidget {
  final AdminUser? existing;
  const _TeacherFormDialog({this.existing});

  @override
  ConsumerState<_TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<_TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _firstName;
  late final TextEditingController _middleInitial;
  late final TextEditingController _lastName;
  late final TextEditingController _nickname;
  late final TextEditingController _birthday;
  bool _saving = false;
  late String _role;
  String _sex = 'Male';

  @override
  void initState() {
    super.initState();
    final user = widget.existing;
    _username = TextEditingController(text: user?.username ?? '');
    _password = TextEditingController();
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _middleInitial = TextEditingController(text: user?.middleInitial ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _nickname = TextEditingController();
    _birthday = TextEditingController();
    _role = (user?.role.trim().toLowerCase() ?? 'teacher') == 'superadmin'
        ? 'superadmin'
        : 'teacher';
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _firstName.dispose();
    _middleInitial.dispose();
    _lastName.dispose();
    _nickname.dispose();
    _birthday.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final canManageSuperadmin = ref.read(authProvider).isSuperadmin;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Account' : 'Register Account'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_role == 'teacher') ...[
                TextFormField(
                  controller: _username,
                  readOnly: isEdit,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    helperText: isEdit
                        ? 'Username edits are disabled for existing accounts.'
                        : null,
                  ),
                  validator: (value) {
                    return value == null || value.trim().length < 3
                        ? 'Use at least 3 characters.'
                        : null;
                  },
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.length < 12
                        ? 'Use at least 12 characters.'
                        : null,
                  ),
                ],
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Account role'),
                items: isEdit
                    ? <DropdownMenuItem<String>>[
                        if (_role == 'superadmin' && canManageSuperadmin)
                          const DropdownMenuItem(
                            value: 'superadmin',
                            child: Text('Superadmin'),
                          ),
                        const DropdownMenuItem(
                          value: 'teacher',
                          child: Text('Teacher'),
                        ),
                      ]
                    : <DropdownMenuItem<String>>[
                        if (canManageSuperadmin)
                          const DropdownMenuItem(
                            value: 'superadmin',
                            child: Text('Superadmin'),
                          ),
                        const DropdownMenuItem(
                          value: 'teacher',
                          child: Text('Teacher'),
                        ),
                        const DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                      ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _role = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              if (_role == 'teacher') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _middleInitial,
                  decoration: const InputDecoration(
                    labelText: 'Middle initial',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              if (!isEdit && _role == 'student') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nickname,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Username is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthday,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Birthday',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final initial =
                        DateTime.tryParse(_birthday.text.trim()) ??
                        DateTime(now.year - 6, now.month, now.day);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(1990, 1, 1),
                      lastDate: now,
                    );
                    if (picked != null) {
                      final month = picked.month.toString().padLeft(2, '0');
                      final day = picked.day.toString().padLeft(2, '0');
                      _birthday.text = '${picked.year}-$month-$day';
                    }
                  },
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
                      return 'Birthday must be YYYY-MM-DD.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sex = value);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(isEdit ? 'Save Changes' : 'Create Account'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(adminUsersProvider.notifier);
    final existing = widget.existing;
    try {
      if (existing == null) {
        if (_role == 'student') {
          await dio.post(
            '${ApiConstants.baseUrl}/api/users',
            data: {
              'first_name': _firstName.text.trim(),
              'last_name': _lastName.text.trim(),
              'nickname': _nickname.text.trim(),
              'birthday': _birthday.text.trim(),
              'sex': _sex,
            },
          );
          ref.invalidate(studentsProvider);
        } else {
          await notifier.registerAccount(
            username: _username.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            middleInitial: _middleInitial.text.trim(),
            lastName: _lastName.text.trim(),
            role: _role,
          );
        }
      } else {
        final safeFirst = _firstName.text.trim().isEmpty
            ? _username.text.trim()
            : _firstName.text.trim();
        final safeLast = _lastName.text.trim().isEmpty
            ? '-'
            : _lastName.text.trim();
        await notifier.updateTeacher(
          existing,
          username: _username.text.trim(),
          firstName: safeFirst,
          middleInitial: _middleInitial.text.trim(),
          lastName: safeLast,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      final message = _extractApiErrorMessage(
        error,
        fallback: 'Failed to save account changes.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  final AdminUser user;
  const _ResetPasswordDialog({required this.user});

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

String _extractApiErrorMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;
    if (payload is Map) {
      final mapped = payload.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final nestedError = mapped['error'];
      if (nestedError is Map) {
        final nestedMessage = nestedError['message']?.toString().trim() ?? '';
        if (nestedMessage.isNotEmpty) return nestedMessage;
      }
      final details = mapped['details'];
      if (details is List && details.isNotEmpty) {
        final joined = details
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .join(', ');
        if (joined.isNotEmpty) return joined;
      }
      final message = mapped['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) return message;
    } else if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }
    if (statusCode != null) {
      return '$fallback (HTTP $statusCode)';
    }
  }
  return fallback;
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (_controller.text.length < 12) return;
            await ref
                .read(adminUsersProvider.notifier)
                .resetPassword(widget.user, _controller.text);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}
