import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin providers do not depend on missing live reporting endpoints', () {
    final dashboardProvider = File(
      'lib/providers/dashboard_provider.dart',
    ).readAsStringSync();
    final reportsProvider = File(
      'lib/providers/reports_provider.dart',
    ).readAsStringSync();
    final studentsProvider = File(
      'lib/providers/students_provider.dart',
    ).readAsStringSync();

    expect(dashboardProvider, isNot(contains('ApiConstants.leaderboard')));
    expect(reportsProvider, isNot(contains('ApiConstants.leaderboard')));
    expect(reportsProvider, contains('ApiConstants.reports'));
    expect(reportsProvider, contains('code != 404 && code != 405'));
    expect(reportsProvider, contains('Future.wait(['));
    expect(reportsProvider, contains('ApiConstants.dashboard'));
    expect(reportsProvider, contains('ApiConstants.students'));
    expect(studentsProvider, isNot(contains('ApiConstants.leaderboard')));
  });
}
