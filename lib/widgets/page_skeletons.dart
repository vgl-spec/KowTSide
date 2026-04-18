import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/app_colors.dart';

class Skeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkElevated : AppColors.lightElevated;
    final highlightColor = isDark ? AppColors.darkSidebar : AppColors.lightSidebar;
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white, // Color is not rendered because of Shimmer replacing it
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            Skeleton(height: 32, width: 180),
            Skeleton(height: 30, width: 120),
            Skeleton(height: 36, width: 140),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
            3,
            (_) => SizedBox(
              width: 320,
              height: 140, // Height to match the new StatCard
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Skeleton(height: 14, width: 100),
                          SizedBox(height: 12),
                          Skeleton(height: 36, width: 140),
                        ],
                      ),
                      const Skeleton(
                        height: 64, width: 64, 
                        borderRadius: BorderRadius.all(Radius.circular(32))
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _SectionSkeleton(rows: 6)),
            SizedBox(width: 16),
            Expanded(flex: 1, child: _SectionSkeleton(rows: 8)),
          ],
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final int rows;

  const _SectionSkeleton({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            rows,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Skeleton(height: 48, width: double.infinity),
            )
          ),
        ),
      ),
    );
  }
}

class StudentsLoadingSkeleton extends StatelessWidget {
  const StudentsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              Skeleton(height: 32, width: 140),
              Skeleton(height: 36, width: 110),
            ],
          ),
          const SizedBox(height: 24),
          const Expanded(child: _TableSkeleton(columns: 8, rows: 8)),
        ],
      ),
    );
  }
}

class DevicesLoadingSkeleton extends StatelessWidget {
  const DevicesLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              Skeleton(height: 32, width: 210),
              Skeleton(height: 36, width: 110),
            ],
          ),
          const SizedBox(height: 24),
          const Expanded(child: _TableSkeleton(columns: 6, rows: 8)),
        ],
      ),
    );
  }
}

class QuestionsLoadingSkeleton extends StatelessWidget {
  const QuestionsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              Skeleton(height: 32, width: 170),
              Skeleton(height: 36, width: 130),
              Skeleton(height: 36, width: 110),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Skeleton(height: 32, width: 100),
                  Skeleton(height: 32, width: 100),
                ],
              ),
            ),
          ),
        ),
        const Expanded(child: Padding(
          padding: EdgeInsets.all(24),
          child: _TableSkeleton(columns: 7, rows: 6),
        )),
      ],
    );
  }
}

class StudentDetailLoadingSkeleton extends StatelessWidget {
  const StudentDetailLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Skeleton(
                    height: 72,
                    width: 72,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Skeleton(height: 16, width: 140),
                        Skeleton(height: 16, width: 180),
                        Skeleton(height: 16, width: 120),
                        Skeleton(height: 16, width: 160),
                        Skeleton(height: 16, width: 130),
                        Skeleton(height: 16, width: 150),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Skeleton(height: 18, width: 170),
          const SizedBox(height: 8),
          const SizedBox(height: 280, child: _TableSkeleton(columns: 4, rows: 4)),
          const SizedBox(height: 24),
          const Skeleton(height: 18, width: 150),
          const SizedBox(height: 8),
          const SizedBox(height: 280, child: _TableSkeleton(columns: 6, rows: 4)),
          const SizedBox(height: 24),
          const Skeleton(height: 18, width: 130),
          const SizedBox(height: 8),
          const SizedBox(height: 260, child: _TableSkeleton(columns: 5, rows: 4)),
        ],
      ),
    );
  }
}

class StandardPageLoadingSkeleton extends StatelessWidget {
  const StandardPageLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Skeleton(height: 30, width: 220),
          SizedBox(height: 16),
          Skeleton(height: 42, width: 360),
          SizedBox(height: 24),
          Expanded(child: _SectionSkeleton(rows: 7)),
        ],
      ),
    );
  }
}

class ReportsLoadingSkeleton extends StatelessWidget {
  const ReportsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Skeleton(height: 32, width: 290),
            Skeleton(height: 36, width: 150),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            4,
            (_) => const SizedBox(
              width: 245,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14, width: 120),
                      SizedBox(height: 10),
                      Skeleton(height: 30, width: 120),
                      SizedBox(height: 8),
                      Skeleton(height: 12, width: 140),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SizedBox(height: 270, child: _SectionSkeleton(rows: 5))),
            SizedBox(width: 10),
            Expanded(child: SizedBox(height: 270, child: _SectionSkeleton(rows: 5))),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 340, child: _TableSkeleton(columns: 5, rows: 5)),
      ],
    );
  }
}

class ContentVersionsLoadingSkeleton extends StatelessWidget {
  const ContentVersionsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Skeleton(height: 32, width: 210),
            Skeleton(height: 36, width: 150),
            Skeleton(height: 36, width: 170),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            3,
            (_) => const SizedBox(
              width: 320,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14, width: 140),
                      SizedBox(height: 10),
                      Skeleton(height: 30, width: 90),
                      SizedBox(height: 8),
                      Skeleton(height: 12, width: 170),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 280, child: _TableSkeleton(columns: 6, rows: 4)),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SizedBox(height: 250, child: _SectionSkeleton(rows: 4))),
            SizedBox(width: 10),
            Expanded(child: SizedBox(height: 250, child: _SectionSkeleton(rows: 6))),
          ],
        ),
      ],
    );
  }
}

class AuditLogLoadingSkeleton extends StatelessWidget {
  const AuditLogLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Skeleton(height: 32, width: 130),
            Skeleton(height: 42, width: 360),
            Skeleton(height: 36, width: 150),
            Skeleton(height: 36, width: 150),
            Skeleton(height: 36, width: 120),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            3,
            (_) => const SizedBox(
              width: 320,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14, width: 130),
                      SizedBox(height: 10),
                      Skeleton(height: 30, width: 80),
                      SizedBox(height: 8),
                      Skeleton(height: 12, width: 150),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 340, child: _TableSkeleton(columns: 5, rows: 6)),
      ],
    );
  }
}

class SyncLogsLoadingSkeleton extends StatelessWidget {
  const SyncLogsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Skeleton(height: 32, width: 110),
            Skeleton(height: 42, width: 320),
            Skeleton(height: 36, width: 140),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (_) => const SizedBox(
              width: 245,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14, width: 110),
                      SizedBox(height: 10),
                      Skeleton(height: 28, width: 95),
                      SizedBox(height: 8),
                      Skeleton(height: 12, width: 140),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 420, child: _TableSkeleton(columns: 5, rows: 8)),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            Skeleton(height: 34, width: 430),
            Skeleton(height: 34, width: 120),
            Skeleton(height: 34, width: 140),
          ],
        ),
      ],
    );
  }
}

class SystemHealthLoadingSkeleton extends StatelessWidget {
  const SystemHealthLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Skeleton(height: 32, width: 170),
            Skeleton(height: 36, width: 150),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            3,
            (_) => const SizedBox(
              width: 320,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14, width: 140),
                      SizedBox(height: 8),
                      Skeleton(height: 22, width: 95),
                      SizedBox(height: 8),
                      Skeleton(height: 12, width: 170),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SizedBox(height: 280, child: _SectionSkeleton(rows: 5))),
            SizedBox(width: 10),
            Expanded(child: SizedBox(height: 280, child: _SectionSkeleton(rows: 6))),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 250, child: _SectionSkeleton(rows: 4)),
      ],
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  final int columns;
  final int rows;

  const _TableSkeleton({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Skeleton(height: 24, width: double.infinity),
            const SizedBox(height: 16),
            ...List.generate(
              rows,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Skeleton(height: 48, width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
