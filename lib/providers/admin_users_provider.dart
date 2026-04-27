import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/admin_user.dart';

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<AdminUser>>>(
      (ref) => AdminUsersNotifier()..load(),
    );

class AdminUsersNotifier extends StateNotifier<AsyncValue<List<AdminUser>>> {
  AdminUsersNotifier() : super(const AsyncValue.loading());

  final List<AdminUser> _demoUsers = <AdminUser>[
    const AdminUser(
      adminId: 2,
      teacherId: 1,
      username: 'teacher_mary',
      role: 'teacher',
      firstName: 'Mary Rose',
      middleInitial: 'M.',
      lastName: 'Manandeg',
      isActive: true,
      mustChangePassword: false,
      mfaEnabled: false,
    ),
    const AdminUser(
      adminId: 3,
      teacherId: 2,
      username: 'teacher_liza',
      role: 'teacher',
      firstName: 'Liza',
      middleInitial: 'A.',
      lastName: 'Cruz',
      isActive: true,
      mustChangePassword: true,
      mfaEnabled: false,
    ),
    const AdminUser(
      adminId: 4,
      teacherId: 3,
      username: 'teacher_joel',
      role: 'teacher',
      firstName: 'Joel',
      middleInitial: '',
      lastName: 'Dizon',
      isActive: false,
      mustChangePassword: true,
      mfaEnabled: false,
    ),
  ];

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      if (ApiConstants.frontendOnly) {
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
        return;
      }

      final response = await dio.get(ApiConstants.teacherUsers);
      final list =
          response.data['teachers'] as List? ??
          response.data['data'] as List? ??
          const <dynamic>[];
      state = AsyncValue.data(
        list
            .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (error, stackTrace) {
      if (!ApiConstants.frontendOnly) {
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
        return;
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> registerTeacher({
    required String username,
    required String password,
    required String firstName,
    required String middleInitial,
    required String lastName,
  }) async {
    if (ApiConstants.frontendOnly) {
      _registerTeacherLocally(
        username: username,
        firstName: firstName,
        middleInitial: middleInitial,
        lastName: lastName,
      );
      return;
    }

    try {
      await dio.post(
        ApiConstants.teacherUsers,
        data: {
          'username': username,
          'password': password,
          'first_name': firstName,
          'middle_initial': middleInitial,
          'last_name': lastName,
        },
      );
      await load();
    } catch (_) {
      _registerTeacherLocally(
        username: username,
        firstName: firstName,
        middleInitial: middleInitial,
        lastName: lastName,
      );
    }
  }

  void _registerTeacherLocally({
    required String username,
    required String firstName,
    required String middleInitial,
    required String lastName,
  }) {
    final nextAdminId =
        _demoUsers
            .map((user) => user.adminId)
            .fold<int>(0, (max, id) => id > max ? id : max) +
        1;
    final nextTeacherId =
        _demoUsers
            .map((user) => user.teacherId)
            .fold<int>(0, (max, id) => id > max ? id : max) +
        1;
    _demoUsers.insert(
      0,
      AdminUser(
        adminId: nextAdminId,
        teacherId: nextTeacherId,
        username: username,
        role: 'teacher',
        firstName: firstName,
        middleInitial: middleInitial,
        lastName: lastName,
        isActive: true,
        mustChangePassword: true,
        mfaEnabled: false,
      ),
    );
    state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
  }

  Future<void> updateTeacher(
    AdminUser user, {
    required String firstName,
    required String middleInitial,
    required String lastName,
  }) async {
    if (ApiConstants.frontendOnly) {
      final index = _demoUsers.indexWhere(
        (item) => item.adminId == user.adminId,
      );
      if (index >= 0) {
        _demoUsers[index] = _demoUsers[index].copyWith(
          firstName: firstName,
          middleInitial: middleInitial,
          lastName: lastName,
        );
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
      }
      return;
    }

    try {
      await dio.put(
        ApiConstants.teacherUser(user.adminId),
        data: {
          'first_name': firstName,
          'middle_initial': middleInitial,
          'last_name': lastName,
        },
      );
      await load();
    } catch (_) {
      final index = _demoUsers.indexWhere(
        (item) => item.adminId == user.adminId,
      );
      if (index >= 0) {
        _demoUsers[index] = _demoUsers[index].copyWith(
          firstName: firstName,
          middleInitial: middleInitial,
          lastName: lastName,
        );
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
      }
    }
  }

  Future<void> resetPassword(AdminUser user, String password) async {
    if (ApiConstants.frontendOnly) {
      final index = _demoUsers.indexWhere(
        (item) => item.adminId == user.adminId,
      );
      if (index >= 0) {
        _demoUsers[index] = _demoUsers[index].copyWith(
          mustChangePassword: true,
        );
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
      }
      return;
    }

    try {
      await dio.post(
        ApiConstants.teacherPasswordReset(user.adminId),
        data: {'password': password},
      );
      await load();
    } catch (_) {
      final index = _demoUsers.indexWhere(
        (item) => item.adminId == user.adminId,
      );
      if (index >= 0) {
        _demoUsers[index] = _demoUsers[index].copyWith(
          mustChangePassword: true,
        );
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
      }
    }
  }

  Future<void> setActive(AdminUser user, bool isActive) async {
    if (ApiConstants.frontendOnly) {
      final index = _demoUsers.indexWhere(
        (item) => item.adminId == user.adminId,
      );
      if (index >= 0) {
        _demoUsers[index] = _demoUsers[index].copyWith(isActive: isActive);
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
      }
      return;
    }

    try {
      await dio.patch(
        ApiConstants.teacherStatus(user.adminId),
        data: {'is_active': isActive ? 1 : 0},
      );
      await load();
    } catch (_) {
      final index = _demoUsers.indexWhere(
        (item) => item.adminId == user.adminId,
      );
      if (index >= 0) {
        _demoUsers[index] = _demoUsers[index].copyWith(isActive: isActive);
        state = AsyncValue.data(List<AdminUser>.from(_demoUsers));
      }
    }
  }
}
