import 'package:flutter/material.dart';
import '../models/detailed_scan_report.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DetailedScanReportScreen extends StatelessWidget {
  final DetailedScanReport report;

  const DetailedScanReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Detailed Scan Report',
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () {
              // TODO: Implement export functionality
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Details',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target: ${report.target}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      'Scan Type: ${report.scanType}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(report.timestamp)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vulnerabilities',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...report.vulnerabilities.map((vulnerability) => Card(
              color: theme.cardColor,
              child: ListTile(
                title: Text(
                  vulnerability.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  vulnerability.description,
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: Text(
                  vulnerability.severity,
                  style: TextStyle(
                    color: _getVulnerabilityColor(vulnerability.cvssScore),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )),
            const Divider(height: 32),
            _buildHostInformation(),
            const Divider(height: 32),
            _buildPortScanResults(),
            const Divider(height: 32),
            _buildVulnerabilityAnalysis(),
            const Divider(height: 32),
            _buildThreatIntelligence(),
            const Divider(height: 32),
            _buildAnomalyDetection(),
            const Divider(height: 32),
            _buildSummary(),
            const Divider(height: 32),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicMetadata() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Scan Information',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Scan ID', report.id),
            _buildInfoRow('Start Time',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(report.startTime)),
            _buildInfoRow('End Time',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(report.endTime)),
            _buildInfoRow('Duration',
                '${report.scanDuration.inMinutes}m ${report.scanDuration.inSeconds % 60}s'),
            _buildInfoRow('Scan Type', report.scanType),
            _buildInfoRow('Scanner Version', report.scannerVersion),
          ],
        ),
      ),
    );
  }

  Widget _buildHostInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host Information',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('IP Address', report.hostInfo.ipAddress),
            if (report.hostInfo.hostname != null)
              _buildInfoRow('Hostname', report.hostInfo.hostname!),
            if (report.hostInfo.operatingSystem != null)
              _buildInfoRow(
                  'Operating System', report.hostInfo.operatingSystem!),
            if (report.hostInfo.geoLocation != null)
              _buildInfoRow('Location', report.hostInfo.geoLocation!),
            if (report.hostInfo.ispInfo != null)
              _buildInfoRow('ISP', report.hostInfo.ispInfo!),
          ],
        ),
      ),
    );
  }

  Widget _buildPortScanResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Port Scan Results',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...report.portScanResults.map((port) => ListTile(
                  title: Text('Port ${port.portNumber} (${port.protocol})'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service: ${port.serviceName}'),
                      if (port.serviceVersion != null)
                        Text('Version: ${port.serviceVersion}'),
                      Text('Status: ${port.status}'),
                      if (port.detectedTechnology != null)
                        Text('Technology: ${port.detectedTechnology}'),
                    ],
                  ),
                  leading: Icon(
                    port.status.toLowerCase() == 'open'
                        ? Icons.warning
                        : Icons.check_circle,
                    color: port.status.toLowerCase() == 'open'
                        ? Colors.red
                        : Colors.green,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildVulnerabilityAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vulnerability Analysis',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildVulnerabilityScore(),
            const SizedBox(height: 16),
            Text('CVE Findings:'),
            ...report.vulnerabilityAnalysis.cveIds.map((cveId) {
              final score =
                  report.vulnerabilityAnalysis.cvssScores[cveId] ?? 0.0;
              final description =
                  report.vulnerabilityAnalysis.cveDescriptions[cveId] ?? '';
              return ListTile(
                title: Text(cveId),
                subtitle: Text(description),
                trailing: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCvssColor(score),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVulnerabilityScore() {
    return Container(
      height: 100,
      width: 100,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: _getVulnerabilityColor(
                      report.vulnerabilityAnalysis.vulnerabilityScore),
                  value: report.vulnerabilityAnalysis.vulnerabilityScore,
                  title: '',
                  radius: 40,
                ),
                PieChartSectionData(
                  color: Colors.grey.shade300,
                  value: 10 - report.vulnerabilityAnalysis.vulnerabilityScore,
                  title: '',
                  radius: 40,
                ),
              ],
              sectionsSpace: 0,
              centerSpaceRadius: 30,
            ),
          ),
          Center(
            child: Text(
              '${(report.vulnerabilityAnalysis.vulnerabilityScore * 10).toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatIntelligence() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threat Intelligence',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                'IP Reputation', report.threatIntelligence.ipReputation),
            _buildInfoRow('Blacklisted',
                report.threatIntelligence.isBlacklisted ? 'Yes' : 'No'),
            if (report
                .threatIntelligence.knownMaliciousActivities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Known Malicious Activities:'),
              ...report.threatIntelligence.knownMaliciousActivities
                  .map((activity) => ListTile(
                        leading:
                            const Icon(Icons.warning, color: Colors.orange),
                        title: Text(activity),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyDetection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anomaly Detection',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (report.anomalyDetection.flaggedBehaviors.isNotEmpty) ...[
              Text('Flagged Behaviors:'),
              ...report.anomalyDetection.flaggedBehaviors
                  .map((behavior) => ListTile(
                        leading:
                            const Icon(Icons.error_outline, color: Colors.red),
                        title: Text(behavior),
                      )),
            ],
            const SizedBox(height: 16),
            Text('AI Analysis:'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(report.anomalyDetection.aiAnalysis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Total IPs Scanned', '${report.totalIpsScanned}'),
            _buildInfoRow('Open Ports', '${report.totalOpenPorts}'),
            _buildInfoRow('Critical Vulnerabilities',
                '${report.criticalVulnerabilities}'),
            _buildInfoRow('Hosts with Exploits', '${report.hostsWithExploits}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...report.recommendations.map((rec) => ExpansionTile(
                  title: Text(rec.category),
                  subtitle: Text(
                    rec.priority,
                    style: TextStyle(
                      color: _getPriorityColor(rec.priority),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rec.description),
                          const SizedBox(height: 8),
                          ...rec.steps
                              .map((step) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(child: Text(step)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getVulnerabilityColor(double score) {
    if (score >= 9) return Colors.red;
    if (score >= 7) return Colors.orange;
    if (score >= 4) return Colors.yellow;
    return Colors.green;
  }

  Color _getCvssColor(double score) {
    if (score >= 9) return Colors.red;
    if (score >= 7) return Colors.orange;
    if (score >= 4) return Colors.yellow;
    return Colors.green;
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }
}
