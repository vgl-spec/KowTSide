import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/devices_provider.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(devicesProvider);

    return SafeArea(
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 8),
              Text('$error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(devicesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (devices) {
          final syncedCount = devices
              .where((device) => device.hasSynced)
              .length;
          final neverSyncedCount = devices.length - syncedCount;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Registered Devices',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(devicesProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SummaryChip(
                      label: 'Total',
                      value: '${devices.length}',
                      color: AppTheme.primary,
                    ),
                    _SummaryChip(
                      label: 'Synced',
                      value: '$syncedCount',
                      color: AppTheme.accent,
                    ),
                    _SummaryChip(
                      label: 'Never Synced',
                      value: '$neverSyncedCount',
                      color: AppTheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: devices.isEmpty
                        ? const Center(
                            child: Text('No devices registered yet.'),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Device Name')),
                                    DataColumn(label: Text('UUID')),
                                    DataColumn(label: Text('Registered At')),
                                    DataColumn(label: Text('Last Synced')),
                                    DataColumn(label: Text('Students')),
                                    DataColumn(label: Text('Status')),
                                  ],
                                  rows: devices.map((device) {
                                    final synced = device.hasSynced;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.tablet_android_outlined,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                device.deviceName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          SelectableText(
                                            device.deviceUuid,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(device.registeredAt)),
                                        DataCell(
                                          Text(
                                            synced ? device.lastSyncedAt! : '-',
                                          ),
                                        ),
                                        DataCell(
                                          Chip(
                                            label: Text(
                                              '${device.studentsOnDevice}',
                                            ),
                                            avatar: const Icon(
                                              Icons.person_outline,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          synced
                                              ? const Chip(
                                                  label: Text('Synced'),
                                                  backgroundColor: Color(
                                                    0xFFE8F5E9,
                                                  ),
                                                  labelStyle: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                )
                                              : const Chip(
                                                  label: Text('Never synced'),
                                                  backgroundColor: Color(
                                                    0xFFFFF3E0,
                                                  ),
                                                  labelStyle: TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 12,
                                                  ),
                                                  padding: EdgeInsets.zero,
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
            ),
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
