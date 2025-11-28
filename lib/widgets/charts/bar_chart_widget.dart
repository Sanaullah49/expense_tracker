import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class BarChartWidget extends StatelessWidget {
  final List<BarChartItem> items;
  final bool showGridLines;
  final bool animate;
  final double barWidth;
  final double maxY;

  const BarChartWidget({
    super.key,
    required this.items,
    this.showGridLines = true,
    this.animate = true,
    this.barWidth = 22,
    this.maxY = 0,
  });

  @override
  Widget build(BuildContext context) {
    final calculatedMaxY = maxY > 0
        ? maxY
        : items.fold<double>(0, (max, item) {
                final itemMax = item.value > item.secondValue
                    ? item.value
                    : item.secondValue;
                return itemMax > max ? itemMax : max;
              }) *
              1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: calculatedMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.grey.shade800,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = items[groupIndex];
              final value = rodIndex == 0 ? item.value : item.secondValue;
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n\$${value.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= items.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    items[value.toInt()].label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showGridLines,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  _formatValue(value),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: showGridLines,
          drawVerticalLine: false,
          horizontalInterval: calculatedMaxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        barGroups: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.value,
                color: item.color ?? AppColors.income,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              if (item.secondValue > 0)
                BarChartRodData(
                  toY: item.secondValue,
                  color: item.secondColor ?? AppColors.expense,
                  width: barWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class BarChartItem {
  final String label;
  final double value;
  final double secondValue;
  final Color? color;
  final Color? secondColor;

  BarChartItem({
    required this.label,
    required this.value,
    this.secondValue = 0,
    this.color,
    this.secondColor,
  });
}
