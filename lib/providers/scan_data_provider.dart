import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../services/web_scan_service.dart';
import '../services/report_service.dart';
import '../models/scan_report.dart';
import '../models/threat.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../screens/enhanced_scan_report_popup.dart';
import '../services/scan_record_service.dart';
import '../models/scan_record.dart';
import '../../main.dart'; // Import the navigatorKey from main.dart
import 'dart:io';
import '../services/url_validator_service.dart';

enum ViewState { idle, busy, error }

class ScanDataProvider extends ChangeNotifier {
  final WebScanService _webScanService = WebScanService();
  final ReportService _reportService = ReportService();
  final ScanRecordService _scanRecordService = ScanRecordService();
  final _uuid = const Uuid();
  ViewState _state = ViewState.idle;
  ScanReport? _currentScan;
  List<ScanReport> _scanHistory = [];

  // Current scan data
  double scanProgress = 0.0;
  String timeRemaining = '--:--';
  bool _isScanning = false;
  String? currentTarget;
  String? currentScanType;
  Map<String, bool>? currentScanOptions;

  // Statistics
  int _totalScans = 0;
  int _activeThreats = 0;
  int _riskScore = 0;

  // Threat data
  List<double> monthlyThreatData = [];
  List<int> dailyThreatData = List.filled(
    7,
    0,
  ); // threats found for each of the last 7 days
  Map<String, List<int>> dailyThreatDataPerTarget = {};
  Map<String, double> vulnerabilityDistribution = {
    'Critical': 30,
    'High': 25,
    'Medium': 28,
    'Low': 17,
  };

  // AI Insights
  List<Map<String, dynamic>> aiInsights = [
    {
      'title': 'Port Scan Analysis',
      'description': 'Multiple open ports detected including 80, 443, 22',
      'confidence': 95,
      'icon': 'network',
      'history': [
        {
          'date': '2024-03-01',
          'ports': [80, 443, 22],
        },
        {
          'date': '2024-03-15',
          'ports': [80, 443, 22, 3306],
        },
      ],
      'comparison': {
        'previous': 3,
        'current': 4,
        'trend': 'increased',
        'recommendation': 'Review newly opened port 3306',
      },
    },
    {
      'title': 'Database Vulnerability',
      'description': 'SQL injection risk identified',
      'confidence': 95,
      'icon': 'database',
      'history': [
        {'date': '2024-03-01', 'severity': 'medium'},
        {'date': '2024-03-15', 'severity': 'high'},
      ],
      'comparison': {
        'previous': 'medium',
        'current': 'high',
        'trend': 'worsened',
        'recommendation': 'Immediate attention required',
      },
    },
    {
      'title': 'Network Analysis',
      'description': 'Potential DDoS pattern detected',
      'confidence': 78,
      'icon': 'shield',
      'history': [
        {'date': '2024-03-01', 'requests': 1000},
        {'date': '2024-03-15', 'requests': 5000},
      ],
      'comparison': {
        'previous': 1000,
        'current': 5000,
        'trend': 'increased',
        'recommendation': 'Implement rate limiting',
      },
    },
  ];

  Timer? _scanTimer;
  Timer? _dataUpdateTimer;
  List<Threat> _threats = [];

  final URLValidatorService _urlValidator = URLValidatorService();

  // Getters
  ViewState get state => _state;
  ScanReport? get currentScan => _currentScan;
  List<ScanReport> get scanHistory => _scanHistory;
  List<Threat> get threats => _threats;
  bool get isScanning => _isScanning;
  int get totalScans => _totalScans;
  int get activeThreats => _activeThreats;
  int get riskScore => _riskScore;

  List<String> get allTargets {
    final targets = <String>{};
    for (final scan in _scanHistory) {
      targets.add(scan.target);
    }
    if (currentTarget != null) targets.add(currentTarget!);
    return targets.toList();
  }

  List<int> getDailyThreatDataForTarget(String? target) {
    if (target == null || target == 'All') {
      // Combine all targets
      List<int> combined = List.filled(7, 0);
      for (final data in dailyThreatDataPerTarget.values) {
        for (int i = 0; i < 7; i++) {
          combined[i] += (i < data.length ? data[i] : 0);
        }
      }
      return combined;
    }
    return dailyThreatDataPerTarget[target] ?? List.filled(7, 0);
  }

  // Add this private field to track the last update date
  DateTime? _lastThreatDataDate;

  bool _hasShownPopup = false;

  // Add new fields for auto-scan scheduling
  Map<String, Timer> _scheduledScans = {};

  ScanDataProvider() {
    _initializeData();
    _loadInitialData();
    _loadScanHistory();
  }

  void _initializeData() {
    // Initialize monthly threat data
    monthlyThreatData = [65, 45, 85, 32, 55, 68];

    // Start periodic data updates
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateThreatData();
    });
  }

  void setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  Future<void> startScan(
    String target,
    String type,
    Map<String, bool> options,
  ) async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      setState(ViewState.busy);
      currentTarget = target;
      currentScanType = type;
      currentScanOptions = options;
      scanProgress = 0.0;
      timeRemaining = '--:--';

      final scanId = _uuid.v4();
      final startTime = DateTime.now();

      // Create initial scan report
      _currentScan = ScanReport(
        id: scanId,
        timestamp: startTime,
        target: target,
        scanType: type,
        vulnerabilityDistribution: {
          'Critical': 0,
          'High': 0,
          'Medium': 0,
          'Low': 0,
        },
        findings: [],
        threats: [],
        enabledOptions: options,
        riskScore: 0,
        summary: 'Scan in progress...',
        scanMetadata: {},
        openPorts: [],
        scanDuration: 0,
        subdomains: [],
        threatIntelligence: {},
        aiScorecard: {},
      );

      // Add to history immediately
      _scanHistory.insert(0, _currentScan!);
      _totalScans = _scanHistory.length;
      await _saveScanHistory(); // Save after adding to history
      notifyListeners();

      // Start progress tracking
      _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (scanProgress < 1.0) {
          scanProgress += 0.01; // Increment progress
          _updateTimeRemaining();
          notifyListeners();
        } else {
          timer.cancel();
        }
      });

      // Start the scan using WebScanService
      if (navigatorKey.currentContext != null) {
        final result = await _webScanService.scanUrl(target);
        
        // Update the scan report with results
        _currentScan = result;
        
        // Update the scan in history
        _scanHistory[0] = _currentScan!;
        await _saveScanHistory(); // Save after updating the scan
        
        // Update threat data
        _updateThreatData();
        
        // Show the report popup
        if (navigatorKey.currentContext != null) {
          await showDialog(
            context: navigatorKey.currentContext!,
            builder: (context) => EnhancedScanReportPopup(
              report: _currentScan!,
              onClose: () => Navigator.of(context).pop(),
            ),
          );
        }
      }

    } catch (e) {
      print('Error during scan: $e');
      setState(ViewState.error);
    } finally {
      _scanTimer?.cancel();
      _isScanning = false;
      scanProgress = 1.0;
      timeRemaining = '00:00';
      setState(ViewState.idle);
      notifyListeners();
    }
  }

  void stopScan() {
    _scanTimer?.cancel();
    _isScanning = false;
    scanProgress = 0.0;
    currentTarget = null;
    currentScanType = null;
    currentScanOptions = null;
    notifyListeners();
  }

  void _updateTimeRemaining() {
    if (scanProgress >= 1.0) {
      timeRemaining = '00:00';
      return;
    }

    final totalSeconds = 12; // Total scan duration
    final remainingSeconds = (totalSeconds * (1 - scanProgress)).round();
    final minutes = (remainingSeconds / 60).floor();
    final seconds = remainingSeconds % 60;
    timeRemaining = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _updateThreatData() async {
    // Simulate real-time threat data updates
    _activeThreats = (_activeThreats + (DateTime.now().second % 3 - 1)).clamp(
      0,
      100,
    );
    _riskScore = (_riskScore + (DateTime.now().second % 5 - 2)).clamp(0, 100);

    // Update monthly data with some variation
    for (var i = 0; i < monthlyThreatData.length; i++) {
      monthlyThreatData[i] += (DateTime.now().millisecond % 3 - 1);
      monthlyThreatData[i] = monthlyThreatData[i].clamp(0, 100);
    }

    notifyListeners();
  }

  Future<void> _processScanResults(ScanReport results) async {
    // Process vulnerabilities from the scan report
    final findings = results.findings;
    int critical = 0, high = 0, medium = 0, low = 0;

    for (var finding in findings) {
      switch (finding['severity']) {
        case 'Critical':
          critical++;
          break;
        case 'High':
          high++;
          break;
        case 'Medium':
          medium++;
          break;
        case 'Low':
          low++;
          break;
      }
    }

    // Update dailyThreatData for the last 7 days
    int todayThreats = findings.length;
    DateTime today = DateTime.now();
    // Shift data if the last entry is not today
    if (dailyThreatData.isNotEmpty && _lastThreatDataDate != null) {
      int daysDiff = today.difference(_lastThreatDataDate!).inDays;
      if (daysDiff > 0) {
        for (int i = 0; i < daysDiff && i < 7; i++) {
          dailyThreatData.insert(0, 0);
        }
        dailyThreatData = dailyThreatData.take(7).toList();
      }
    }
    dailyThreatData[0] += todayThreats;
    _lastThreatDataDate = today;

    // Per-target daily data
    final target = results.target;
    dailyThreatDataPerTarget[target] ??= List.filled(7, 0);
    if (dailyThreatDataPerTarget[target]!.isNotEmpty &&
        _lastThreatDataDate != null) {
      int daysDiff = today.difference(_lastThreatDataDate!).inDays;
      if (daysDiff > 0) {
        for (int i = 0; i < daysDiff && i < 7; i++) {
          dailyThreatDataPerTarget[target]!.insert(0, 0);
        }
        dailyThreatDataPerTarget[target] =
            dailyThreatDataPerTarget[target]!.take(7).toList();
      }
    }
    dailyThreatDataPerTarget[target]![0] += todayThreats;

    final total = critical + high + medium + low;
    if (total > 0) {
      vulnerabilityDistribution = {
        'Critical': (critical / total) * 100,
        'High': (high / total) * 100,
        'Medium': (medium / total) * 100,
        'Low': (low / total) * 100,
      };
    }

    // Convert findings to threats
    _threats = findings
        .map(
          (f) => Threat(
            name: f['name'] ?? 'Unknown Threat',
            severity: f['severity'] ?? 'Low',
            location: f['location'] ?? 'Unknown',
            description: f['description'] ?? '',
            recommendation: f['recommendation'] ?? '',
            detectedAt: DateTime.now(),
            type: f['type'] ?? 'Unknown',
          ),
        )
        .toList();

    // Create and save scan record
    final scanRecord = ScanRecord(
      timestamp: DateTime.now(),
      target: results.target,
      scanType: results.scanType,
      scanOptions: currentScanOptions ?? {},
      threats: _threats,
      vulnerabilityDistribution: vulnerabilityDistribution.map(
        (key, value) => MapEntry(key, value.round()),
      ),
      riskScore: _riskScore,
      summary: _generateScanSummary(),
      scanMetadata: results.scanMetadata,
      openPorts: results.openPorts,
      scanDuration: results.scanDuration,
    );

    await _scanRecordService.saveScanRecord(scanRecord);

    notifyListeners();
  }

  Future<void> _generateScanReport() async {
    if (currentTarget == null || currentScanType == null) return;

    // Get IP address for the current target
    String? ipAddress;
    try {
      String domain = currentTarget!;
      if (domain.startsWith('http')) {
        domain = Uri.parse(domain).host;
      }
      final addresses = await InternetAddress.lookup(domain);
      if (addresses.isNotEmpty) {
        ipAddress = addresses.first.address;
      }
    } catch (e) {
      print('IP extraction error: $e');
    }

    final vulnDist = {
      'Critical': (_threats.where((t) => t.severity == 'Critical').length),
      'High': (_threats.where((t) => t.severity == 'High').length),
      'Medium': (_threats.where((t) => t.severity == 'Medium').length),
      'Low': (_threats.where((t) => t.severity == 'Low').length),
    };

    final findings = _threats
        .map(
          (t) => {
            'type': t.type,
            'severity': t.severity,
            'description': t.description,
            'location': t.location,
            'name': t.name,
            'recommendation': t.recommendation,
          },
        )
        .toList();

    final report = ScanReport(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      target: currentTarget!,
      scanType: currentScanType!,
      findings: findings,
      vulnerabilityDistribution: vulnDist,
      threats: _threats,
      enabledOptions: currentScanOptions ?? {},
      riskScore: _riskScore,
      summary: _generateScanSummary(),
      scanMetadata: {
        'scan_duration': 0,
        'protocol': '',
        'server': '',
        'headers': [],
        'ssl_info': [],
      },
      openPorts: [],
      scanDuration: 0,
      subdomains: ['dev.example.com', 'api.example.com'],
      threatIntelligence: {
        'Reputation': 'Clean',
        'Blacklisted': false,
        'Malicious Activities': 'None detected',
      },
      aiScorecard: {
        'AI Risk Score': 72,
        'Trend': 'Stable',
        'Confidence': 'High',
      },
      ipAddress: ipAddress,
    );

    try {
      await _reportService.generateReport(report, 'json');
      await _reportService.generateReport(report, 'pdf');
      await _reportService.generateReport(report, 'html');
    } catch (e) {
      print('Error generating report: $e');
    }
  }

  String _generateScanSummary() {
    final criticalCount =
        _threats.where((t) => t.severity == 'Critical').length;
    final highCount = _threats.where((t) => t.severity == 'High').length;
    final mediumCount = _threats.where((t) => t.severity == 'Medium').length;
    final lowCount = _threats.where((t) => t.severity == 'Low').length;

    return '''
    Scan completed for $currentTarget. Found:
    - $criticalCount Critical vulnerabilities
    - $highCount High-risk vulnerabilities
    - $mediumCount Medium-risk vulnerabilities
    - $lowCount Low-risk vulnerabilities
    
    Overall risk score: $_riskScore/100
    ''';
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _dataUpdateTimer?.cancel();
    for (var timer in _scheduledScans.values) {
      timer.cancel();
    }
    _scheduledScans.clear();
    super.dispose();
  }

  Future<void> scanUrl(String url) async {
    try {
      setState(ViewState.busy);
      _currentScan = await _webScanService.scanUrl(url);
      _scanHistory.add(_currentScan!);
      await _saveScanHistory(); // Save after adding a scan
      setState(ViewState.idle);
      // Show report popup after scan completion
      if (navigatorKey.currentContext != null) {
        await showDialog(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => EnhancedScanReportPopup(
            report: _currentScan!,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        );
      }
    } catch (e) {
      print('Error scanning URL: $e');
      setState(ViewState.error);
    }
  }

  Future<void> scanTarget(String target, String type) async {
    try {
      setState(ViewState.busy);
      if (type == 'url') {
        await scanUrl(target);
      } else if (type == 'ip') {
        // Implement IP scanning
        throw UnimplementedError('IP scanning not yet implemented');
      }
      setState(ViewState.idle);
    } catch (e) {
      print('Error scanning target: $e');
      setState(ViewState.error);
    }
  }

  Future<void> clearHistory() async {
    _scanHistory.clear();
    _totalScans = 0;
    await _saveScanHistory(); // Save after clearing history
    notifyListeners();
  }

  Future<void> removeScan(String scanId) async {
    _scanHistory.removeWhere((scan) => scan.id == scanId);
    _totalScans = _scanHistory.length;
    await _saveScanHistory(); // Save after removing scan
    notifyListeners();
  }

  // Initialize with sample data
  void _loadInitialData() {
    _totalScans = 15;
    _activeThreats = 28;
    _riskScore = 75;

    _threats = [
      Threat(
        name: 'SQL Injection Vulnerability',
        severity: 'Critical',
        location: 'login.php',
        description: 'Unvalidated user input in login form',
        recommendation: 'Implement input validation and prepared statements',
        detectedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: 'Injection',
      ),
      Threat(
        name: 'Outdated SSL Certificate',
        severity: 'High',
        location: 'Server Configuration',
        description: 'SSL certificate expires in 5 days',
        recommendation: 'Renew SSL certificate immediately',
        detectedAt: DateTime.now().subtract(const Duration(days: 2)),
        type: 'Configuration',
      ),
      Threat(
        name: 'Cross-Site Scripting (XSS)',
        severity: 'High',
        location: 'comment.js',
        description: 'Unsanitized user input in comment section',
        recommendation: 'Implement proper input sanitization',
        detectedAt: DateTime.now().subtract(const Duration(days: 3)),
        type: 'Injection',
      ),
      // Add more sample threats here
    ];

    notifyListeners();
  }

  // Add a new threat
  void addThreat(Threat threat) {
    _threats.add(threat);
    _activeThreats = _threats.where((t) => !t.isFixed && !t.isIgnored).length;
    updateRiskScore();
    notifyListeners();
  }

  // Mark a threat as fixed
  void markThreatAsFixed(Threat threat) {
    final index = _threats.indexOf(threat);
    if (index != -1) {
      _threats[index].isFixed = true;
      _activeThreats = _threats.where((t) => !t.isFixed && !t.isIgnored).length;
      updateRiskScore();
      notifyListeners();
    }
  }

  // Ignore a threat
  void ignoreThreat(Threat threat) {
    final index = _threats.indexOf(threat);
    if (index != -1) {
      _threats[index].isIgnored = true;
      _activeThreats = _threats.where((t) => !t.isFixed && !t.isIgnored).length;
      updateRiskScore();
      notifyListeners();
    }
  }

  // Update risk score based on active threats
  void updateRiskScore() {
    if (_threats.isEmpty) {
      _riskScore = 0;
      return;
    }

    int totalScore = 0;
    int maxPossibleScore = _threats.length * 4; // 4 is the max severity score

    for (var threat in _threats) {
      if (!threat.isFixed && !threat.isIgnored) {
        totalScore += threat.severityScore;
      }
    }

    _riskScore = ((totalScore / maxPossibleScore) * 100).round();
    notifyListeners();
  }

  // Get threats by severity
  List<Threat> getThreatsBySeverity(String severity) {
    return _threats
        .where(
          (t) =>
              t.severity.toLowerCase() == severity.toLowerCase() &&
              !t.isFixed &&
              !t.isIgnored,
        )
        .toList();
  }

  // Get threats by type
  List<Threat> getThreatsByType(String type) {
    return _threats
        .where(
          (t) =>
              t.type.toLowerCase() == type.toLowerCase() &&
              !t.isFixed &&
              !t.isIgnored,
        )
        .toList();
  }

  // Export threats to JSON
  String exportThreatsToJson() {
    return jsonEncode(_threats.map((t) => t.toJson()).toList());
  }

  Future<void> exportTrainingData() async {
    await _scanRecordService.exportTrainingData();
  }

  // New method to schedule an auto-scan
  Future<void> scheduleAutoScan(
      String target, String scanInterval, Map<String, bool> options) async {
    // Cancel any existing scheduled scan for this target
    _scheduledScans[target]?.cancel();
    _scheduledScans.remove(target);

    // Calculate the interval duration
    Duration interval;
    switch (scanInterval) {
      case 'hourly':
        interval = const Duration(hours: 1);
        break;
      case 'daily':
        interval = const Duration(days: 1);
        break;
      case 'weekly':
        interval = const Duration(days: 7);
        break;
      case 'monthly':
        interval = const Duration(days: 30);
        break;
      default:
        interval = const Duration(days: 1);
    }

    // Schedule the scan
    _scheduledScans[target] = Timer.periodic(interval, (timer) async {
      await startScan(target, 'url', options);
    });

    notifyListeners();
  }

  // New method to cancel a scheduled auto-scan
  void cancelAutoScan(String target) {
    _scheduledScans[target]?.cancel();
    _scheduledScans.remove(target);
    notifyListeners();
  }

  // New method to compare two scans
  Map<String, dynamic> compareScans(String scanId1, String scanId2) {
    final scan1 = _scanHistory.firstWhere((scan) => scan.id == scanId1);
    final scan2 = _scanHistory.firstWhere((scan) => scan.id == scanId2);

    final newFindings = <Map<String, dynamic>>[];
    final resolvedFindings = <Map<String, dynamic>>[];
    final vulnerabilityDistributionChange = <String, int>{};
    final newOpenPorts = <int>[];
    final closedOpenPorts = <int>[];

    // Compare findings
    for (var finding in scan2.findings) {
      if (!scan1.findings.any((f) => f['name'] == finding['name'])) {
        newFindings.add(finding);
      }
    }

    for (var finding in scan1.findings) {
      if (!scan2.findings.any((f) => f['name'] == finding['name'])) {
        resolvedFindings.add(finding);
      }
    }

    // Compare vulnerability distribution
    for (var severity in ['Critical', 'High', 'Medium', 'Low']) {
      vulnerabilityDistributionChange[severity] =
          (scan2.vulnerabilityDistribution[severity] ?? 0) -
              (scan1.vulnerabilityDistribution[severity] ?? 0);
    }

    // Compare open ports
    for (var port in scan2.openPorts) {
      if (!scan1.openPorts.contains(port)) {
        newOpenPorts.add(port as int);
      }
    }

    for (var port in scan1.openPorts) {
      if (!scan2.openPorts.contains(port)) {
        closedOpenPorts.add(port as int);
      }
    }

    return {
      'newFindings': newFindings,
      'resolvedFindings': resolvedFindings,
      'riskScoreChange': scan2.riskScore - scan1.riskScore,
      'vulnerabilityDistributionChange': vulnerabilityDistributionChange,
      'openPortsChange': {
        'new': newOpenPorts,
        'closed': closedOpenPorts,
      },
    };
  }

  // Add method to get scan history
  List<ScanReport> getScanHistory() {
    return _scanHistory;
  }

  // Load scan history from SharedPreferences
  Future<void> _loadScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('scan_history');
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _scanHistory = decoded.map((item) => ScanReport.fromJson(item)).toList();
        _totalScans = _scanHistory.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading scan history: $e');
    }
  }

  // Save scan history to SharedPreferences
  Future<void> _saveScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_scanHistory.map((scan) => scan.toJson()).toList());
      await prefs.setString('scan_history', historyJson);
    } catch (e) {
      print('Error saving scan history: $e');
    }
  }
}
