import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/scan_result.dart';
import '../models/threat.dart';
import '../models/ml_result.dart';
import 'database_service.dart';
import 'ml_service.dart';

class ScanService {
  static final ScanService _instance = ScanService._internal();
  final DatabaseService _db = DatabaseService();
  final MLService _mlService = MLService();

  factory ScanService() => _instance;

  ScanService._internal();

  /// Start a new scan
  Future<ScanResult> startScan({
    required String targetPath,
    required String scanType,
  }) async {
    // Create initial scan result
    final scanResult = ScanResult(
      targetPath: targetPath,
      scanType: scanType,
      startTime: DateTime.now(),
      status: 'running',
    );

    // Save to database
    final id = await _db.insertScanResult(scanResult.toMap());
    final savedResult = scanResult.copyWith(id: id);

    // Start scanning in background
    _performScan(savedResult);

    return savedResult;
  }

  /// Perform the actual scan
  Future<void> _performScan(ScanResult scanResult) async {
    try {
      // Simulate scanning process
      await Future.delayed(const Duration(seconds: 2));

      // Get ML predictions
      final mlResults = await _getMLPredictions(scanResult);

      // Analyze results and identify threats
      final threats = await _analyzeThreats(scanResult, mlResults);

      // Calculate risk level
      final riskLevel = _calculateRiskLevel(threats);

      // Update scan result
      final updatedResult = scanResult.copyWith(
        endTime: DateTime.now(),
        status: 'completed',
        findings: {
          'threats': threats.map((t) => t.toMap()).toList(),
          'mlResults': mlResults.map((r) => r.toMap()).toList(),
        },
        riskLevel: riskLevel,
      );

      // Save updated result
      await _db.insertScanResult(updatedResult.toMap());

      // Save threats
      for (var threat in threats) {
        await _db.insertThreat(threat.toMap());
      }

      // Save ML results
      for (var result in mlResults) {
        await _mlService.saveMLResult(result);
      }
    } catch (e) {
      // Update scan result with error
      final errorResult = scanResult.copyWith(
        endTime: DateTime.now(),
        status: 'failed',
        findings: {'error': e.toString()},
      );

      await _db.insertScanResult(errorResult.toMap());
    }
  }

  /// Get ML predictions for the scan
  Future<List<MLResult>> _getMLPredictions(ScanResult scanResult) async {
    final predictions = <MLResult>[];

    // Simulate ML predictions for different models
    for (var modelName in [
      'threatDetection',
      'vulnerabilityAnalysis',
      'anomalyDetection'
    ]) {
      final prediction = MLResult(
        scanResultId: scanResult.id!,
        modelName: modelName,
        confidence:
            0.8 + (0.2 * DateTime.now().millisecondsSinceEpoch % 100) / 100,
        prediction: _getRandomPrediction(modelName),
        features: _getRandomFeatures(modelName),
      );

      predictions.add(prediction);
    }

    return predictions;
  }

  /// Analyze threats based on ML results
  Future<List<Threat>> _analyzeThreats(
      ScanResult scanResult, List<MLResult> mlResults) async {
    final threats = <Threat>[];

    // Simulate threat analysis
    for (var result in mlResults) {
      if (result.confidence > 0.7) {
        threats.add(Threat(
          scanResultId: scanResult.id!,
          threatType: result.modelName,
          description: 'Potential ${result.modelName} threat detected',
          severity: _getRandomSeverity(),
          location: scanResult.targetPath,
          recommendation: _getRandomRecommendation(result.modelName),
        ));
      }
    }

    return threats;
  }

  /// Calculate overall risk level
  String _calculateRiskLevel(List<Threat> threats) {
    if (threats.isEmpty) return 'low';

    final severityCounts = {
      'high': 0,
      'medium': 0,
      'low': 0,
    };

    for (var threat in threats) {
      severityCounts[threat.severity] =
          (severityCounts[threat.severity] ?? 0) + 1;
    }

    if (severityCounts['high']! > 0) return 'high';
    if (severityCounts['medium']! > 0) return 'medium';
    return 'low';
  }

  /// Get random prediction for testing
  String _getRandomPrediction(String modelName) {
    final predictions = {
      'threatDetection': ['Malicious', 'Benign', 'Suspicious'],
      'vulnerabilityAnalysis': ['Vulnerable', 'Secure', 'Needs Review'],
      'anomalyDetection': ['Anomaly', 'Normal', 'Suspicious'],
    };

    final modelPredictions = predictions[modelName] ?? ['Unknown'];
    return modelPredictions[
        DateTime.now().millisecondsSinceEpoch % modelPredictions.length];
  }

  /// Get random features for testing
  Map<String, dynamic> _getRandomFeatures(String modelName) {
    final features = {
      'threatDetection': {
        'port': 443,
        'service': 'https',
        'protocol': 'tcp',
        'banner': 'Apache/2.4.41',
        'response_time': 0.15,
      },
      'vulnerabilityAnalysis': {
        'code_complexity': 0.7,
        'dependencies': 15,
        'security_headers': 3,
        'input_validation': 0.8,
      },
      'anomalyDetection': {
        'packet_size': 1024,
        'frequency': 0.5,
        'destination_ports': [80, 443, 8080],
        'protocol_distribution': {'tcp': 0.7, 'udp': 0.3},
      },
    };

    return features[modelName] ?? {};
  }

  /// Get random severity for testing
  String _getRandomSeverity() {
    final severities = ['high', 'medium', 'low'];
    return severities[
        DateTime.now().millisecondsSinceEpoch % severities.length];
  }

  /// Get random recommendation for testing
  String _getRandomRecommendation(String modelName) {
    final recommendations = {
      'threatDetection': [
        'Update security patches',
        'Implement firewall rules',
        'Monitor network traffic',
      ],
      'vulnerabilityAnalysis': [
        'Fix input validation',
        'Update dependencies',
        'Implement secure coding practices',
      ],
      'anomalyDetection': [
        'Investigate unusual patterns',
        'Review access logs',
        'Update detection rules',
      ],
    };

    final modelRecommendations =
        recommendations[modelName] ?? ['No recommendation available'];
    return modelRecommendations[
        DateTime.now().millisecondsSinceEpoch % modelRecommendations.length];
  }

  /// Get scan results
  Future<List<ScanResult>> getScanResults() async {
    final results = await _db.getScanResults();
    return results.map((map) => ScanResult.fromMap(map)).toList();
  }

  /// Get threats for a scan
  Future<List<Threat>> getThreatsForScan(int scanResultId) async {
    final threats = await _db.getThreatsForScan(scanResultId);
    return threats.map((map) => Threat.fromMap(map)).toList();
  }
}
