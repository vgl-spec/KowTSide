import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kow_admin_web/models/dashboard.dart';
import 'package:kow_admin_web/models/student.dart';

void main() {
  test('student-facing score models normalize legacy /10 payloads to /5', () {
    final student = Student.fromJson({
      'stud_id': 1001,
      'nickname': 'Mari',
      'first_name': 'Maria',
      'last_name': 'Santos',
      'avg_score': 8.0,
      'proficiency': '',
    });

    final scoreRecord = ScoreRecord.fromJson({
      'subject': 'Mathematics',
      'difficulty': 'Average',
      'score': 8,
      'total_items': 10,
      'passed': 1,
      'played_at': '2026-05-06T08:00:00',
    });

    final dashboard = DashboardData.fromJson({
      'average_score': 8.0,
      'subject_level_summary': [
        {
          'gradelvl': 'Punla',
          'subject': 'Mathematics',
          'active_students': 4,
          'avg_score': 8.0,
          'pass_rate_pct': 80.0,
        },
      ],
    });

    expect(student.avgScore, 4.0);
    expect(student.proficiency, 'On track');
    expect(scoreRecord.score, 4.0);
    expect(scoreRecord.totalItems, 5);
    expect(dashboard.averageScore, 4.0);
    expect(dashboard.ageGroupProgress.single.avgScore, 4.0);
  });

  test(
    'router boots on a non-protected route while auth restore is loading',
    () {
      final appSource = File('lib/app.dart').readAsStringSync();

      expect(appSource, contains('initialLocation: _bootstrapRoute'));
      expect(appSource, contains('path: _bootstrapRoute'));
      expect(appSource, contains("if (auth.isLoading)"));
    },
  );
}
