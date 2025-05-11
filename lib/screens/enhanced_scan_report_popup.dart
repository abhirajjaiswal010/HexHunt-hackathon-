import 'package:flutter/material.dart';
import '../models/scan_report.dart';
import '../models/threat.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../services/report_service.dart';
import 'package:flutter/foundation.dart';

class EnhancedScanReportPopup extends StatefulWidget {
  final ScanReport report;
  final VoidCallback onClose;

  const EnhancedScanReportPopup({
    Key? key,
    required this.report,
    required this.onClose,
  }) : super(key: key);

  @override
  State<EnhancedScanReportPopup> createState() => _EnhancedScanReportPopupState();
}

class _EnhancedScanReportPopupState extends State<EnhancedScanReportPopup> {
  bool _isExporting = false;

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    try {
      // Get the reports directory path in the main isolate
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      final reportsPath = reportsDir.path;
      // Use compute to run report generation in a background isolate, passing the path
      final filePath = await compute(_generateReportInIsolate, [widget.report, 'pdf', reportsPath]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  static Future<String> _generateReportInIsolate(List<dynamic> args) async {
    final report = args[0] as ScanReport;
    final format = args[1] as String;
    final reportsPath = args[2] as String;
    return await ReportService().generateReport(report, format, customDirectory: reportsPath);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(20),
        color: Theme.of(context).dialogBackgroundColor,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scan Report',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.share, color: Theme.of(context).iconTheme.color),
                            onPressed: _exportReport,
                            tooltip: 'Export Report',
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionHeader('Overview'),
                  _overviewSection(),
                  _sectionHeader('Host Fingerprinting'),
                  _hostFingerprintSection(),
                  _sectionHeader('Open Ports & Services'),
                  _openPortsSection(),
                  _sectionHeader('Vulnerability Insights (CVE Mapping)'),
                  _vulnerabilityInsightsSection(),
                  _sectionHeader('Risk & Threat Classification'),
                  _riskClassificationSection(),
                  _sectionHeader('Subdomain Exposure'),
                  _subdomainExposureSection(),
                  _sectionHeader('Threat Intelligence'),
                  _threatIntelligenceSection(),
                  _sectionHeader('AI Scorecard'),
                  _aiScorecardSection(),
                  _sectionHeader('Formatted Scan Data'),
                  _formattedDataSection(),
                ],
              ),
            ),
            if (_isExporting)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    ),
  );

  Widget _overviewSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Target', widget.report.target),
          _infoRow('Scan Type', widget.report.scanType),
          _infoRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.report.timestamp)),
          _infoRow('Risk Score', widget.report.riskScore.toString()),
          _infoRow('Threats Found', widget.report.threats.length.toString()),
          if (widget.report.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.report.summary, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ],
      ),
    ),
  );

  Widget _hostFingerprintSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.report.ipAddress != null)
            _infoRow('IP Address', widget.report.ipAddress!),
          if (widget.report.dnsRecords != null && widget.report.dnsRecords!.isNotEmpty)
            _infoRow('DNS Records', widget.report.dnsRecords!.join(', ')),
          if (widget.report.scanMetadata['server'] != null)
            _infoRow('Server', widget.report.scanMetadata['server'].toString()),
          if (widget.report.scanMetadata['os'] != null)
            _infoRow('OS', widget.report.scanMetadata['os'].toString()),
          if (widget.report.scanMetadata['headers'] != null) ...[
            (() {
              final headers = widget.report.scanMetadata['headers'];
              if (headers is Map) {
                return _infoRow('Headers', headers.entries.map((e) => '${e.key}: ${e.value}').join(', '));
              } else if (headers is List) {
                return _infoRow('Headers', headers.join(', '));
              } else {
                return const SizedBox.shrink();
              }
            })(),
          ],
          if ((widget.report.ipAddress == null && (widget.report.dnsRecords == null || widget.report.dnsRecords!.isEmpty)))
            Text('No host fingerprinting data available', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    ),
  );

  Widget _openPortsSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: widget.report.openPorts.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.report.openPorts
                  .map((port) => Text(port.toString(), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                  .toList(),
            )
          : Text('No open ports detected', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
    ),
  );

  Widget _vulnerabilityInsightsSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: widget.report.threats.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.report.threats
                  .map((threat) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${threat.name} (${threat.severity})', style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color)),
                            if (threat.type.isNotEmpty)
                              Text('Type: ${threat.type}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                            if (threat.location.isNotEmpty)
                              Text('Location: ${threat.location}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                            if (threat.recommendation.isNotEmpty)
                              Text('Recommendation: ${threat.recommendation}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                            if (threat.description.isNotEmpty)
                              Text(threat.description, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                          ],
                        ),
                      ))
                  .toList())
          : Text('No vulnerabilities detected', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
    ),
  );

  Widget _riskClassificationSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vulnerability Distribution:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color)),
          ...widget.report.vulnerabilityDistribution.entries.map((entry) => Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  color: entry.key.toLowerCase() == 'critical'
                      ? Colors.red
                      : entry.key.toLowerCase() == 'high'
                          ? Colors.orange
                          : entry.key.toLowerCase() == 'medium'
                              ? Colors.yellow
                              : Colors.green,
                ),
              )),
        ],
      ),
    ),
  );

  Widget _subdomainExposureSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: (widget.report.subdomains != null && widget.report.subdomains!.isNotEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.report.subdomains!
                  .map((sub) => Text(sub, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                  .toList(),
            )
          : Text('No subdomain data available', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
    ),
  );

  Widget _threatIntelligenceSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: (widget.report.threatIntelligence != null && widget.report.threatIntelligence!.isNotEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.report.threatIntelligence!.entries
                  .map((e) => Text('${e.key}: ${e.value}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                  .toList(),
            )
          : Text('No threat intelligence data available', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
    ),
  );

  Widget _aiScorecardSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: (widget.report.aiScorecard != null && widget.report.aiScorecard!.isNotEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.report.aiScorecard!.entries
                  .map((e) => Text('${e.key}: ${e.value}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                  .toList(),
            )
          : Text('No AI threat scorecard available', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
    ),
  );

  Widget _formattedDataSection() => Card(
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formatted Scan Data:', style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color)),
          const SizedBox(height: 8),
          Text(
            ReportService().summarizeRawScanData(widget.report.toJson()),
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          if (widget.report.scanMetadata['headers'] != null) ...[
            const SizedBox(height: 16),
            Text('Server Headers (Explained):', style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color)),
            const SizedBox(height: 8),
            Text(
              ReportService().explainServerHeaders(widget.report.scanMetadata['headers']),
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        ),
      ],
    ),
  );
}
