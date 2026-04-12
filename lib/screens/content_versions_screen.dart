import 'package:flutter/material.dart';
import '../core/theme.dart';

class ContentVersionsScreen extends StatelessWidget {
  const ContentVersionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  'Content Versions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Publish Update'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('Rollback Preview'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: MediaQuery.of(context).size.width < 960 ? 1 : 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: const [
                _VersionSummaryCard(
                  title: 'Current Version',
                  value: 'v43',
                  subtitle: 'Released 2 days ago',
                  color: AppTheme.primary,
                  icon: Icons.verified_rounded,
                ),
                _VersionSummaryCard(
                  title: 'Published This Month',
                  value: '6',
                  subtitle: 'Average +1 every 5 days',
                  color: AppTheme.accent,
                  icon: Icons.rocket_launch_rounded,
                ),
                _VersionSummaryCard(
                  title: 'Devices Pending Update',
                  value: '142',
                  subtitle: '3.4% of active tablets',
                  color: AppTheme.tertiary,
                  icon: Icons.sync_problem_rounded,
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
                      'Release Ledger',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Version Tag')),
                          DataColumn(label: Text('Changed By')),
                          DataColumn(label: Text('Change Note')),
                          DataColumn(label: Text('Released At')),
                          DataColumn(label: Text('Adoption')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: [
                          DataRow(
                            cells: [
                              DataCell(Text('v43')),
                              DataCell(Text('kow_admin')),
                              DataCell(Text('English hard-level refresh pack')),
                              DataCell(Text('2026-04-10 11:04')),
                              DataCell(Text('96.6%')),
                              DataCell(
                                _StatusDot(
                                  label: 'Active',
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('v42')),
                              DataCell(Text('jeremiah.v')),
                              DataCell(
                                Text('Science typo fixes and hint updates'),
                              ),
                              DataCell(Text('2026-04-05 09:18')),
                              DataCell(Text('100%')),
                              DataCell(
                                _StatusDot(
                                  label: 'Archived',
                                  color: AppTheme.textMediumEmphasis,
                                ),
                              ),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('v41')),
                              DataCell(Text('content.team')),
                              DataCell(
                                Text('Binhi math average-level additions'),
                              ),
                              DataCell(Text('2026-04-01 14:40')),
                              DataCell(Text('100%')),
                              DataCell(
                                _StatusDot(
                                  label: 'Archived',
                                  color: AppTheme.textMediumEmphasis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                  child: const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change Timeline'),
                          SizedBox(height: 12),
                          _VersionTimelineTile(
                            version: 'v43',
                            title: 'Question bank expansion for English',
                            detail:
                                'Added 45 prompts for Binhi hard level and updated distractor quality checks.',
                            timestamp: '2 days ago',
                            active: true,
                          ),
                          _VersionTimelineTile(
                            version: 'v42',
                            title: 'Science typo patch',
                            detail:
                                'Corrected spelling inconsistencies and refreshed explanation hints.',
                            timestamp: '1 week ago',
                          ),
                          _VersionTimelineTile(
                            version: 'v41',
                            title: 'Math progression rebalance',
                            detail:
                                'Adjusted average-level option spread for better difficulty curve.',
                            timestamp: '11 days ago',
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
                            'Release Safeguards',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          const _CheckItem(
                            text: 'Content checksum generated for each package',
                          ),
                          const _CheckItem(
                            text:
                                'Rollback snapshot retained for latest 5 versions',
                          ),
                          const _CheckItem(
                            text:
                                'Soft-delete only policy enforced for legacy questions',
                          ),
                          const _CheckItem(
                            text:
                                'Version bump procedure triggered after every CRUD mutation',
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Next scheduled release window: 2026-04-15 09:00 AM',
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
          ],
        ),
      ),
    );
  }
}

class _VersionSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _VersionSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Icon(icon, color: color),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _VersionTimelineTile extends StatelessWidget {
  final String version;
  final String title;
  final String detail;
  final String timestamp;
  final bool active;

  const _VersionTimelineTile({
    required this.version,
    required this.title,
    required this.detail,
    required this.timestamp,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: active ? AppTheme.accent : AppTheme.textLowEmphasis,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          version,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timestamp,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;

  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.accent, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
