import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

class ChartSegment {
  final String label;
  final double value;
  final Color color;

  const ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class SimpleBarDatum {
  final String label;
  final double value;
  final Color color;

  const SimpleBarDatum({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DualBarDatum {
  final String label;
  final double leftValue;
  final double rightValue;

  const DualBarDatum({
    required this.label,
    required this.leftValue,
    required this.rightValue,
  });
}

class DonutBreakdownChart extends StatelessWidget {
  final List<ChartSegment> segments;
  final String centerLabel;

  const DonutBreakdownChart({
    super.key,
    required this.segments,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty || segments.every((segment) => segment.value <= 0)) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No chart data available.')),
      );
    }

    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    centerSpaceRadius: 58,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    sections: segments.map((segment) {
                      final percent = total <= 0 ? 0 : (segment.value / total) * 100;
                      return PieChartSectionData(
                        color: segment.color,
                        value: segment.value,
                        radius: 26,
                        title: '${percent.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(centerLabel, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: segments.map((segment) {
                final percent = total <= 0 ? 0 : (segment.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(segment.label)),
                      Text(
                        '${segment.value.toStringAsFixed(0)} (${percent.toStringAsFixed(0)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SingleBarChart extends StatelessWidget {
  final List<SimpleBarDatum> data;
  final double maxY;
  final bool percentageScale;

  const SingleBarChart({
    super.key,
    required this.data,
    required this.maxY,
    this.percentageScale = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('No chart data available.')),
      );
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: data.length <= 2
              ? BarChartAlignment.spaceEvenly
              : BarChartAlignment.spaceAround,
          groupsSpace: data.length <= 2 ? 26 : 12,
          barTouchData: BarTouchData(enabled: true),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 10 ? 2 : 20,
            getDrawingHorizontalLine: (value) => FlLine(
              strokeWidth: 1,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 45,
                showTitles: true,
                interval: maxY <= 10 ? 2 : 20,
                getTitlesWidget: (value, _) {
                  final label = percentageScale
                      ? '${value.toStringAsFixed(0)}%'
                      : value.toStringAsFixed(0);
                  return Text(label, style: Theme.of(context).textTheme.bodySmall);
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  final label = data[index].label;
                  return SideTitleWidget(
                    axisSide: AxisSide.bottom,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label.length > 10 ? '${label.substring(0, 10)}...' : label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: data.asMap().entries.map((entry) {
            final barWidth = data.length <= 2
                ? 46.0
                : data.length <= 4
                ? 34.0
                : 22.0;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  width: barWidth,
                  borderRadius: BorderRadius.circular(6),
                  color: entry.value.color,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DualMetricBarChart extends StatelessWidget {
  final List<DualBarDatum> data;
  final String leftLegend;
  final String rightLegend;
  final double maxY;

  const DualMetricBarChart({
    super.key,
    required this.data,
    required this.leftLegend,
    required this.rightLegend,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('No chart data available.')),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            _LegendDot(color: AppTheme.primary, label: leftLegend),
            const SizedBox(width: 12),
            _LegendDot(color: AppTheme.tertiary, label: rightLegend),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: data.length <= 2
                  ? BarChartAlignment.spaceEvenly
                  : BarChartAlignment.spaceAround,
              groupsSpace: data.length <= 2 ? 28 : 12,
              barTouchData: BarTouchData(enabled: true),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY <= 10 ? 2 : 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  strokeWidth: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.28),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY <= 10 ? 2 : 20,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        axisSide: AxisSide.bottom,
                        child: Text(
                          data[index].label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: data.asMap().entries.map((entry) {
                final barWidth = data.length <= 4 ? 24.0 : 14.0;
                return BarChartGroupData(
                  x: entry.key,
                  barsSpace: barWidth * 0.4,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.leftValue,
                      color: AppTheme.primary,
                      width: barWidth,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: entry.value.rightValue,
                      color: AppTheme.tertiary,
                      width: barWidth,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
