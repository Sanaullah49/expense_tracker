import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartWidget extends StatelessWidget {
  final List<LineChartDataSet> dataSets;
  final List<String>? bottomLabels;
  final bool showGridLines;
  final bool showDots;
  final bool curved;
  final bool filled;
  final double? minY;
  final double? maxY;

  const LineChartWidget({
    super.key,
    required this.dataSets,
    this.bottomLabels,
    this.showGridLines = true,
    this.showDots = false,
    this.curved = true,
    this.filled = true,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.grey.shade800,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataSet = dataSets[spot.barIndex];
                return LineTooltipItem(
                  '${dataSet.label}\n\$${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: dataSet.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: showGridLines,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: bottomLabels != null,
              getTitlesWidget: (value, meta) {
                if (bottomLabels == null ||
                    value.toInt() >= bottomLabels!.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    bottomLabels![value.toInt()],
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
        minY: minY,
        maxY: maxY,
        lineBarsData: dataSets.map((dataSet) {
          return LineChartBarData(
            spots: dataSet.spots,
            isCurved: curved,
            color: dataSet.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: showDots),
            belowBarData: filled
                ? BarAreaData(
                    show: true,
                    color: dataSet.color.withValues(alpha: 0.15),
                  )
                : BarAreaData(show: false),
          );
        }).toList(),
      ),
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

class LineChartDataSet {
  final String label;
  final List<FlSpot> spots;
  final Color color;

  LineChartDataSet({
    required this.label,
    required this.spots,
    required this.color,
  });
}
