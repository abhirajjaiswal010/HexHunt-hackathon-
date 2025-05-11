import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_data_provider.dart';
import '../models/scan_report.dart';
import '../services/report_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ReportService _reportService = ReportService();
  bool _isLoading = false;
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();
  List<ScanReport> _selectedScans = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ScanReport> _getFilteredReports(List<ScanReport> reports) {
    return reports.where((report) {
      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!report.target.toLowerCase().contains(searchTerm) &&
            !report.scanType.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }

      // Apply type filter
      if (_selectedFilter != 'all') {
        return report.scanType == _selectedFilter;
      }

      return true;
    }).toList();
  }

  Future<void> _viewReport(ScanReport report) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportPath =
          '${directory.path}/reports/scan_${report.id}_${DateFormat('yyyyMMdd_HHmmss').format(report.timestamp)}';

      final htmlFile = File('$reportPath.html');
      final pdfFile = File('$reportPath.pdf');

      if (await htmlFile.exists()) {
        await _openFile(htmlFile.path);
      } else if (await pdfFile.exists()) {
        await _openFile(pdfFile.path);
      } else {
        // Generate a new report if it doesn't exist
        final path = await _reportService.generateReport(report, 'html');
        await _openFile(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error viewing report: $e')),
        );
      }
    }
  }

  Future<void> _openFile(String path) async {
    final uri = Uri.file(path);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the report')),
        );
      }
    }
  }

  Future<void> _deleteReport(ScanReport report) async {
    try {
      final scanData = Provider.of<ScanDataProvider>(context, listen: false);
      await scanData.removeScan(report.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting report: $e')),
        );
      }
    }
  }

  Future<void> _exportReport(ScanReport report) async {
    try {
      setState(() => _isLoading = true);
      
      // Generate the report
      final path = await _reportService.generateReport(report, 'pdf');
      
      // Get the downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Create a timestamp for the filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'threat_analysis_${report.id}_$timestamp.pdf';
      final targetPath = '${downloadsDir.path}/$fileName';

      // Copy the file to downloads directory
      await File(path).copy(targetPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully to: $targetPath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openFile(targetPath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Scan History',
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          if (_selectedScans.isNotEmpty)
            Text(
              '${_selectedScans.length}/2 selected',
              style: theme.textTheme.bodyMedium,
            ),
          IconButton(
            icon: Icon(
              Icons.compare_arrows,
              color: _selectedScans.length == 2
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withOpacity(0.5),
            ),
            onPressed: _selectedScans.length == 2
                ? () => _showComparisonDialog(context)
                : null,
          ),
        ],
      ),
      body: Consumer<ScanDataProvider>(
        builder: (context, scanData, child) {
          final reports = scanData.scanHistory;
          final filteredReports = _getFilteredReports(reports);
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search scans...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'url', child: Text('Web')),
                        DropdownMenuItem(value: 'ip', child: Text('IP')),
                        DropdownMenuItem(value: 'system', child: Text('System')),
                        DropdownMenuItem(value: 'network', child: Text('Network')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedFilter = value!);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredReports.isEmpty
                        ? Center(
                            child: Text(
                              'No scan reports found',
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              final isSelected = _selectedScans.contains(report);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          if (_selectedScans.length < 2) {
                                            _selectedScans.add(report);
                                          }
                                        } else {
                                          _selectedScans.remove(report);
                                        }
                                      });
                                    },
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        report.scanType == 'url'
                                            ? Icons.link
                                            : report.scanType == 'ip'
                                                ? Icons.lan
                                                : Icons.computer,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              report.target,
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Scan Type: ${report.scanType}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(report.timestamp)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.visibility, color: theme.colorScheme.primary),
                                        onPressed: () => _viewReport(report),
                                        tooltip: 'View Report',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.download, color: theme.colorScheme.primary),
                                        onPressed: () => _exportReport(report),
                                        tooltip: 'Export Report',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteReport(report),
                                        tooltip: 'Delete Report',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComparisonDialog(BuildContext context) {
    final theme = Theme.of(context);
    final diffReport = Provider.of<ScanDataProvider>(context, listen: false)
        .compareScans(_selectedScans[0].id, _selectedScans[1].id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Comparison'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scan details
              Text(
                'Comparing scans:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildScanInfo(_selectedScans[0], 'Scan 1'),
              _buildScanInfo(_selectedScans[1], 'Scan 2'),
              const Divider(height: 24),

              // Risk score change
              _buildComparisonSection(
                'Risk Score Change',
                '${diffReport['riskScoreChange'] > 0 ? '+' : ''}${diffReport['riskScoreChange']}',
                diffReport['riskScoreChange'] > 0 ? Colors.red : Colors.green,
              ),

              // New findings
              if (diffReport['newFindings'].isNotEmpty)
                _buildFindingsSection(
                  'New Findings',
                  diffReport['newFindings'],
                  Colors.red,
                ),

              // Resolved findings
              if (diffReport['resolvedFindings'].isNotEmpty)
                _buildFindingsSection(
                  'Resolved Findings',
                  diffReport['resolvedFindings'],
                  Colors.green,
                ),

              // Vulnerability distribution changes
              _buildVulnerabilityChanges(
                diffReport['vulnerabilityDistributionChange'],
              ),

              // Open ports changes
              if (diffReport['openPortsChange']['new'].isNotEmpty ||
                  diffReport['openPortsChange']['closed'].isNotEmpty)
                _buildPortChanges(diffReport['openPortsChange']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanInfo(ScanReport scan, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ${scan.target}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(scan.timestamp)}',
            ),
            Text('Risk Score: ${scan.riskScore}'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsSection(String title, List<dynamic> findings, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...findings.map((finding) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Text(
                  finding['description'] ?? finding['name'] ?? 'Unknown finding',
                  style: TextStyle(color: color),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildVulnerabilityChanges(Map<String, int> changes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vulnerability Changes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...changes.entries.map((entry) {
            final color = entry.value > 0 ? Colors.red : Colors.green;
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Text(
                '${entry.key}: ${entry.value > 0 ? '+' : ''}${entry.value}',
                style: TextStyle(color: color),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPortChanges(Map<String, dynamic> changes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Port Changes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (changes['new'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Text(
                'New ports: ${changes['new'].join(', ')}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (changes['closed'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Text(
                'Closed ports: ${changes['closed'].join(', ')}',
                style: const TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}
