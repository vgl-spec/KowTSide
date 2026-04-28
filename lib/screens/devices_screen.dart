import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/devices_provider.dart';
import '../providers/live_updates_provider.dart';
import '../widgets/page_skeletons.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(wsEventsProvider, (_, next) {
      next.whenData((event) {
        if (shouldInvalidateForWsEvent(event.type)) {
          ref.invalidate(devicesProvider);
        }
      });
    });

    final async = ref.watch(devicesProvider);

    return SafeArea(
      child: async.when(
        loading: () => const DevicesLoadingSkeleton(),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final desktop = constraints.maxWidth >= 1100;
                      final tableMinWidth = constraints.maxWidth
                          .clamp(960.0, 1400.0)
                          .toDouble();

                      return Card(
                        child: devices.isEmpty
                            ? const Center(
                                child: Text('No devices registered yet.'),
                              )
                            : Padding(
                                padding: EdgeInsets.all(desktop ? 16 : 10),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: tableMinWidth,
                                    ),
                                    child: DataTable(
                                      columnSpacing: desktop ? 32 : 18,
                                      horizontalMargin: desktop ? 20 : 12,
                                      headingRowHeight: 54,
                                      dataRowMinHeight: desktop ? 62 : 52,
                                      dataRowMaxHeight: desktop ? 72 : 60,
                                      columns: const [
                                        DataColumn(
                                          label: SizedBox(
                                            width: 280,
                                            child: Text('Device Name'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 260,
                                            child: Text('UUID'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 170,
                                            child: Text('Registered At'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 170,
                                            child: Text('Last Synced'),
                                          ),
                                        ),
                                        DataColumn(
                                          numeric: true,
                                          label: SizedBox(
                                            width: 110,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text('Students'),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 150,
                                            child: Text('Status'),
                                          ),
                                        ),
                                      ],
                                      rows: devices.map((device) {
                                        final synced = device.hasSynced;
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 280,
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .tablet_android_outlined,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        device.deviceName,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 260,
                                                child: SelectableText(
                                                  device.deviceUuid,
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  _formatTimestamp(
                                                    device.registeredAt,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  synced
                                                      ? _formatTimestamp(
                                                          device.lastSyncedAt,
                                                        )
                                                      : '-',
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    '${device.studentsOnDevice}',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 150,
                                                child: synced
                                                    ? Chip(
                                                        label: const Text(
                                                          'Synced',
                                                        ),
                                                        backgroundColor:
                                                            AppTheme.success
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                        labelStyle:
                                                            const TextStyle(
                                                              color: AppTheme
                                                                  .success,
                                                              fontSize: 12,
                                                            ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      )
                                                    : Chip(
                                                        label: const Text(
                                                          'Never synced',
                                                        ),
                                                        backgroundColor:
                                                            AppTheme.warning
                                                                .withValues(
                                                                  alpha: 0.16,
                                                                ),
                                                        labelStyle:
                                                            const TextStyle(
                                                              color: AppTheme
                                                                  .warning,
                                                              fontSize: 12,
                                                            ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                      );
                    },
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

String _formatTimestamp(String? rawValue) {
  if (rawValue == null || rawValue.isEmpty) {
    return '-';
  }

  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    return rawValue;
  }

  final local = parsed.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
