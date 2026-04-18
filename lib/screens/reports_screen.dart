import 'package:flutter/material.dart';
import '../core/theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const masteryData = [
      _SubjectMastery('Mathematics', 84),
      _SubjectMastery('Science', 79),
      _SubjectMastery('Filipino', 72),
      _SubjectMastery('English', 88),
    ];

    const trendData = [64, 67, 69, 71, 73, 76, 79, 82];

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
                  'Reports & Stakeholder Insights',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export Summary'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: MediaQuery.of(context).size.width < 1000 ? 2 : 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.75,
              children: const [
                _ReportKpiCard(
                  title: 'Average Score',
                  value: '7.9 / 10',
                  delta: '+0.4 this month',
                  color: AppTheme.accent,
                  icon: Icons.insights_rounded,
                ),
                _ReportKpiCard(
                  title: 'Pass Rate',
                  value: '82.3%',
                  delta: '+2.2%',
                  color: AppTheme.primary,
                  icon: Icons.workspace_premium_rounded,
                ),
                _ReportKpiCard(
                  title: 'Needs Support',
                  value: '38 Students',
                  delta: '-5 from last month',
                  color: AppTheme.tertiary,
                  icon: Icons.flag_circle_rounded,
                ),
                _ReportKpiCard(
                  title: 'Active Devices',
                  value: '94.7%',
                  delta: 'Utilization rate',
                  color: AppTheme.info,
                  icon: Icons.tablet_mac_rounded,
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
                            'Subject Mastery Snapshot',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          ...masteryData.map((item) => _MasteryRow(item: item)),
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
                            'Cohort Trend (8 Weeks)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Average mastery progression for all active cohorts.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 180,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(trendData.length, (
                                index,
                              ) {
                                final score = trendData[index];
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$score',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: score * 1.5,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                AppTheme.primary,
                                                AppTheme.accent,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'W${index + 1}',
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
                      'Intervention Priority List',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Group')),
                          DataColumn(label: Text('Subject')),
                          DataColumn(label: Text('Students At Risk')),
                          DataColumn(label: Text('Suggested Action')),
                          DataColumn(label: Text('Priority')),
                        ],
                        rows: const [
                          DataRow(
                            cells: [
                              DataCell(Text('Punla (3-5)')),
                              DataCell(Text('Filipino')),
                              DataCell(Text('14')),
                              DataCell(Text('Reading comprehension drills')),
                              DataCell(_PriorityBadge('High', AppTheme.error)),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('Punla (3-5)')),
                              DataCell(Text('Science')),
                              DataCell(Text('9')),
                              DataCell(Text('Hands-on activity modules')),
                              DataCell(
                                _PriorityBadge('Medium', AppTheme.tertiary),
                              ),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('Binhi (6-8)')),
                              DataCell(Text('Mathematics')),
                              DataCell(Text('6')),
                              DataCell(Text('Numeracy challenge refreshers')),
                              DataCell(_PriorityBadge('Low', AppTheme.accent)),
                            ],
                          ),
                        ],
                      ),
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

class _ReportKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final Color color;
  final IconData icon;

  const _ReportKpiCard({
    required this.title,
    required this.value,
    required this.delta,
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
                Icon(icon, color: color, size: 19),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(delta, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MasteryRow extends StatelessWidget {
  final _SubjectMastery item;

  const _MasteryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(item.subject)),
              Text('${item.percent}%'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: item.percent / 100,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                item.percent >= 80 ? AppTheme.accent : AppTheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SubjectMastery {
  final String subject;
  final int percent;

  const _SubjectMastery(this.subject, this.percent);
}
