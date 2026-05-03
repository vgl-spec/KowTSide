import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/admin_user.dart';
import '../models/student.dart';
import '../providers/admin_users_provider.dart';
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
      return SafeArea(child: Center(child: Text('Failed to load admin users: ${adminAsync.error}')));
    }
    if (studentsAsync.hasError) {
      return SafeArea(child: Center(child: Text('Failed to load students: ${studentsAsync.error}')));
    }

    final admins = adminAsync.value ?? const <AdminUser>[];
    final students = studentsAsync.value ?? const <Student>[];
    final entries = <_UserbaseEntry>[
      ...admins.map(_UserbaseEntry.admin),
      ...students.map(_UserbaseEntry.student),
    ];

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

  @override
  Widget build(BuildContext context) {
    final filtered = widget.entries.where((entry) {
      final needle = _query.trim().toLowerCase();
      final matchesQuery = needle.isEmpty ||
          entry.displayName.toLowerCase().contains(needle) ||
          entry.username.toLowerCase().contains(needle);
      final matchesType = _type == 'All' || entry.kind == _type;
      return matchesQuery && matchesType;
    }).toList();

    final totalRows = filtered.length;
    final totalPages = totalRows == 0 ? 1 : ((totalRows + _rowsPerPage - 1) ~/ _rowsPerPage);
    if (_page > totalPages) {
      _page = totalPages;
    }
    final startIndex = totalRows == 0 ? 0 : (_page - 1) * _rowsPerPage;
    final endIndex = totalRows == 0
        ? 0
        : ((startIndex + _rowsPerPage) > totalRows ? totalRows : (startIndex + _rowsPerPage));
    final pageRows = totalRows == 0 ? const <_UserbaseEntry>[] : filtered.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlarePageHeader(
          title: 'Userbase',
          subtitle: 'Manage teachers, admins, and students in one place.',
          actions: [
            FilledButton.icon(
              onPressed: () => _showTeacherDialog(context, ref),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Register Teacher'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                ref.read(adminUsersProvider.notifier).load();
                ref.invalidate(studentsProvider);
              },
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
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const ['All', 'Teacher', 'Admin', 'Student']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                        _page = 1;
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
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Username/Nickname')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: pageRows.map((entry) {
                                return DataRow(cells: [
                                  DataCell(Text(entry.displayName)),
                                  DataCell(Text(entry.username)),
                                  DataCell(FlarePill(label: entry.kind, color: _kindColor(entry.kind))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => entry.admin != null
                                            ? _showTeacherDialog(context, ref, existing: entry.admin)
                                            : _showStudentDialog(context, entry.student!),
                                      ),
                                      if (entry.admin != null)
                                        IconButton(
                                          tooltip: 'Reset password',
                                          icon: const Icon(Icons.lock_reset),
                                          onPressed: () => showDialog<void>(
                                            context: context,
                                            builder: (_) => _ResetPasswordDialog(user: entry.admin!),
                                          ),
                                        ),
                                    ],
                                  )),
                                ]);
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
            Text('Showing ${totalRows == 0 ? 0 : startIndex + 1}-$endIndex of $totalRows'),
            OutlinedButton(
              onPressed: _page > 1
                  ? () => setState(() => _page -= 1)
                  : null,
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
    var profileBirthday = student.birthday;
    var profileSex = student.sex;
    try {
      final resp = await dio.get('${ApiConstants.baseUrl}/api/users/${student.studId}');
      final profile = (resp.data is Map<String, dynamic>)
          ? (resp.data['profile'] as Map<String, dynamic>? ?? const {})
          : const <String, dynamic>{};
      final bday = (profile['birthday'] as String?)?.trim() ?? '';
      if (bday.length >= 10) {
        profileBirthday = bday.substring(0, 10);
      }
      final sexId = profile['sex_id'];
      if (sexId == 2 || sexId == '2') {
        profileSex = 'Female';
      } else if (sexId == 1 || sexId == '1') {
        profileSex = 'Male';
      }
    } catch (_) {}

    final firstName = TextEditingController(text: student.firstName);
    final lastName = TextEditingController(text: student.lastName);
    final nickname = TextEditingController(text: student.nickname);
    final birthday = TextEditingController(text: profileBirthday);
    String sex = profileSex == 'Female' ? 'Female' : 'Male';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Student'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First name')),
              const SizedBox(height: 8),
              TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last name')),
              const SizedBox(height: 8),
              TextField(controller: nickname, decoration: const InputDecoration(labelText: 'Nickname')),
              const SizedBox(height: 8),
              TextField(controller: birthday, decoration: const InputDecoration(labelText: 'Birthday (YYYY-MM-DD)')),
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final bday = birthday.text.trim();
              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(bday)) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Birthday must be YYYY-MM-DD.')),
                );
                return;
              }
              await dio.put(
                '${ApiConstants.baseUrl}/api/users/${student.studId}/profile',
                data: {
                  'first_name': firstName.text.trim(),
                  'last_name': lastName.text.trim(),
                  'nickname': nickname.text.trim(),
                  'birthday': bday,
                  'sex': sex,
                },
              );
              if (!mounted) return;
              ref.invalidate(studentsProvider);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTeacherDialog(BuildContext context, WidgetRef ref, {AdminUser? existing}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TeacherFormDialog(existing: existing),
    );
  }
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
    final role = user.role.toLowerCase() == 'teacher' ? 'Teacher' : 'Admin';
    return _UserbaseEntry._(
      kind: role,
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.existing;
    _username = TextEditingController(text: user?.username ?? '');
    _password = TextEditingController();
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _middleInitial = TextEditingController(text: user?.middleInitial ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _firstName.dispose();
    _middleInitial.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Account' : 'Register Teacher'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value == null || value.trim().length < 3 ? 'Use at least 3 characters.' : null,
              ),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Temporary password'),
                  validator: (value) => value == null || value.length < 12 ? 'Use at least 12 characters.' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'First name')),
              const SizedBox(height: 12),
              TextFormField(controller: _middleInitial, decoration: const InputDecoration(labelText: 'Middle initial')),
              const SizedBox(height: 12),
              TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last name')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(isEdit ? 'Save Changes' : 'Create Teacher')),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(adminUsersProvider.notifier);
    final existing = widget.existing;
    if (existing == null) {
      await notifier.registerTeacher(
        username: _username.text.trim(),
        password: _password.text,
        firstName: _firstName.text.trim(),
        middleInitial: _middleInitial.text.trim(),
        lastName: _lastName.text.trim(),
      );
    } else {
      final safeFirst = _firstName.text.trim().isEmpty
          ? _username.text.trim()
          : _firstName.text.trim();
      final safeLast = _lastName.text.trim().isEmpty ? '-' : _lastName.text.trim();
      await notifier.updateTeacher(
        existing,
        username: _username.text.trim(),
        firstName: safeFirst,
        middleInitial: _middleInitial.text.trim(),
        lastName: safeLast,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  final AdminUser user;
  const _ResetPasswordDialog({required this.user});

  @override
  ConsumerState<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
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
          decoration: const InputDecoration(labelText: 'New temporary password'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (_controller.text.length < 12) return;
            await ref.read(adminUsersProvider.notifier).resetPassword(widget.user, _controller.text);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}
