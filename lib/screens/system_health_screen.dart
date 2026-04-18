import 'package:flutter/material.dart';
import '../core/theme.dart';

class SystemHealthScreen extends StatelessWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const latencySeries = [138, 142, 135, 149, 147, 141, 139, 143, 136, 140];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'System Health',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.health_and_safety_rounded, size: 18),
                  label: const Text('Run Diagnostics'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: MediaQuery.of(context).size.width < 1100 ? 1 : 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: const [
                _HealthCard(
                  title: 'API Gateway',
                  status: 'Healthy',
                  metric: 'P95 142ms',
                  detail: 'No timeout spike in the last 6 hours.',
                  color: AppTheme.accent,
                  icon: Icons.api_rounded,
                ),
                _HealthCard(
                  title: 'Oracle Database',
                  status: 'Healthy',
                  metric: 'CPU 38%',
                  detail: 'Query pool stable with low lock contention.',
                  color: AppTheme.accent,
                  icon: Icons.storage_rounded,
                ),
                _HealthCard(
                  title: 'WebSocket Broker',
                  status: 'Degraded',
                  metric: '7 reconnects/hr',
                  detail: 'Intermittent connection churn detected.',
                  color: AppTheme.tertiary,
                  icon: Icons.wifi_tethering_error_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width < 1200
                      ? MediaQuery.of(context).size.width - 48
                      : (MediaQuery.of(context).size.width - 320) / 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latency Timeline (ms)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 190,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(latencySeries.length, (
                                index,
                              ) {
                                final latency = latencySeries[index];
                                final ratio = ((latency - 120) / 45)
                                    .clamp(0.15, 1.0)
                                    .toDouble();
                                final color = latency <= 145
                                    ? AppTheme.accent
                                    : AppTheme.tertiary;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$latency',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 130 * ratio,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'T${index + 1}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 1200
                      ? MediaQuery.of(context).size.width - 48
                      : (MediaQuery.of(context).size.width - 320) / 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reliability KPIs',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          const _MetricRow(
                            label: 'Overall Uptime',
                            value: '99.998%',
                            color: AppTheme.accent,
                          ),
                          const _MetricRow(
                            label: 'Failed Syncs (24h)',
                            value: '14',
                            color: AppTheme.error,
                          ),
                          const _MetricRow(
                            label: 'Average Queue Depth',
                            value: '37 events',
                            color: AppTheme.primary,
                          ),
                          const _MetricRow(
                            label: 'Last Restart',
                            value: '14d 2h 11m ago',
                            color: AppTheme.info,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Status recommendation: monitor WebSocket broker and tune reconnect backoff interval.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open Incident Queue',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    const _IncidentTile(
                      title: 'Tablet cluster B-12 repeated WS disconnects',
                      detail: 'Observed in 3 devices over 60 minutes.',
                      level: 'Medium',
                      color: AppTheme.tertiary,
                    ),
                    const _IncidentTile(
                      title: 'Late sync acknowledgements on /sync endpoint',
                      detail: 'P95 increased from 124ms to 142ms after noon.',
                      level: 'Low',
                      color: AppTheme.info,
                    ),
                    const _IncidentTile(
                      title: 'One failed DB health probe at 03:11',
                      detail: 'Transient issue, no user-facing impact.',
                      level: 'Low',
                      color: AppTheme.info,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title;
  final String status;
  final String metric;
  final String detail;
  final Color color;
  final IconData icon;

  const _HealthCard({
    required this.title,
    required this.status,
    required this.metric,
    required this.detail,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              metric,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 23,
              ),
            ),
            const SizedBox(height: 4),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final String title;
  final String detail;
  final String level;
  final Color color;

  const _IncidentTile({
    required this.title,
    required this.detail,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      level,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
