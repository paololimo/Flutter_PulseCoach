import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';

class MinutesPerWeekChart extends StatelessWidget {
  const MinutesPerWeekChart({super.key, required this.minutesPerWeek});

  final List<WeeklyMinutes> minutesPerWeek;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < minutesPerWeek.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: minutesPerWeek[i].totalMinutes.toDouble(),
              color: colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= minutesPerWeek.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  minutesPerWeek[index].weekLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }
}
