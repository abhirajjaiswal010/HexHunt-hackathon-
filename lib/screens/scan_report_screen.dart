import 'package:flutter/material.dart';
import '../models/scan_report.dart';
import '../services/report_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanReportScreen extends StatefulWidget {
  final ScanReport report;

  const ScanReportScreen({
    super.key,
    required this.report,
  });

  @override
  State<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen> {
  final ReportService _reportService = ReportService();
  bool _isGenerating = false;
  String? _reportPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C2E),
        title: const Text(
          'Scan Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildDownloadButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 24),
            _buildVulnerabilitySection(),
            const SizedBox(height: 24),
            _buildDetailedFindings(),
            const SizedBox(height: 24),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return PopupMenuButton<String>(
      onSelected: _generateReport,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'pdf',
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Download as PDF'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'html',
          child: ListTile(
            leading: Icon(Icons.html),
            title: Text('Download as HTML'),
          ),
        ),
      ],
      icon: const Icon(Icons.download, color: Colors.white),
    );
  }

  Future<void> _generateReport(String format) async {
    try {
      setState(() {
        _isGenerating = true;
      });

      // Ensure reports directory exists
      final appDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDir.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final filePath =
          await _reportService.generateReport(widget.report, format);

      setState(() {
        _reportPath = filePath;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated successfully'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openReport(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error generating report: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReportHeader() {
    return Card(
      color: const Color(0xFF232538),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Target: ${widget.report.target}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan Date: ${_formatDate(widget.report.timestamp)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      color: const Color(0xFF232538),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRiskScoreIndicator(),
            const SizedBox(height: 16),
            _buildVulnerabilitySummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreIndicator() {
    final color = _getRiskColor(widget.report.riskScore);
    return Row(
      children: [
        const Text(
          'Risk Score: ',
          style: TextStyle(color: Colors.white70),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.report.riskScore.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVulnerabilitySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.report.vulnerabilityDistribution.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${entry.key}:',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                entry.value.toString(),
                style: TextStyle(
                  color: _getSeverityColor(entry.key),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVulnerabilitySection() {
    return Card(
      color: const Color(0xFF232538),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vulnerability Distribution',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildVulnerabilityChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildVulnerabilityChart() {
    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.report.vulnerabilityDistribution.entries.map((entry) {
          final percentage =
              (entry.value / widget.report.findings.length) * 100;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: percentage * 1.5,
                color: _getSeverityColor(entry.key),
              ),
              const SizedBox(height: 8),
              Text(
                entry.key,
                style: TextStyle(
                  color: _getSeverityColor(entry.key),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${entry.value}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedFindings() {
    return Card(
      color: const Color(0xFF232538),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Findings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.report.findings
                .map((finding) => _buildFindingCard(finding)),
          ],
        ),
      ),
    );
  }

  Widget _buildFindingCard(Map<String, dynamic> finding) {
    return Card(
      color: const Color(0xFF2A2D3E),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getSeverityColor(finding['severity']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    finding['severity'],
                    style: TextStyle(
                      color: _getSeverityColor(finding['severity']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finding['title'],
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
              finding['description'],
              style: const TextStyle(color: Colors.white70),
            ),
            if (finding['recommendation'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Recommendation:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                finding['recommendation'],
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      color: const Color(0xFF232538),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.report.recommendations
                .map((rec) => _buildRecommendationCard(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Card(
      color: const Color(0xFF2A2D3E),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recommendation['description'],
              style: const TextStyle(color: Colors.white70),
            ),
            if (recommendation['priority'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(recommendation['priority'])
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Priority: ${recommendation['priority']}',
                  style: TextStyle(
                    color: _getSeverityColor(recommendation['priority']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openReport(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the report'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Color _getRiskColor(int score) {
    if (score >= 80) return Colors.red;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.yellow;
    if (score >= 20) return Colors.green;
    return Colors.blue;
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
        return Colors.blue;
    }
  }
}
