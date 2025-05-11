import 'package:flutter/material.dart';
import '../models/scan_report.dart';
import '../services/ml_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CompareScreen extends StatefulWidget {
  final List<ScanReport> reports;

  const CompareScreen({
    super.key,
    required this.reports,
  });

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final MLService _mlService = MLService();
  Map<String, dynamic>? _comparisonResults;
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _analyzeReports();
  }

  Future<void> _analyzeReports() async {
    setState(() => _isLoading = true);
    try {
      final results = await _mlService.compareScans(widget.reports);
      setState(() {
        _comparisonResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing reports: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C2E),
        title: const Text(
          'Compare Scans',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    // Side Navigation for larger screens
                    if (constraints.maxWidth > 800)
                      Container(
                        width: 200,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFF232538),
                              width: 1,
                            ),
                          ),
                        ),
                        child: _buildNavigation(isVertical: true),
                      ),
                    // Main Content Area
                    Expanded(
                      child: Column(
                        children: [
                          // Top Navigation for smaller screens
                          if (constraints.maxWidth <= 800)
                            _buildNavigation(isVertical: false),
                          // Content Area
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _buildSelectedContent(constraints),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNavigation({required bool isVertical}) {
    final items = [
      _NavItem(
        icon: Icons.compare_arrows,
        label: 'Overview',
        index: 0,
      ),
      _NavItem(
        icon: Icons.bug_report,
        label: 'Vulnerabilities',
        index: 1,
      ),
      _NavItem(
        icon: Icons.trending_up,
        label: 'Trends',
        index: 2,
      ),
      _NavItem(
        icon: Icons.recommend,
        label: 'Recommendations',
        index: 3,
      ),
    ];

    if (isVertical) {
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Icon(item.icon, color: Colors.white70),
            title: Text(
              item.label,
              style: const TextStyle(color: Colors.white),
            ),
            selected: _selectedTab == item.index,
            selectedColor: Colors.blue,
            onTap: () => setState(() => _selectedTab = item.index),
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Row(
                children: [
                  Icon(item.icon,
                      size: 18,
                      color: _selectedTab == item.index
                          ? Colors.white
                          : Colors.white70),
                  const SizedBox(width: 8),
                  Text(item.label),
                ],
              ),
              selected: _selectedTab == item.index,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTab = item.index);
                }
              },
              selectedColor: Colors.blue,
              backgroundColor: const Color(0xFF232538),
              labelStyle: TextStyle(
                color:
                    _selectedTab == item.index ? Colors.white : Colors.white70,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedContent(BoxConstraints constraints) {
    switch (_selectedTab) {
      case 0:
        return _buildOverview(constraints);
      case 1:
        return _buildVulnerabilityComparison(constraints);
      case 2:
        return _buildTrends(constraints);
      case 3:
        return _buildRecommendations(constraints);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverview(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 600;
    final reports = widget.reports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildOverviewCard(
              'Total Vulnerabilities',
              _comparisonResults?['total_vulnerabilities'] ?? 0,
              Icons.bug_report,
              Colors.red,
              constraints,
            ),
            _buildOverviewCard(
              'Risk Score Change',
              _comparisonResults?['risk_score_change'] ?? 0,
              Icons.trending_up,
              Colors.orange,
              constraints,
            ),
            _buildOverviewCard(
              'New Issues',
              _comparisonResults?['new_issues'] ?? 0,
              Icons.new_releases,
              Theme.of(context).colorScheme.primary,
              constraints,
            ),
            _buildOverviewCard(
              'Resolved Issues',
              _comparisonResults?['resolved_issues'] ?? 0,
              Icons.check_circle,
              Colors.green,
              constraints,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Key Changes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final change in _comparisonResults?['key_changes'] ?? [])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        change['type'] == 'improvement'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: change['type'] == 'improvement'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          change['description'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, dynamic value, IconData icon,
      Color color, BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 600;
    final cardWidth =
        isWide ? (constraints.maxWidth - 48) / 4 : double.infinity;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF232538),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVulnerabilityComparison(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vulnerability Changes',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWide ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF232538),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const titles = ['Critical', 'High', 'Medium', 'Low'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          titles[value.toInt()],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _createBarGroup(0, widget.reports),
                _createBarGroup(1, widget.reports),
                _createBarGroup(2, widget.reports),
                _createBarGroup(3, widget.reports),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_comparisonResults?['vulnerability_insights'] != null) ...[
          Text(
            'ML Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF232538),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final insight
                    in _comparisonResults!['vulnerability_insights'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          insight['description'],
                          style: const TextStyle(
                              color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  BarChartGroupData _createBarGroup(int x, List<ScanReport> reports) {
    final bars = reports.map((report) {
      final value = report.vulnerabilityDistribution.values.elementAt(x);
      return BarChartRodData(
        toY: value,
        color: x == 0
            ? Colors.red
            : x == 1
                ? Colors.orange
                : x == 2
                    ? Colors.yellow
                    : Colors.green,
        width: 16,
      );
    }).toList();

    return BarChartGroupData(
      x: x,
      barRods: bars,
      showingTooltipIndicators: [0, 1],
    );
  }

  Widget _buildTrends(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Trends',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWide ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF232538),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= widget.reports.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MM/dd')
                              .format(widget.reports[value.toInt()].timestamp),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(widget.reports.length, (index) {
                    return FlSpot(index.toDouble(),
                        widget.reports[index].riskScore.toDouble());
                  }),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_comparisonResults?['trend_analysis'] != null) ...[
          Text(
            'Trend Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF232538),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final trend in _comparisonResults!['trend_analysis'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          trend['direction'] == 'up'
                              ? Icons.trending_up
                              : trend['direction'] == 'down'
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          color: trend['direction'] == 'up'
                              ? Colors.red
                              : trend['direction'] == 'down'
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trend['metric'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trend['analysis'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendations(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ML-Powered Recommendations',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWide ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (_comparisonResults?['recommendations'] != null)
          ...(_comparisonResults!['recommendations'] as List).map((rec) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF232538),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(rec['priority'])
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rec['priority'].toUpperCase(),
                          style: TextStyle(
                            color: _getPriorityColor(rec['priority']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rec['description'],
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  if (rec['steps'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Implementation Steps:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...rec['steps'].map<Widget>((step) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
