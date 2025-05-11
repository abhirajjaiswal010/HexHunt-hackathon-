import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/scan_report.dart';
import 'package:intl/intl.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  Future<String> generateReport(ScanReport report, String format, {String? customDirectory}) async {
    final directoryPath = customDirectory ?? (await getApplicationDocumentsDirectory()).path;
    final reportsDir = Directory('$directoryPath/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'scan_report_${report.target.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$timestamp';

    switch (format.toLowerCase()) {
      case 'pdf':
        return _generatePdfReport(report, reportsDir.path, fileName);
      case 'json':
        return _generateJsonReport(report, reportsDir.path, fileName);
      case 'html':
        return _generateHtmlReport(report, reportsDir.path, fileName);
      case 'csv':
        return _generateCsvReport(report, reportsDir.path, fileName);
      default:
        throw ArgumentError('Unsupported format: $format');
    }
  }

  Future<String> _generatePdfReport(ScanReport report, String directory, String fileName) async {
    try {
      final pdf = pw.Document();
      const maxFindings = 50;
      const maxRawDataLength = 1000;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildHeader(report),
            _buildOverviewSection(report),
            _buildHostFingerprintSection(report),
            _buildOpenPortsSection(report),
            _buildVulnerabilityInsightsSectionLimited(report, maxFindings),
            _buildRiskClassificationSection(report),
            _buildSubdomainExposureSection(report),
            _buildThreatIntelligenceSection(report),
            _buildAiScorecardSection(report),
            _buildExportSectionTruncated(report, maxRawDataLength),
          ],
        ),
      );

      final file = File('$directory/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('Error generating PDF report: $e');
      throw Exception('Failed to generate PDF report: $e');
    }
  }

  pw.Widget _buildHeader(ScanReport report) {
    return pw.Header(
      level: 0,
      child: pw.Text(
        'Scan Report',
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildOverviewSection(ScanReport report) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Overview'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Target', report.target),
                _buildInfoRow('Scan Type', report.scanType),
                _buildInfoRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(report.timestamp)),
                _buildInfoRow('Risk Score', report.riskScore.toString()),
                _buildInfoRow('Threats Found', report.threats.length.toString()),
                if (report.summary.isNotEmpty)
                  pw.Text(report.summary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHostFingerprintSection(ScanReport report) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Host Fingerprinting'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (report.ipAddress != null)
                  _buildInfoRow('IP Address', report.ipAddress!),
                if (report.dnsRecords != null && report.dnsRecords!.isNotEmpty)
                  _buildInfoRow('DNS Records', report.dnsRecords!.join(', ')),
                if (report.scanMetadata['server'] != null)
                  _buildInfoRow('Server', report.scanMetadata['server'].toString()),
                if (report.scanMetadata['os'] != null)
                  _buildInfoRow('OS', report.scanMetadata['os'].toString()),
                if (report.scanMetadata['headers'] != null) ...[
                  (() {
                    final headers = report.scanMetadata['headers'];
                    if (headers is Map) {
                      return _buildInfoRow('Headers', headers.entries.map((e) => '${e.key}: ${e.value}').join(', '));
                    } else if (headers is List) {
                      return _buildInfoRow('Headers', headers.join(', '));
                    } else {
                      return pw.SizedBox.shrink();
                    }
                  })(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildOpenPortsSection(ScanReport report) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Open Ports & Services'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: report.openPorts.isNotEmpty
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: report.openPorts.map((port) => pw.Text(port.toString())).toList(),
                  )
                : pw.Text('No open ports detected'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVulnerabilityInsightsSectionLimited(ScanReport report, int maxFindings) {
    final limitedThreats = report.threats.take(maxFindings).toList();
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Vulnerability Insights (CVE Mapping)'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: limitedThreats.isNotEmpty
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      ...limitedThreats.map((threat) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${threat.name} (${threat.severity})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          if (threat.type.isNotEmpty)
                            pw.Text('Type: ${threat.type}'),
                          if (threat.location.isNotEmpty)
                            pw.Text('Location: ${threat.location}'),
                          if (threat.recommendation.isNotEmpty)
                            pw.Text('Recommendation: ${threat.recommendation}'),
                          if (threat.description.isNotEmpty)
                            pw.Text(threat.description),
                          pw.SizedBox(height: 10),
                        ],
                      )),
                      if (report.threats.length > maxFindings)
                        pw.Text('...and more. Export as JSON for full details.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                    ],
                  )
                : pw.Text('No vulnerabilities detected'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRiskClassificationSection(ScanReport report) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Risk & Threat Classification'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Vulnerability Distribution:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...report.vulnerabilityDistribution.entries.map((entry) => pw.Text('${entry.key}: ${entry.value}')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSubdomainExposureSection(ScanReport report) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Subdomain Exposure'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: (report.subdomains != null && report.subdomains!.isNotEmpty)
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: report.subdomains!.map((sub) => pw.Text(sub)).toList(),
                  )
                : pw.Text('No subdomain data available'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildThreatIntelligenceSection(ScanReport report) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Threat Intelligence Lookup'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: (report.threatIntelligence != null && report.threatIntelligence!.isNotEmpty)
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: report.threatIntelligence!.entries.map((e) => pw.Text('${e.key}: ${e.value}')).toList(),
                  )
                : pw.Text('No threat intelligence data available'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAiScorecardSection(ScanReport report) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('AI Threat Scorecard'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: (report.aiScorecard != null && report.aiScorecard!.isNotEmpty)
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: report.aiScorecard!.entries.map((e) => pw.Text('${e.key}: ${e.value}')).toList(),
                  )
                : pw.Text('No AI threat scorecard available'),
          ),
        ],
      ),
    );
  }

  // NLP-style summary for raw scan data
  String summarizeRawScanData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Format target information
    if (data.containsKey('target')) {
      buffer.writeln('Target: ${data['target']}');
    }
    
    // Format scan type and timestamp
    if (data.containsKey('scanType')) {
      buffer.writeln('Scan Type: ${data['scanType']}');
    }
    if (data.containsKey('timestamp')) {
      final timestamp = DateTime.parse(data['timestamp'].toString());
      buffer.writeln('Timestamp: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp)}');
    }
    
    // Format vulnerability distribution
    if (data.containsKey('vulnerabilityDistribution')) {
      final vulnDist = data['vulnerabilityDistribution'] as Map<String, dynamic>;
      buffer.writeln('\nVulnerability Distribution:');
      vulnDist.forEach((severity, count) {
        buffer.writeln('- $severity: $count');
      });
    }
    
    // Format findings
    if (data.containsKey('findings') && data['findings'] is List) {
      final findings = data['findings'] as List;
      if (findings.isNotEmpty) {
        buffer.writeln('\nKey Findings:');
        for (var i = 0; i < findings.length && i < 5; i++) {
          final finding = findings[i];
          buffer.writeln('- ${finding['name'] ?? 'Unknown'} (${finding['severity'] ?? 'Unknown'}): ${finding['description'] ?? 'No description'}');
        }
        if (findings.length > 5) {
          buffer.writeln('... and ${findings.length - 5} more findings');
        }
      }
    }
    
    // Format open ports
    if (data.containsKey('openPorts') && data['openPorts'] is List) {
      final ports = data['openPorts'] as List;
      if (ports.isNotEmpty) {
        buffer.writeln('\nOpen Ports:');
        for (var i = 0; i < ports.length && i < 10; i++) {
          final port = ports[i];
          buffer.writeln('- Port ${port['port'] ?? 'Unknown'}: ${port['service'] ?? 'Unknown service'}');
        }
        if (ports.length > 10) {
          buffer.writeln('... and ${ports.length - 10} more ports');
        }
      }
    }
    
    // Format risk score
    if (data.containsKey('riskScore')) {
      buffer.writeln('\nRisk Score: ${data['riskScore']}/100');
    }
    
    // Format summary
    if (data.containsKey('summary')) {
      buffer.writeln('\nSummary:');
      buffer.writeln(data['summary']);
    }
    
    return buffer.toString().trim();
  }

  // NLP-style explanation for server headers
  String explainServerHeaders(dynamic headers) {
    if (headers == null) return 'No server headers available.';
    final buffer = StringBuffer();
    Map<String, String> headerMap = {};
    if (headers is Map) {
      headerMap = headers.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (headers is List) {
      for (var h in headers) {
        if (h is String && h.contains(':')) {
          final parts = h.split(':');
          headerMap[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      }
    }
    if (headerMap.isEmpty) return 'No server headers available.';
    for (final entry in headerMap.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
      final explanation = _headerExplanation(entry.key, entry.value);
      if (explanation.isNotEmpty) {
        buffer.writeln('  → $explanation');
      }
    }
    return buffer.toString().trim();
  }

  String _headerExplanation(String key, String value) {
    switch (key.toLowerCase()) {
      case 'x-frame-options':
        if (value.toLowerCase().contains('deny')) return 'Prevents the site from being embedded in a frame (protects against clickjacking).';
        if (value.toLowerCase().contains('sameorigin')) return 'Allows framing only from the same origin.';
        return 'Controls whether the site can be embedded in a frame.';
      case 'x-xss-protection':
        return 'Enables cross-site scripting (XSS) filter in browsers.';
      case 'x-content-type-options':
        return 'Prevents MIME-sniffing, reducing exposure to drive-by downloads.';
      case 'strict-transport-security':
        return 'Forces browsers to use HTTPS, improving security.';
      case 'content-security-policy':
        return 'Defines approved sources of content, helps prevent XSS attacks.';
      case 'server':
        return 'Indicates the software used by the origin server.';
      case 'set-cookie':
        return 'Sets cookies; check for HttpOnly and Secure flags for best security.';
      case 'access-control-allow-origin':
        return 'Specifies which origins can access resources (CORS policy).';
      default:
        return '';
    }
  }

  // Use these summaries in the PDF export
  pw.Widget _buildExportSectionTruncated(ScanReport report, int maxRawDataLength) {
    final rawJson = report.toJson();
    final summary = summarizeRawScanData(rawJson);
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Exported Logs / Raw Scan Data (Summary)'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(summary.isNotEmpty ? summary : 'No summary available.'),
              ],
            ),
          ),
          if (rawJson['scanMetadata'] != null && rawJson['scanMetadata']['headers'] != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Server Headers (Explained):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(explainServerHeaders(rawJson['scanMetadata']['headers'])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  Future<String> _generateJsonReport(ScanReport report, String directory, String fileName) async {
    final file = File('$directory/$fileName.json');
    await file.writeAsString(report.toJson().toString());
    return file.path;
  }

  Future<String> _generateHtmlReport(ScanReport report, String directory, String fileName) async {
    final file = File('$directory/$fileName.html');
    await file.writeAsString('''
      <html>
        <head>
          <title>Scan Report</title>
          <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .section { margin: 20px 0; }
            .header { font-size: 24px; font-weight: bold; }
            .subheader { font-size: 18px; font-weight: bold; margin: 10px 0; }
            .info-row { margin: 5px 0; }
            .label { font-weight: bold; display: inline-block; width: 120px; }
          </style>
        </head>
        <body>
          <div class="header">Scan Report</div>
          <div class="section">
            <div class="subheader">Overview</div>
            <div class="info-row"><span class="label">Target:</span> ${report.target}</div>
            <div class="info-row"><span class="label">Scan Type:</span> ${report.scanType}</div>
            <div class="info-row"><span class="label">Timestamp:</span> ${DateFormat('yyyy-MM-dd HH:mm:ss').format(report.timestamp)}</div>
            <div class="info-row"><span class="label">Risk Score:</span> ${report.riskScore}</div>
            <div class="info-row"><span class="label">Threats Found:</span> ${report.threats.length}</div>
          </div>
          <div class="section">
            <div class="subheader">Vulnerabilities</div>
            ${report.threats.map((threat) => '''
              <div class="info-row">
                <div><strong>${threat.name}</strong> (${threat.severity})</div>
                <div>Type: ${threat.type}</div>
                <div>Location: ${threat.location}</div>
                <div>Recommendation: ${threat.recommendation}</div>
                <div>${threat.description}</div>
              </div>
            ''').join('')}
          </div>
        </body>
      </html>
    ''');
    return file.path;
  }

  Future<String> _generateCsvReport(ScanReport report, String directory, String fileName) async {
    final file = File('$directory/$fileName.csv');
    final csv = StringBuffer();
    
    // Add header
    csv.writeln('Target,Scan Type,Timestamp,Risk Score,Threats Found');
    
    // Add main data
    csv.writeln('${report.target},${report.scanType},${DateFormat('yyyy-MM-dd HH:mm:ss').format(report.timestamp)},${report.riskScore},${report.threats.length}');
    
    // Add threats
    csv.writeln('\nThreats');
    csv.writeln('Name,Severity,Type,Location,Recommendation,Description');
    for (var threat in report.threats) {
      csv.writeln('${threat.name},${threat.severity},${threat.type},${threat.location},${threat.recommendation},${threat.description}');
    }
    
    await file.writeAsString(csv.toString());
    return file.path;
  }

  Future<List<ScanReport>> loadReports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      if (!await reportsDir.exists()) {
        return [];
      }

      final reports = <ScanReport>[];
      await for (final file in reportsDir.list()) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content);
            if (json != null) {
              reports.add(ScanReport.fromJson(json));
            }
          } catch (e) {
            print('Error loading report ${file.path}: $e');
            // Continue loading other reports even if one fails
            continue;
          }
        }
      }

      return reports..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading reports: $e');
      return [];
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      if (!await reportsDir.exists()) {
        return;
      }

      await for (final file in reportsDir.list()) {
        if (file is File &&
            (file.path.contains(reportId) &&
                (file.path.endsWith('.json') || file.path.endsWith('.html')))) {
          try {
            await file.delete();
          } catch (e) {
            print('Error deleting report file ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      print('Error during report deletion: $e');
      rethrow;
    }
  }
}
