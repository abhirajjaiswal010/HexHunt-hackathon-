import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/scan_data_provider.dart';

class ThreatOverviewChart extends StatelessWidget {
  final String? selectedTarget;
  const ThreatOverviewChart({super.key, this.selectedTarget});

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final textColor = isLightMode ? const Color(0xFF424242) : Colors.white;
    final secondaryTextColor = isLightMode ? const Color(0xFF757575) : Colors.white60;

    return Consumer<ScanDataProvider>(
      builder: (context, scanData, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Threat Overview',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.filter_list, color: secondaryTextColor),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: secondaryTextColor),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 8.0, left: 8.0, right: 8.0, bottom: 16.0),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final now = DateTime.now();
                            final days = List.generate(
                                7, (i) => now.subtract(Duration(days: 6 - i)));
                            if (value.toInt() >= 0 &&
                                value.toInt() < days.length) {
                              final day = days[value.toInt()];
                              final label = [
                                'Sun',
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat'
                              ][day.weekday - 1];
                              return Text(
                                label,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0.0,
                    maxY: () {
                      final data =
                          scanData.getDailyThreatDataForTarget(selectedTarget);
                      final max = data.reduce((a, b) => a > b ? a : b);
                      final nextMultipleOf5 = ((max + 4) ~/ 5) * 5;
                      final cappedMaxY = nextMultipleOf5 > 25
                          ? 25.0
                          : nextMultipleOf5.toDouble();
                      return cappedMaxY < 5 ? 5.0 : cappedMaxY;
                    }(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          scanData
                              .getDailyThreatDataForTarget(selectedTarget)
                              .length,
                          (index) {
                            // Compute 3-day moving average
                            final data = scanData
                                .getDailyThreatDataForTarget(selectedTarget);
                            int i = 6 - index;
                            int start = (i - 2) < 0 ? 0 : (i - 2);
                            double sum = 0;
                            int count = 0;
                            for (int j = start; j <= i; j++) {
                              sum += data[j];
                              count++;
                            }
                            double avg = count > 0 ? sum / count : 0;
                            return FlSpot(index.toDouble(), avg);
                          },
                        ),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: isLightMode 
                            ? const Color(0xFFEEEEEE).withOpacity(0.9)
                            : const Color(0xFF424242).withOpacity(0.9),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toInt()} threats',
                              TextStyle(
                                color: isLightMode ? Colors.black87 : Colors.white,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
