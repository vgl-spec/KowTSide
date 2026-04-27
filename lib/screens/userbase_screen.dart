import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/admin_user.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/flareline_components.dart';

class UserbaseScreen extends ConsumerWidget {
  const UserbaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlarePageHeader(
              title: 'Userbase',
              subtitle:
                  'Superadmin teacher account management for registration, edits, password resets, and account status.',
              actions: [
                FilledButton.icon(
                  onPressed: () => _showTeacherDialog(context, ref),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Register Teacher'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => ref.read(adminUsersProvider.notifier).load(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Failed to load userbase: $error'),
                ),
                data: (users) => _UserbaseBody(users: users),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeacherDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminUser? existing,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TeacherFormDialog(existing: existing),
    );
  }
}

class _UserbaseBody extends ConsumerStatefulWidget {
  final List<AdminUser> users;

  const _UserbaseBody({required this.users});

  @override
  ConsumerState<_UserbaseBody> createState() => _UserbaseBodyState();
}

class _UserbaseBodyState extends ConsumerState<_UserbaseBody> {
  String _query = '';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    final active = widget.users.where((user) => user.isActive).length;
    final resetRequired =
        widget.users.where((user) => user.mustChangePassword).length;
    final filtered = widget.users.where((user) {
      final needle = _query.trim().toLowerCase();
      final matchesQuery = needle.isEmpty ||
          user.username.toLowerCase().contains(needle) ||
          user.fullName.toLowerCase().contains(needle);
      final matchesStatus = _status == 'All' ||
          (_status == 'Active' && user.isActive) ||
          (_status == 'Inactive' && !user.isActive) ||
          (_status == 'Password reset' && user.mustChangePassword);
      return matchesQuery && matchesStatus;
    }).toList();

    return Column(
      children: [
        _KpiRow(
          total: widget.users.length,
          active: active,
          resetRequired: resetRequired,
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
                    hintText: 'Search teacher name or username...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Account status'),
                  items: const [
                    'All',
                    'Active',
                    'Inactive',
                    'Password reset',
                  ]
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: FlareSurfaceCard(
            child: filtered.isEmpty
                ? const Center(child: Text('No teacher accounts found.'))
                : Padding(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Teacher')),
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Role')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Password')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filtered.map((user) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 240,
                                    child: Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(user.username)),
                                DataCell(FlarePill(
                                  label: user.role,
                                  color: AppTheme.primary,
                                )),
                                DataCell(_StatusChip(active: user.isActive)),
                                DataCell(
                                  FlarePill(
                                    label: user.mustChangePassword
                                        ? 'Change required'
                                        : 'Current',
                                    color: user.mustChangePassword
                                        ? AppTheme.warning
                                        : AppTheme.success,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit teacher',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => showDialog<void>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) =>
                                              _TeacherFormDialog(existing: user),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Reset password',
                                        icon: const Icon(Icons.lock_reset),
                                        onPressed: () => showDialog<void>(
                                          context: context,
                                          builder: (_) =>
                                              _ResetPasswordDialog(user: user),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: user.isActive
                                            ? 'Deactivate'
                                            : 'Reactivate',
                                        icon: Icon(
                                          user.isActive
                                              ? Icons.block_rounded
                                              : Icons.check_circle_outline,
                                          color: user.isActive
                                              ? AppTheme.error
                                              : AppTheme.success,
                                        ),
                                        onPressed: () => ref
                                            .read(adminUsersProvider.notifier)
                                            .setActive(user, !user.isActive),
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
          ),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final int total;
  final int active;
  final int resetRequired;

  const _KpiRow({
    required this.total,
    required this.active,
    required this.resetRequired,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 3 : 1;
        final width = (constraints.maxWidth - (12 * (columns - 1))) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: FlareMetricTile(
                label: 'Teacher Accounts',
                value: '$total',
                hint: 'Registered classroom admin users',
                icon: Icons.badge_rounded,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: FlareMetricTile(
                label: 'Active Teachers',
                value: '$active',
                hint: 'Can sign in and manage content',
                icon: Icons.verified_user_rounded,
                color: AppTheme.success,
              ),
            ),
            SizedBox(
              width: width,
              child: FlareMetricTile(
                label: 'Password Resets',
                value: '$resetRequired',
                hint: 'Must change password on next sign-in',
                icon: Icons.lock_clock_rounded,
                color: AppTheme.warning,
              ),
            ),
          ],
        );
      },
    );
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
      title: Text(isEdit ? 'Edit Teacher' : 'Register Teacher'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _username,
                  enabled: !isEdit,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) =>
                      value == null || value.trim().length < 3
                          ? 'Use at least 3 characters.'
                          : null,
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Temporary password',
                      helperText:
                          'Minimum 12 chars. Teacher must change it later.',
                    ),
                    validator: (value) =>
                        value == null || value.length < 12
                            ? 'Use at least 12 characters.'
                            : null,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(labelText: 'First name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _middleInitial,
                        decoration:
                            const InputDecoration(labelText: 'M.I.'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(labelText: 'Last name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          child: Text(isEdit ? 'Save Changes' : 'Create Teacher'),
        ),
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
      await notifier.updateTeacher(
        existing,
        firstName: _firstName.text.trim(),
        middleInitial: _middleInitial.text.trim(),
        lastName: _lastName.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }
}

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  final AdminUser user;

  const _ResetPasswordDialog({required this.user});

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
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
      title: const Text('Reset Teacher Password'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New temporary password',
            helperText: 'Teacher will be required to change this after login.',
          ),
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

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    return FlarePill(
      label: active ? 'Active' : 'Inactive',
      color: active ? AppTheme.success : AppTheme.error,
    );
  }
}
