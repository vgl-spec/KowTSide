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
    final highlightColor = isDark
        ? AppColors.darkSidebar
        : AppColors.lightSidebar;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors
              .white, // Color is not rendered because of Shimmer replacing it
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
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
            (_) => const SizedBox(
              width: 320,
              height: 140, // Height to match the new StatCard
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Skeleton(height: 14, width: 100),
                          SizedBox(height: 12),
                          Skeleton(height: 36, width: 140),
                        ],
                      ),
                      Skeleton(
                        height: 64,
                        width: 64,
                        borderRadius: BorderRadius.all(Radius.circular(32)),
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
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rows,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Skeleton(height: 48, width: double.infinity),
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.hasBoundedHeight) {
              return SingleChildScrollView(child: content);
            }
            return content;
          },
        ),
      ),
    );
  }
}

class StudentsLoadingSkeleton extends StatelessWidget {
  const StudentsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              Skeleton(height: 32, width: 140),
              Skeleton(height: 36, width: 110),
            ],
          ),
          SizedBox(height: 24),
          Expanded(child: _TableSkeleton(columns: 8, rows: 8)),
        ],
      ),
    );
  }
}

class DevicesLoadingSkeleton extends StatelessWidget {
  const DevicesLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              Skeleton(height: 32, width: 210),
              Skeleton(height: 36, width: 110),
            ],
          ),
          SizedBox(height: 24),
          Expanded(child: _TableSkeleton(columns: 6, rows: 8)),
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: const [
              _QuestionsHeaderSkeleton(),
              SizedBox(height: 14),
              _QuestionsFilterSkeleton(),
              SizedBox(height: 14),
              _QuestionBankTableSkeleton(rows: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionsHeaderSkeleton extends StatelessWidget {
  const _QuestionsHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(height: 34, width: 220),
            SizedBox(height: 10),
            Skeleton(height: 16, width: 560),
            SizedBox(height: 6),
            Skeleton(height: 16, width: 420),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            Skeleton(height: 40, width: 156),
            Skeleton(height: 40, width: 136),
            Skeleton(height: 40, width: 108),
          ],
        ),
      ],
    );
  }
}

class _QuestionsFilterSkeleton extends StatelessWidget {
  const _QuestionsFilterSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(height: 20, width: 220),
            SizedBox(height: 10),
            Skeleton(height: 14, width: 520),
            SizedBox(height: 6),
            Skeleton(height: 14, width: 380),
            SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                Skeleton(height: 56, width: 210),
                Skeleton(height: 56, width: 210),
                Skeleton(height: 56, width: 210),
                Skeleton(height: 56, width: 210),
                Skeleton(height: 34, width: 118),
                Skeleton(height: 34, width: 88),
                Skeleton(height: 34, width: 82),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBankTableSkeleton extends StatelessWidget {
  final int rows;

  const _QuestionBankTableSkeleton({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1080;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) const _QuestionTableHeader(),
                if (!compact) const SizedBox(height: 8),
                ...List.generate(
                  rows,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == rows - 1 ? 0 : 10,
                    ),
                    child: _QuestionTableRowSkeleton(compact: compact),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuestionTableHeader extends StatelessWidget {
  const _QuestionTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 52, child: Skeleton(height: 14, width: 24)),
          const SizedBox(width: 12),
          _headerCell(22),
          const SizedBox(width: 12),
          _headerCell(28),
          const SizedBox(width: 12),
          _headerCell(42),
          const SizedBox(width: 12),
          _headerCell(22),
        ],
      ),
    );
  }

  Widget _headerCell(int flex) {
    return Expanded(
      flex: flex,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Skeleton(height: 14, width: 92),
      ),
    );
  }
}

class _QuestionTableRowSkeleton extends StatelessWidget {
  final bool compact;

  const _QuestionTableRowSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.32),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: compact
          ? const _QuestionTableRowCompact()
          : const _QuestionTableRowWide(),
    );
  }
}

class _QuestionTableRowWide extends StatelessWidget {
  const _QuestionTableRowWide();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Skeleton(height: 14, width: 28),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 14, width: 108),
              SizedBox(height: 6),
              Skeleton(height: 14, width: 74),
              SizedBox(height: 6),
              Skeleton(height: 12, width: 88),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 14, width: 124),
              SizedBox(height: 8),
              Skeleton(height: 14, width: 152),
              SizedBox(height: 8),
              Skeleton(height: 28, width: 84),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 42,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(
                height: 64,
                width: 64,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: 14, width: 220),
                    SizedBox(height: 8),
                    Skeleton(height: 14, width: 194),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 22,
          child: Row(
            children: [
              Skeleton(
                height: 32,
                width: 32,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SizedBox(width: 10),
              Expanded(child: Skeleton(height: 14, width: 120)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionTableRowCompact extends StatelessWidget {
  const _QuestionTableRowCompact();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Skeleton(height: 28, width: 60),
            Spacer(),
            Skeleton(height: 28, width: 76),
          ],
        ),
        SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(height: 12, width: 46),
                  SizedBox(height: 6),
                  Skeleton(height: 14, width: 104),
                  SizedBox(height: 6),
                  Skeleton(height: 14, width: 70),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(height: 12, width: 38),
                  SizedBox(height: 6),
                  Skeleton(height: 14, width: 120),
                  SizedBox(height: 6),
                  Skeleton(height: 14, width: 146),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Skeleton(height: 12, width: 52),
        SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(
              height: 64,
              width: 64,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(height: 14, width: 220),
                  SizedBox(height: 8),
                  Skeleton(height: 14, width: 164),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Skeleton(height: 12, width: 96),
        SizedBox(height: 8),
        Row(
          children: [
            Skeleton(
              height: 32,
              width: 32,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            SizedBox(width: 10),
            Expanded(child: Skeleton(height: 14, width: 120)),
          ],
        ),
      ],
    );
  }
}

class StudentDetailLoadingSkeleton extends StatelessWidget {
  const StudentDetailLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          SizedBox(height: 24),
          Skeleton(height: 18, width: 170),
          SizedBox(height: 8),
          SizedBox(height: 280, child: _TableSkeleton(columns: 4, rows: 4)),
          SizedBox(height: 24),
          Skeleton(height: 18, width: 150),
          SizedBox(height: 8),
          SizedBox(height: 280, child: _TableSkeleton(columns: 6, rows: 4)),
          SizedBox(height: 24),
          Skeleton(height: 18, width: 130),
          SizedBox(height: 8),
          SizedBox(height: 260, child: _TableSkeleton(columns: 5, rows: 4)),
        ],
      ),
    );
  }
}

class StandardPageLoadingSkeleton extends StatelessWidget {
  const StandardPageLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            Expanded(
              child: SizedBox(height: 270, child: _SectionSkeleton(rows: 5)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: SizedBox(height: 270, child: _SectionSkeleton(rows: 5)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 340, child: _TableSkeleton(columns: 5, rows: 5)),
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
            Expanded(
              child: SizedBox(height: 280, child: _SectionSkeleton(rows: 5)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: SizedBox(height: 280, child: _SectionSkeleton(rows: 6)),
            ),
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
    final content = Column(
      mainAxisSize: MainAxisSize.min,
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
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.hasBoundedHeight) {
              return SingleChildScrollView(child: content);
            }
            return content;
          },
        ),
      ),
    );
  }
}
