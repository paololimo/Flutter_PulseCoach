import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CompletionRateChart extends StatelessWidget {
  const CompletionRateChart({
    super.key,
    required this.completedCount,
    required this.abandonedCount,
  });

  final int completedCount;
  final int abandonedCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = completedCount + abandonedCount;
    final completionPct = total > 0 ? completedCount / total * 100 : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 60,
            sections: [
              PieChartSectionData(
                value: completedCount.toDouble(),
                color: colorScheme.primary,
                radius: 24,
                showTitle: false,
              ),
              PieChartSectionData(
                value: abandonedCount.toDouble(),
                color: colorScheme.surfaceContainerHighest,
                radius: 24,
                showTitle: false,
              ),
            ],
          ),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        ),
        Text(
          '${completionPct.toStringAsFixed(0)}%',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
        ),
      ],
    );
  }
}
