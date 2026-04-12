import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.16);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
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
            SkeletonBox(height: 32, width: 180),
            SkeletonBox(height: 30, width: 120),
            SkeletonBox(height: 36, width: 140),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            3,
            (_) => SizedBox(
              width: 286,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 14, width: 120),
                      SizedBox(height: 8),
                      SkeletonBox(height: 30, width: 140),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 170),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionSkeleton(rows: 4),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SectionSkeleton(rows: 4)),
            SizedBox(width: 10),
            Expanded(child: _SectionSkeleton(rows: 6)),
          ],
        ),
      ],
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
              SkeletonBox(height: 32, width: 140),
              SkeletonBox(height: 36, width: 110),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              4,
              (_) => const SkeletonBox(height: 34, width: 130),
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SkeletonBox(height: 42, width: 360),
              SkeletonBox(height: 42, width: 150),
            ],
          ),
          const SizedBox(height: 12),
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
              SkeletonBox(height: 32, width: 210),
              SkeletonBox(height: 36, width: 110),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              3,
              (_) => const SkeletonBox(height: 34, width: 120),
            ),
          ),
          const SizedBox(height: 12),
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
              SkeletonBox(height: 32, width: 170),
              SkeletonBox(height: 36, width: 130),
              SkeletonBox(height: 36, width: 110),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  SkeletonBox(height: 38, width: 140),
                  SkeletonBox(height: 38, width: 140),
                  SkeletonBox(height: 38, width: 140),
                  SkeletonBox(height: 32, width: 120),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _TableSkeleton(columns: 8, rows: 8),
          ),
        ),
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
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 24, width: 220),
                  SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SkeletonBox(height: 16, width: 110),
                      SkeletonBox(height: 16, width: 140),
                      SkeletonBox(height: 16, width: 80),
                      SkeletonBox(height: 16, width: 110),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          SkeletonBox(height: 24, width: 170),
          SizedBox(height: 8),
          _TableSkeleton(columns: 4, rows: 4, height: 220),
          SizedBox(height: 24),
          SkeletonBox(height: 24, width: 150),
          SizedBox(height: 8),
          _TableSkeleton(columns: 6, rows: 4, height: 220),
          SizedBox(height: 24),
          SkeletonBox(height: 24, width: 130),
          SizedBox(height: 8),
          _TableSkeleton(columns: 5, rows: 4, height: 220),
        ],
      ),
    );
  }
}

class StandardPageLoadingSkeleton extends StatelessWidget {
  const StandardPageLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SkeletonBox(height: 32, width: 210),
            SkeletonBox(height: 36, width: 130),
          ],
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: _TableSkeleton(columns: 4, rows: 4, height: 180)),
            SizedBox(width: 12),
            Expanded(child: _TableSkeleton(columns: 3, rows: 4, height: 180)),
          ],
        ),
        const SizedBox(height: 12),
        const _TableSkeleton(columns: 6, rows: 8, height: 360),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 22, width: 180),
            const SizedBox(height: 8),
            const SkeletonBox(height: 14, width: 290),
            const SizedBox(height: 12),
            ...List.generate(
              rows,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SkeletonBox(height: 18, width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  final int columns;
  final int rows;
  final double? height;

  const _TableSkeleton({
    required this.columns,
    required this.rows,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: List.generate(
                  columns,
                  (_) => const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: SkeletonBox(height: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: rows,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: List.generate(
                        columns,
                        (_) => const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: SkeletonBox(height: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
