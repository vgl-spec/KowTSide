import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/device.dart';

final devicesPageStateProvider = StateProvider<int>((ref) => 1);

const int _devicesPageSize = 25;

final devicesProvider = FutureProvider<DevicePage>((ref) async {
  final page = ref.watch(devicesPageStateProvider);

  if (ApiConstants.frontendOnly) {
    final devices = MockData.devices();
    final total = devices.length;
    final totalPages = total == 0 ? 1 : ((total + _devicesPageSize - 1) ~/ _devicesPageSize);
    final safePage = page > totalPages ? totalPages : page;
    final start = (safePage - 1) * _devicesPageSize;
    final pageItems = devices.skip(start).take(_devicesPageSize).toList();
    return DevicePage(
      page: safePage,
      limit: _devicesPageSize,
      total: total,
      totalPages: totalPages,
      devices: pageItems,
    );
  }

  final resp = await dio.get(
    ApiConstants.devices,
    queryParameters: {'page': page, 'limit': _devicesPageSize},
  );
  return DevicePage.fromJson(resp.data as Map<String, dynamic>);
});
