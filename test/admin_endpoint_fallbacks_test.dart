import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'missing admin endpoints do not show demo userbase or activity errors',
    () {
      final activityProvider = File(
        'lib/providers/activity_logs_provider.dart',
      ).readAsStringSync();
      final usersProvider = File(
        'lib/providers/admin_users_provider.dart',
      ).readAsStringSync();

      expect(activityProvider, contains('code != 404 && code != 405'));
      expect(usersProvider, contains('code == 404 || code == 405'));
      expect(usersProvider, isNot(contains('teacher_liza')));
    },
  );
}
