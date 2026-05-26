import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SessionTypeBreakdownChart extends StatelessWidget {
  const SessionTypeBreakdownChart({super.key, required this.sessionTypeCounts});

  final Map<String, int> sessionTypeCounts;

  static const _typeColors = {
    'mobility': Color(0xFF7DD3C0),
    'cardio': Color(0xFFA78BDA),
    'breathing': Color(0xFFE8C87A),
  };

  static const _typeLabels = {
    'mobility': 'Mobilità',
    'cardio': 'Cardio',
    'breathing': 'Respirazione',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = sessionTypeCounts.values.fold(0, (sum, count) => sum + count);

    final sections = <PieChartSectionData>[];
    sessionTypeCounts.forEach((type, count) {
      final pct = total > 0 ? count / total * 100 : 0.0;
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: _typeColors[type] ?? colorScheme.onSurface,
          radius: 48,
          title: '${pct.toStringAsFixed(0)}%',
          titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 112,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sessionTypeCounts.keys.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _typeColors[type] ?? colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _typeLabels[type] ?? type,
                        style: Theme.of(context).textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
