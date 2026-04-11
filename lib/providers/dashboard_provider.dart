import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/dashboard.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.dashboard();
  }
  final resp = await dio.get(ApiConstants.dashboard);
  return DashboardData.fromJson(resp.data as Map<String, dynamic>);
});
