import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/device.dart';

final devicesProvider = FutureProvider<List<Device>>((ref) async {
  if (ApiConstants.frontendOnly) {
    return MockData.devices();
  }
  final resp = await dio.get(ApiConstants.devices);
  final list = resp.data['devices'] as List? ?? resp.data as List? ?? [];
  return list.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
});
