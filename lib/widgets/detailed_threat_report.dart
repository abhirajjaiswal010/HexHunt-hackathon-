import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_data_provider.dart';
import '../models/scan_report.dart';
import '../models/threat.dart';

class DetailedThreatReport extends StatelessWidget {
  const DetailedThreatReport({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ScanDataProvider>(
      builder: (context, scanData, _) {
        final currentScan = scanData.currentScan;
        if (currentScan == null) {
          return Center(
            child: Text(
              'No scan data available',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }

        final threats = currentScan.threats;
        final findings = currentScan.findings;
        final vulnerabilityDistribution = currentScan.vulnerabilityDistribution;
        final riskScore = currentScan.riskScore;

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detailed Threat Analysis',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Risk Score: $riskScore',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _getRiskScoreColor(riskScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildVulnerabilityDistribution(vulnerabilityDistribution, theme),
                const SizedBox(height: 24),
                _buildThreatCategories(threats, theme),
                const SizedBox(height: 24),
                _buildDetailedThreatList(threats, findings, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVulnerabilityDistribution(
      Map<String, int> distribution, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vulnerability Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final severity = entry.key;
              final count = entry.value;
              final total = distribution.values.reduce((a, b) => a + b);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          severity,
                          style: TextStyle(
                            color: _getSeverityColor(severity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: total > 0 ? count / total : 0,
                      backgroundColor: _getSeverityColor(severity).withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSeverityColor(severity),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatCategories(List<Threat> threats, ThemeData theme) {
    final categories = _groupThreatsByCategory(threats);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Threat Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key} (${entry.value.length})'),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedThreatList(
      List<Threat> threats, List<Map<String, dynamic>> findings, ThemeData theme) {
    if (threats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No threats detected.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: threats.map((threat) {
        final finding = findings.firstWhere(
          (f) => f['name'] == threat.name || f['type'] == threat.type,
          orElse: () => {},
        );

        return Card(
          color: theme.cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Row(
              children: [
                _getSeverityIcon(threat.severity, theme),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    threat.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Location: ${threat.location}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (threat.description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(threat.description),
                      const SizedBox(height: 16),
                    ],
                    if (finding['details'] != null) ...[
                      Text(
                        'Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(finding['details'].toString()),
                      const SizedBox(height: 16),
                    ],
                    if (threat.recommendation.isNotEmpty) ...[
                      Text(
                        'Recommendation',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(threat.recommendation),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<Threat>> _groupThreatsByCategory(List<Threat> threats) {
    final categories = <String, List<Threat>>{};
    for (final threat in threats) {
      final category = threat.type;
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(threat);
    }
    return categories;
  }

  Widget _getSeverityIcon(String severity, ThemeData theme) {
    IconData icon;
    Color color;

    switch (severity.toLowerCase()) {
      case 'critical':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'high':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'medium':
        icon = Icons.info;
        color = Colors.yellow;
        break;
      case 'low':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
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

  Color _getRiskScoreColor(int score) {
    if (score >= 80) {
      return Colors.red;
    } else if (score >= 60) {
      return Colors.orange;
    } else if (score >= 40) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
}
