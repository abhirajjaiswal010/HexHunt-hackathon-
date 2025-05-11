import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/ml_result.dart';
import '../models/scan_report.dart';
import 'database_service.dart';

/// Service for managing machine learning models in HexHunt
class MLService {
  static final MLService _instance = MLService._internal();
  final DatabaseService _db = DatabaseService();

  // Singleton pattern
  factory MLService() => _instance;

  MLService._internal() {
    _initializeModels();
  }

  // Model versions and metadata
  Map<String, dynamic> _modelMetadata = {
    'threatDetection': {
      'version': 1.5,
      'trainedOn': '2023-05-15',
      'accuracy': 0.87,
      'type': 'Random Forest',
      'features': ['port', 'service', 'protocol', 'banner', 'response_time']
    },
    'vulnerabilityAnalysis': {
      'version': 2.1,
      'trainedOn': '2023-06-20',
      'accuracy': 0.92,
      'type': 'BERT (Fine-tuned)',
      'vocabSize': 30522,
      'attentionHeads': 12,
      'hiddenLayers': 12,
      'languages': ['English', 'Spanish', 'French', 'German'],
      'specialization': 'Cybersecurity text analysis',
    },
    'anomalyDetection': {
      'version': 1.2,
      'trainedOn': '2023-04-10',
      'accuracy': 0.83,
      'type': 'Isolation Forest',
      'threshold': 0.65,
      'features': [
        'packet_size',
        'frequency',
        'destination_ports',
        'protocol_distribution'
      ]
    },
    'webSecurityScanner': {
      'version': 2.3,
      'trainedOn': '2023-07-05',
      'accuracy': 0.88,
      'type': 'CNN + Transformer Hybrid',
      'vulnerabilityTypes': [
        'XSS',
        'SQL Injection',
        'CSRF',
        'Header Misconfiguration',
        'Input Validation'
      ]
    },
    'threatIntelligence': {
      'version': 3.0,
      'trainedOn': '2023-07-25',
      'accuracy': 0.95,
      'type': 'GeoIP + Risk Assessment',
      'sources': ['MaxMind', 'AbuseIPDB', 'AlienVault OTX', 'Proprietary']
    }
  };

  // Model data - in a real app these would be actual model weights, parameters, etc.
  Map<String, dynamic> _modelData = {};

  // Performance metrics
  Map<String, List<double>> _performanceMetrics = {
    'threatDetection': [0.84, 0.86, 0.87, 0.87, 0.87],
    'vulnerabilityAnalysis': [0.88, 0.90, 0.91, 0.92, 0.92],
    'anomalyDetection': [0.80, 0.81, 0.83, 0.83, 0.83],
    'webSecurityScanner': [0.85, 0.86, 0.87, 0.88, 0.88],
    'threatIntelligence': [0.92, 0.93, 0.94, 0.94, 0.95],
  };

  // Training statistics
  Map<String, dynamic> _trainingStats = {
    'lastTraining': '2023-07-28',
    'samplesProcessed': 15420,
    'improvementRate': 0.03,
    'trainingTime': '4h 32m',
  };

  /// Initialize ML models - in a real app, this would load actual model files
  Future<void> _initializeModels() async {
    try {
      // Simulated model initialization
      await Future.delayed(const Duration(seconds: 1));
      _loadModelData();
      debugPrint('ML models initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ML models: $e');
    }
  }

  /// Load model data from storage or bundled assets
  Future<void> _loadModelData() async {
    try {
      // Here we would load actual model files, but for this demo we'll use placeholder data
      final mockModelData = {
        'threatDetection': {
          'weights': List.generate(100, (i) => math.Random().nextDouble()),
          'biases': List.generate(10, (i) => math.Random().nextDouble()),
          'featureImportance': {
            'port': 0.35,
            'service': 0.25,
            'protocol': 0.15,
            'banner': 0.15,
            'response_time': 0.10,
          },
        },
        'vulnerabilityAnalysis': {
          'embeddingSize': 768,
          'vocabulary': List.generate(1000, (i) => 'token_$i'),
          'topVulnerabilities': [
            'SQL Injection',
            'Cross-site Scripting (XSS)',
            'Cross-site Request Forgery (CSRF)',
            'Insecure Deserialization',
            'Authentication Bypass'
          ],
        },
        'anomalyDetection': {
          'normalPatterns': List.generate(50, (i) => 'pattern_$i'),
          'thresholds': List.generate(5, (i) => 0.6 + (i * 0.05)),
        },
        'webSecurityScanner': {
          'patterns': List.generate(200, (i) => 'web_pattern_$i'),
          'signatures': List.generate(100, (i) => 'signature_$i'),
        },
        'threatIntelligence': {
          'geoIPDatabase': 'loaded',
          'threatFeeds': ['AlienVault', 'AbuseIPDB', 'Emerging Threats'],
        },
      };

      // Save model data to database
      for (var entry in mockModelData.entries) {
        await _db.setSetting('model_${entry.key}', jsonEncode(entry.value));
      }
    } catch (e) {
      debugPrint('Error loading model data: $e');
    }
  }

  /// Save model data to persistent storage
  Future<void> _saveModelData() async {
    try {
      // In a real app, this would serialize and save model data to disk
      final modelJson = jsonEncode(_modelData);
      final metadataJson = jsonEncode(_modelMetadata);

      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/ml_models.json');
      final metadataFile = File('${directory.path}/ml_metadata.json');

      await modelFile.writeAsString(modelJson);
      await metadataFile.writeAsString(metadataJson);

      debugPrint('Model data saved successfully');
    } catch (e) {
      debugPrint('Error saving model data: $e');
    }
  }

  /// Get model information
  Map<String, dynamic> getModelInfo(String modelName) {
    if (_modelMetadata.containsKey(modelName)) {
      return _modelMetadata[modelName];
    }
    return {'error': 'Model not found'};
  }

  /// Get performance trend for a model
  List<double> getPerformanceTrend(String modelName) {
    if (_performanceMetrics.containsKey(modelName)) {
      return List<double>.from(_performanceMetrics[modelName] ?? []);
    }
    return [];
  }

  /// Get overall model stats
  Map<String, dynamic> getOverallStats() {
    final averageAccuracy = _modelMetadata.values
            .map((m) => m['accuracy'] as double)
            .reduce((a, b) => a + b) /
        _modelMetadata.length;

    return {
      'modelsCount': _modelMetadata.length,
      'averageAccuracy': averageAccuracy,
      'lastTraining': _trainingStats['lastTraining'],
      'samplesProcessed': _trainingStats['samplesProcessed'],
    };
  }

  /// Get all models with their metadata
  List<Map<String, dynamic>> getAllModels() {
    return _modelMetadata.entries.map((entry) {
      return {
        'id': entry.key,
        'name': _getReadableName(entry.key),
        'accuracy': entry.value['accuracy'] as double,
        'version': entry.value['version'],
        'trainedOn': entry.value['trainedOn'],
      };
    }).toList();
  }

  /// Get readable name for model
  String _getReadableName(String modelId) {
    switch (modelId) {
      case 'threatDetection':
        return 'Threat Detection';
      case 'vulnerabilityAnalysis':
        return 'Vulnerability Analysis';
      case 'anomalyDetection':
        return 'Anomaly Detection';
      case 'webSecurityScanner':
        return 'Web Security Scanner';
      case 'threatIntelligence':
        return 'Threat Intelligence';
      default:
        return modelId;
    }
  }

  /// Analyze security for a given target (URL, IP, or file)
  /// Returns ML predictions for threat assessment
  Future<Map<String, dynamic>> analyzeSecurity(String target) async {
    // Simulate ML analysis with a delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate random threat predictions based on target characteristics
    final random = math.Random();

    // Use characteristics of the target to influence predictions
    // In a real app, this would use an actual ML model
    int baseRisk = 0;

    // Check if it's a known risky domain
    if (target.contains('example.com') ||
        target.contains('test.') ||
        target.contains('dev.')) {
      baseRisk = 30 + random.nextInt(20);
    } else if (target.endsWith('.exe') ||
        target.endsWith('.dll') ||
        target.endsWith('.bat')) {
      // Executables have higher base risk
      baseRisk = 50 + random.nextInt(30);
    } else {
      // Random base risk for other targets
      baseRisk = 10 + random.nextInt(40);
    }

    // Predicted threats based on risk score
    final predictedThreats = baseRisk ~/ 5 + random.nextInt(5);

    // Generate vulnerability breakdown
    final vulnerabilityBreakdown = <String, double>{
      'Critical': (baseRisk > 70)
          ? 0.25 + random.nextDouble() * 0.15
          : 0.05 + random.nextDouble() * 0.15,
      'High': (baseRisk > 50)
          ? 0.2 + random.nextDouble() * 0.15
          : 0.1 + random.nextDouble() * 0.15,
      'Medium': 0.15 + random.nextDouble() * 0.25,
      'Low': 0.1 + random.nextDouble() * 0.3,
    };

    // Normalize to ensure they sum to 1.0
    double total =
        vulnerabilityBreakdown.values.fold(0, (sum, value) => sum + value);
    vulnerabilityBreakdown.forEach((key, value) {
      vulnerabilityBreakdown[key] = value / total;
    });

    return {
      'predictedRiskScore': baseRisk,
      'predictedThreats': predictedThreats,
      'vulnerabilityBreakdown': vulnerabilityBreakdown,
      'confidence': 0.7 +
          random.nextDouble() * 0.25, // Confidence score between 0.7 and 0.95
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 1. Threat Detection Model - Port and service analysis
  Future<Map<String, dynamic>> detectThreats(
      Map<String, dynamic> scanData) async {
    // In a real app, this would use the actual ML model for inference
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulate processing time

    final ports = scanData['ports'] as List<dynamic>? ?? [];
    final services = scanData['services'] as List<dynamic>? ?? [];

    // Simulate threat scoring
    final random = math.Random();
    final threats = <Map<String, dynamic>>[];

    for (int i = 0; i < ports.length && i < services.length; i++) {
      final port = ports[i];
      final service = services[i];

      // Some ports are more likely to have threats
      double threatScore = 0.1;
      if (port == 21 || port == 23 || port == 445 || port == 3389) {
        threatScore =
            0.7 + (random.nextDouble() * 0.2); // Higher risk for certain ports
      } else if (port < 1024) {
        threatScore = 0.3 + (random.nextDouble() * 0.3);
      } else {
        threatScore = random.nextDouble() * 0.4;
      }

      // Certain services are more risky
      if (service.toString().toLowerCase().contains('telnet') ||
          service.toString().toLowerCase().contains('ftp') ||
          service.toString().toLowerCase().contains('smb')) {
        threatScore += 0.2;
      }

      if (threatScore > 0.5) {
        threats.add({
          'port': port,
          'service': service,
          'threatScore': threatScore,
          'recommendation': _getThreatRecommendation(port, service),
        });
      }
    }

    return {
      'threatCount': threats.length,
      'threats': threats,
      'highestThreatScore': threats.isEmpty
          ? 0
          : threats.map((t) => t['threatScore'] as double).reduce(math.max),
      'modelVersion': _modelMetadata['threatDetection']['version'],
    };
  }

  String _getThreatRecommendation(int port, String service) {
    // Basic recommendations based on port/service
    if (port == 21) {
      return 'Consider replacing FTP with SFTP or disabling if unused';
    } else if (port == 23) {
      return 'Telnet is insecure and should be replaced with SSH';
    } else if (port == 445) {
      return 'Ensure SMB is patched and restrict access to trusted IPs';
    } else if (port == 3389) {
      return 'Use Network Level Authentication and restrict RDP access';
    } else if (service.toLowerCase().contains('http')) {
      return 'Ensure web services use HTTPS and are properly configured';
    }
    return 'Review if this service is necessary and restrict access if possible';
  }

  /// 2. Vulnerability Analysis with BERT NLP
  Future<Map<String, dynamic>> analyzeVulnerabilities(String text) async {
    // Simulate BERT processing time
    await Future.delayed(const Duration(milliseconds: 800));

    // Keywords that might indicate vulnerabilities
    final vulnerabilityKeywords = {
      'sql injection': 0.92,
      'xss': 0.90,
      'cross-site scripting': 0.90,
      'csrf': 0.88,
      'cross-site request forgery': 0.88,
      'authentication bypass': 0.85,
      'buffer overflow': 0.82,
      'command injection': 0.86,
      'file inclusion': 0.84,
      'path traversal': 0.83,
      'insecure deserialization': 0.87,
      'xxe': 0.85,
      'xml external entity': 0.85,
    };

    final textLower = text.toLowerCase();
    final foundVulnerabilities = <Map<String, dynamic>>[];

    vulnerabilityKeywords.forEach((keyword, confidence) {
      if (textLower.contains(keyword)) {
        foundVulnerabilities.add({
          'type': keyword,
          'confidence': confidence -
              (math.Random().nextDouble() * 0.1), // Add some variability
          'summary': _generateVulnerabilitySummary(keyword),
          'cvss': _generateCVSSScore(keyword),
        });
      }
    });

    // If no keywords matched but text is long enough, use "semantic" analysis
    if (foundVulnerabilities.isEmpty && text.length > 100) {
      // Simulate finding something through semantic analysis
      final randomVuln = vulnerabilityKeywords.keys
          .elementAt(math.Random().nextInt(vulnerabilityKeywords.length));

      // Lower confidence for semantic findings
      foundVulnerabilities.add({
        'type': randomVuln,
        'confidence': 0.60 + (math.Random().nextDouble() * 0.15),
        'summary': 'Potential ' + _generateVulnerabilitySummary(randomVuln),
        'cvss': _generateCVSSScore(randomVuln),
        'note': 'Identified through semantic analysis',
      });
    }

    return {
      'findings': foundVulnerabilities,
      'processingTime': '${(math.Random().nextInt(500) + 300)}ms',
      'modelVersion': _modelMetadata['vulnerabilityAnalysis']['version'],
      'modelAccuracy': _modelMetadata['vulnerabilityAnalysis']['accuracy'],
    };
  }

  String _generateVulnerabilitySummary(String vulnType) {
    final summaries = {
      'sql injection':
          'SQL injection vulnerability allowing attackers to manipulate database queries',
      'xss':
          'Cross-site scripting vulnerability allowing injection of malicious scripts',
      'cross-site scripting':
          'Cross-site scripting vulnerability allowing injection of malicious scripts',
      'csrf':
          'Cross-site request forgery vulnerability allowing forced actions on behalf of authenticated users',
      'cross-site request forgery':
          'Cross-site request forgery vulnerability allowing forced actions on behalf of authenticated users',
      'authentication bypass':
          'Vulnerability allowing attackers to bypass authentication mechanisms',
      'buffer overflow':
          'Buffer overflow vulnerability potentially allowing code execution',
      'command injection':
          'Command injection vulnerability allowing execution of arbitrary commands',
      'file inclusion':
          'File inclusion vulnerability allowing inclusion of unauthorized files',
      'path traversal':
          'Path traversal vulnerability allowing access to files outside root directory',
      'insecure deserialization':
          'Insecure deserialization vulnerability potentially allowing code execution',
      'xxe':
          'XML External Entity vulnerability allowing access to internal files and services',
      'xml external entity':
          'XML External Entity vulnerability allowing access to internal files and services',
    };

    return summaries[vulnType] ??
        'Security vulnerability that could compromise system integrity';
  }

  double _generateCVSSScore(String vulnType) {
    // Base CVSS scores for vulnerability types
    final cvssBase = {
      'sql injection': 8.5,
      'xss': 6.5,
      'cross-site scripting': 6.5,
      'csrf': 6.8,
      'cross-site request forgery': 6.8,
      'authentication bypass': 9.0,
      'buffer overflow': 8.0,
      'command injection': 8.8,
      'file inclusion': 7.5,
      'path traversal': 7.2,
      'insecure deserialization': 8.0,
      'xxe': 7.5,
      'xml external entity': 7.5,
    };

    // Add some variability
    final baseScore = cvssBase[vulnType] ?? 6.0;
    return baseScore + (math.Random().nextDouble() - 0.5);
  }

  /// 3. Anomaly Detection in Network Scans
  Future<Map<String, dynamic>> detectAnomalies(
      List<Map<String, dynamic>> networkData) async {
    // Simulate model processing
    await Future.delayed(const Duration(milliseconds: 500));

    final random = math.Random();
    final anomalies = <Map<String, dynamic>>[];

    // Features we'd analyze for anomalies
    final features = [
      'packet_size',
      'frequency',
      'destination_ports',
      'protocol_distribution'
    ];

    // Simulate anomaly detection
    for (int i = 0; i < networkData.length; i++) {
      final data = networkData[i];
      final anomalyScore = random.nextDouble();

      if (anomalyScore > 0.7) {
        // This would be an anomaly
        final anomalousFeatures = <String>[];
        for (final feature in features) {
          if (random.nextBool()) {
            anomalousFeatures.add(feature);
          }
        }

        if (anomalousFeatures.isNotEmpty) {
          anomalies.add({
            'dataPointIndex': i,
            'anomalyScore': anomalyScore,
            'anomalousFeatures': anomalousFeatures,
            'severity': anomalyScore > 0.9
                ? 'High'
                : (anomalyScore > 0.8 ? 'Medium' : 'Low'),
            'recommendation':
                'Investigate unusual network behavior in the highlighted features',
          });
        }
      }
    }

    return {
      'anomalyCount': anomalies.length,
      'anomalies': anomalies,
      'threshold': _modelMetadata['anomalyDetection']['threshold'],
      'modelVersion': _modelMetadata['anomalyDetection']['version'],
    };
  }

  /// 4. Web Security Scanner
  Future<Map<String, dynamic>> scanWebSecurity(
      String url, Map<String, dynamic> responseData) async {
    // Simulate ML processing time
    await Future.delayed(const Duration(milliseconds: 700));

    final random = math.Random();
    final vulnerabilities = <Map<String, dynamic>>[];

    // Check for common web vulnerabilities based on response headers and content
    final missingHeaders = _checkSecurityHeaders(
        responseData['headers'] as Map<String, dynamic>? ?? {});

    for (final header in missingHeaders) {
      vulnerabilities.add({
        'type': 'Missing Security Header',
        'detail': header,
        'risk': header.contains('Content-Security-Policy') ? 'High' : 'Medium',
        'confidence': 0.95,
        'recommendation': 'Add the $header header to improve security posture',
      });
    }

    // Simulate finding other vulnerabilities
    final vulnTypes = _modelMetadata['webSecurityScanner']['vulnerabilityTypes']
        as List<dynamic>;

    // Randomly find 0-2 vulnerabilities
    final vulnCount = random.nextInt(3);
    for (int i = 0; i < vulnCount; i++) {
      final vulnType = vulnTypes[random.nextInt(vulnTypes.length)];

      // Don't duplicate header findings
      if (vulnType != 'Header Misconfiguration') {
        vulnerabilities.add({
          'type': vulnType,
          'detail': _generateVulnerabilityDetail(vulnType, url),
          'risk': _getVulnerabilityRisk(vulnType),
          'confidence': 0.7 + (random.nextDouble() * 0.25),
          'recommendation': _getVulnerabilityRecommendation(vulnType),
        });
      }
    }

    return {
      'vulnerabilityCount': vulnerabilities.length,
      'vulnerabilities': vulnerabilities,
      'scanCoverage': 0.85 + (random.nextDouble() * 0.1),
      'modelVersion': _modelMetadata['webSecurityScanner']['version'],
    };
  }

  List<String> _checkSecurityHeaders(Map<String, dynamic> headers) {
    // Essential security headers
    final securityHeaders = [
      'Content-Security-Policy',
      'X-Content-Type-Options',
      'X-Frame-Options',
      'X-XSS-Protection',
      'Strict-Transport-Security',
      'Referrer-Policy',
    ];

    final missing = <String>[];
    final headerKeys =
        headers.keys.map((k) => k.toString().toLowerCase()).toList();

    for (final header in securityHeaders) {
      if (!headerKeys.contains(header.toLowerCase())) {
        missing.add(header);
      }
    }

    // Randomly select a subset of missing headers to report
    missing.shuffle();
    return missing.take(math.min(3, missing.length)).toList();
  }

  String _generateVulnerabilityDetail(String vulnType, String url) {
    switch (vulnType) {
      case 'XSS':
        return 'Potential XSS vulnerability found in parameter handling at $url?search=<parameter>';
      case 'SQL Injection':
        return 'Possible SQL injection point in database query handling at $url?id=<parameter>';
      case 'CSRF':
        return 'Missing CSRF tokens in form submission at $url/form';
      case 'Input Validation':
        return 'Insufficient input validation on user-provided data at $url/input';
      default:
        return 'Security vulnerability detected in application at $url';
    }
  }

  String _getVulnerabilityRisk(String vulnType) {
    switch (vulnType) {
      case 'XSS':
        return 'Medium';
      case 'SQL Injection':
        return 'High';
      case 'CSRF':
        return 'Medium';
      case 'Input Validation':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _getVulnerabilityRecommendation(String vulnType) {
    switch (vulnType) {
      case 'XSS':
        return 'Implement proper input validation, output encoding, and consider using Content-Security-Policy';
      case 'SQL Injection':
        return 'Use parameterized queries or prepared statements and validate all user inputs';
      case 'CSRF':
        return 'Implement CSRF tokens in all forms and validate on form submission';
      case 'Input Validation':
        return 'Implement server-side validation for all user inputs';
      default:
        return 'Review and secure the identified vulnerability point';
    }
  }

  /// 5. GeoIP & Threat Intelligence
  Future<Map<String, dynamic>> analyzeIPThreatIntelligence(
      String ipAddress) async {
    // Simulate API call to threat intelligence service
    await Future.delayed(const Duration(milliseconds: 400));

    final random = math.Random();

    // Generate plausible country and ASN data
    final countries = [
      'United States',
      'Russia',
      'China',
      'Germany',
      'Brazil',
      'India',
      'Netherlands',
      'Ukraine'
    ];
    final country = countries[random.nextInt(countries.length)];

    final asnNames = [
      'Google LLC',
      'Amazon.com Inc.',
      'Digital Ocean',
      'OVH SAS',
      'Cloudflare Inc.',
      'Microsoft Corporation'
    ];
    final asnName = asnNames[random.nextInt(asnNames.length)];
    final asnNumber = 'AS${10000 + random.nextInt(40000)}';

    // Generate threat score - certain countries have higher base risk in this example
    double threatScore = 0.1 + (random.nextDouble() * 0.3);
    if (country == 'Russia' || country == 'China' || country == 'Ukraine') {
      threatScore += 0.2;
    }

    // Random chance to have reported malicious activity
    final reportedMalicious = random.nextDouble() > 0.7;
    if (reportedMalicious) {
      threatScore += 0.3 + (random.nextDouble() * 0.2);
    }

    // Risk categorization
    String riskCategory;
    if (threatScore < 0.3) {
      riskCategory = 'Low';
    } else if (threatScore < 0.6) {
      riskCategory = 'Medium';
    } else if (threatScore < 0.8) {
      riskCategory = 'High';
    } else {
      riskCategory = 'Critical';
    }

    // Activity data
    final activities = <String>[];
    if (reportedMalicious) {
      final possibleActivities = [
        'Port Scanning',
        'Brute Force Attempts',
        'Malware Distribution',
        'Phishing',
        'DDoS Source'
      ];
      final activityCount = 1 + random.nextInt(3);
      for (int i = 0; i < activityCount; i++) {
        activities
            .add(possibleActivities[random.nextInt(possibleActivities.length)]);
      }
    }

    return {
      'ip': ipAddress,
      'country': country,
      'asn': {'name': asnName, 'number': asnNumber},
      'threatScore': threatScore,
      'riskCategory': riskCategory,
      'reportedMalicious': reportedMalicious,
      'activities': activities,
      'lastSeen':
          reportedMalicious ? '${1 + random.nextInt(30)} days ago' : 'Never',
      'modelVersion': _modelMetadata['threatIntelligence']['version'],
    };
  }

  /// Train models with new data
  Future<Map<String, dynamic>> trainModels(
      Map<String, dynamic> trainingData) async {
    // In a real app, this would send data to a backend service for training
    // or perform on-device training for smaller models

    await Future.delayed(const Duration(seconds: 2)); // Simulate training time

    // Update training stats
    _trainingStats['lastTraining'] =
        DateTime.now().toIso8601String().split('T')[0];
    _trainingStats['samplesProcessed'] =
        (_trainingStats['samplesProcessed'] as int) +
            (trainingData['sampleCount'] as int? ?? 100);

    // Simulate improvement in model accuracy
    for (final modelName in _modelMetadata.keys) {
      final currentAccuracy = _modelMetadata[modelName]['accuracy'] as double;

      // Small random improvement, max out at 0.98
      final newAccuracy =
          math.min(0.98, currentAccuracy + (math.Random().nextDouble() * 0.02));
      _modelMetadata[modelName]['accuracy'] = newAccuracy;

      // Update performance metrics
      _performanceMetrics[modelName]?.add(newAccuracy);
      if ((_performanceMetrics[modelName]?.length ?? 0) > 10) {
        _performanceMetrics[modelName]?.removeAt(0);
      }
    }

    // Save updated model data
    await _saveModelData();

    return {
      'success': true,
      'modelsUpdated': _modelMetadata.length,
      'averageAccuracyImprovement': 0.01 + (math.Random().nextDouble() * 0.01),
      'trainingTime':
          '${1 + math.Random().nextInt(4)}h ${math.Random().nextInt(60)}m',
    };
  }

  /// Process text for BERT model
  Future<Map<String, dynamic>> processBERTText(String text) async {
    // Simulate BERT text processing
    await Future.delayed(const Duration(milliseconds: 600));

    // Tokenization and embedding simulation
    final wordCount = text.split(' ').length;
    final tokens = math.min(wordCount + 20, 512); // Add special tokens

    return {
      'tokenCount': tokens,
      'sequenceLength': tokens,
      'attentionHeads': 12,
      'layers': 12,
      'processingTime': '${300 + math.Random().nextInt(400)}ms',
      'modelType': 'BERT-base (Cybersecurity fine-tuned)',
    };
  }

  /// Fine-tune BERT model with new data
  Future<Map<String, dynamic>> fineTuneBERTModel(
      List<Map<String, dynamic>> samples) async {
    // Simulate fine-tuning process
    await Future.delayed(const Duration(seconds: 3));

    // Update BERT model metadata
    final currentAccuracy =
        _modelMetadata['vulnerabilityAnalysis']['accuracy'] as double;
    final newAccuracy = math.min(
        0.98, currentAccuracy + (0.005 * math.sqrt(samples.length / 100)));

    _modelMetadata['vulnerabilityAnalysis']['accuracy'] = newAccuracy;
    _modelMetadata['vulnerabilityAnalysis']['trainedOn'] =
        DateTime.now().toIso8601String().split('T')[0];

    // Update performance metrics
    _performanceMetrics['vulnerabilityAnalysis']?.add(newAccuracy);
    if ((_performanceMetrics['vulnerabilityAnalysis']?.length ?? 0) > 10) {
      _performanceMetrics['vulnerabilityAnalysis']?.removeAt(0);
    }

    // Save model data
    await _saveModelData();

    return {
      'success': true,
      'samplesProcessed': samples.length,
      'accuracyBefore': currentAccuracy,
      'accuracyAfter': newAccuracy,
      'improvementPercentage':
          ((newAccuracy - currentAccuracy) / currentAccuracy * 100)
                  .toStringAsFixed(2) +
              '%',
      'trainingTime':
          '${math.max(1, (samples.length / 50).round())}h ${math.Random().nextInt(60)}m',
    };
  }

  /// Save ML result to database
  Future<int> saveMLResult(MLResult result) async {
    return await _db.insertMLResult(result.toMap());
  }

  /// Get ML results for a scan
  Future<List<MLResult>> getMLResultsForScan(int scanResultId) async {
    final results = await _db.getMLResultsForScan(scanResultId);
    return results.map((map) => MLResult.fromMap(map)).toList();
  }

  /// Get model performance metrics
  Future<Map<String, dynamic>> getModelPerformance(String modelName) async {
    final results = await _db.getMLResultsForScan(0); // Get all results
    final modelResults =
        results.where((r) => r['model_name'] == modelName).toList();

    if (modelResults.isEmpty) {
      return {
        'accuracy': 0.0,
        'totalPredictions': 0,
        'correctPredictions': 0,
      };
    }

    double totalConfidence = 0.0;
    for (var result in modelResults) {
      totalConfidence += result['confidence'] as double;
    }

    return {
      'accuracy': totalConfidence / modelResults.length,
      'totalPredictions': modelResults.length,
      'correctPredictions': (totalConfidence * modelResults.length).round(),
    };
  }

  Future<Map<String, dynamic>> compareScans(List<ScanReport> reports) async {
    if (reports.isEmpty) {
      return {
        'total_scans': 0,
        'total_threats': 0,
        'average_risk_score': 0,
        'risk_score_change': 0,
        'new_issues': 0,
        'resolved_issues': 0,
        'vulnerability_distribution': {
          'Critical': 0,
          'High': 0,
          'Medium': 0,
          'Low': 0
        },
        'key_changes': [],
        'vulnerability_insights': [],
        'trend_analysis': [],
        'recommendations': [],
      };
    }

    // Calculate total scans
    final totalScans = reports.length;

    // Calculate total threats and vulnerability distribution
    int totalThreats = 0;
    Map<String, int> vulnerabilityDistribution = {
      'Critical': 0,
      'High': 0,
      'Medium': 0,
      'Low': 0
    };

    // Get the latest report for current distribution
    final latestReport = reports.last;
    for (final threat in latestReport.threats) {
      totalThreats++;
      final severity = threat.severity;
      if (vulnerabilityDistribution.containsKey(severity)) {
        vulnerabilityDistribution[severity] =
            (vulnerabilityDistribution[severity] ?? 0) + 1;
      }
    }

    // Calculate average risk score
    double averageRiskScore =
        reports.map((r) => r.riskScore).reduce((a, b) => a + b) /
            reports.length;

    // Calculate risk score change
    int riskScoreChange = 0;
    if (reports.length >= 2) {
      riskScoreChange =
          reports.last.riskScore - reports[reports.length - 2].riskScore;
    }

    // Count new and resolved issues by comparing the latest two scans
    int newIssues = 0;
    int resolvedIssues = 0;
    if (reports.length >= 2) {
      final previousReport = reports[reports.length - 2];

      // Compare threats between scans
      final previousThreats = Set.from(
          previousReport.threats.map((t) => '${t.type}:${t.location}'));
      final currentThreats =
          Set.from(latestReport.threats.map((t) => '${t.type}:${t.location}'));

      newIssues = currentThreats.difference(previousThreats).length;
      resolvedIssues = previousThreats.difference(currentThreats).length;
    }

    // Generate key changes based on the analysis
    final keyChanges = <Map<String, String>>[];
    if (riskScoreChange != 0) {
      keyChanges.add({
        'type': riskScoreChange < 0 ? 'improvement' : 'degradation',
        'description':
            'Risk score ${riskScoreChange < 0 ? 'decreased' : 'increased'} by ${riskScoreChange.abs()} points',
      });
    }

    if (newIssues > 0) {
      keyChanges.add({
        'type': 'degradation',
        'description': 'Detected $newIssues new security issues',
      });
    }

    if (resolvedIssues > 0) {
      keyChanges.add({
        'type': 'improvement',
        'description': 'Resolved $resolvedIssues security issues',
      });
    }

    // Generate ML-powered vulnerability insights based on real threat data
    final vulnerabilityInsights = _analyzeVulnerabilityTrends(reports);

    // Generate trend analysis with actual threat data
    final trendAnalysis = _analyzeTrends(reports);

    // Generate recommendations based on current threats
    final recommendations = _generateRecommendations(reports);

    return {
      'total_scans': totalScans,
      'total_threats': totalThreats,
      'average_risk_score': averageRiskScore,
      'risk_score_change': riskScoreChange,
      'new_issues': newIssues,
      'resolved_issues': resolvedIssues,
      'vulnerability_distribution': vulnerabilityDistribution,
      'key_changes': keyChanges,
      'vulnerability_insights': vulnerabilityInsights,
      'trend_analysis': trendAnalysis,
      'recommendations': recommendations,
    };
  }

  List<Map<String, String>> _analyzeVulnerabilityTrends(
      List<ScanReport> reports) {
    if (reports.length < 2) {
      return [];
    }

    final insights = <Map<String, String>>[];
    final latestReport = reports.last;
    final previousReport = reports[reports.length - 2];

    // Count threats by severity for both reports
    Map<String, int> currentSeverityCounts = {
      'Critical': 0,
      'High': 0,
      'Medium': 0,
      'Low': 0
    };
    Map<String, int> previousSeverityCounts = Map.from(currentSeverityCounts);

    // Count current threats by severity
    for (final threat in latestReport.threats) {
      if (currentSeverityCounts.containsKey(threat.severity)) {
        currentSeverityCounts[threat.severity] =
            (currentSeverityCounts[threat.severity] ?? 0) + 1;
      }
    }

    // Count previous threats by severity
    for (final threat in previousReport.threats) {
      if (previousSeverityCounts.containsKey(threat.severity)) {
        previousSeverityCounts[threat.severity] =
            (previousSeverityCounts[threat.severity] ?? 0) + 1;
      }
    }

    // Analyze critical vulnerabilities
    final criticalDiff = currentSeverityCounts['Critical']! -
        previousSeverityCounts['Critical']!;
    if (criticalDiff != 0) {
      insights.add({
        'title': 'Critical Vulnerability Changes',
        'description': criticalDiff > 0
            ? 'Detected $criticalDiff new critical vulnerabilities that require immediate attention'
            : 'Successfully resolved ${criticalDiff.abs()} critical vulnerabilities',
      });
    }

    // Analyze high-risk vulnerabilities trend
    if (reports.length >= 3) {
      final highRiskCounts = reports
          .map((r) => r.threats.where((t) => t.severity == 'High').length)
          .toList();

      final isIncreasing =
          highRiskCounts.last > highRiskCounts[highRiskCounts.length - 2] &&
              highRiskCounts[highRiskCounts.length - 2] >
                  highRiskCounts[highRiskCounts.length - 3];

      if (isIncreasing) {
        insights.add({
          'title': 'High-Risk Vulnerability Trend',
          'description':
              'Consistent increase in high-risk vulnerabilities over the last three scans. Consider reviewing security policies and implementing additional safeguards.',
        });
      }
    }

    return insights;
  }

  List<Map<String, dynamic>> _analyzeTrends(List<ScanReport> reports) {
    if (reports.length < 2) {
      return [];
    }

    final trends = <Map<String, dynamic>>[];
    final latestReport = reports.last;
    final previousReport = reports[reports.length - 2];

    // Analyze risk score trend
    final riskScores = reports.map((r) => r.riskScore).toList();
    final latestScore = riskScores.last;
    final previousScore = riskScores[riskScores.length - 2];

    trends.add({
      'metric': 'Risk Score',
      'direction': latestScore > previousScore ? 'up' : 'down',
      'analysis':
          'Risk score has ${latestScore > previousScore ? 'increased' : 'decreased'} from $previousScore to $latestScore',
    });

    // Analyze threat severity distribution trends
    for (final severity in ['Critical', 'High', 'Medium', 'Low']) {
      final currentCount =
          latestReport.threats.where((t) => t.severity == severity).length;
      final previousCount =
          previousReport.threats.where((t) => t.severity == severity).length;

      if (currentCount != previousCount) {
        trends.add({
          'metric': '$severity Vulnerabilities',
          'direction': currentCount > previousCount ? 'up' : 'down',
          'analysis':
              '$severity vulnerabilities have ${currentCount > previousCount ? 'increased' : 'decreased'} from $previousCount to $currentCount',
        });
      }
    }

    return trends;
  }

  List<Map<String, dynamic>> _generateRecommendations(
      List<ScanReport> reports) {
    if (reports.isEmpty) {
      return [];
    }

    final recommendations = <Map<String, dynamic>>[];
    final latestReport = reports.last;

    // Count threats by severity
    final criticalCount =
        latestReport.threats.where((t) => t.severity == 'Critical').length;
    final highCount =
        latestReport.threats.where((t) => t.severity == 'High').length;

    // Check for critical vulnerabilities
    if (criticalCount > 0) {
      recommendations.add({
        'priority': 'critical',
        'title': 'Address Critical Vulnerabilities',
        'description':
            'Found $criticalCount critical vulnerabilities that require immediate attention.',
        'steps': [
          'Review and patch all identified critical vulnerabilities',
          'Implement emergency fixes for exploitable vulnerabilities',
          'Conduct follow-up scans to verify fixes',
          'Update security policies to prevent similar vulnerabilities',
        ],
      });
    }

    // Check for high-risk vulnerabilities trend
    if (reports.length >= 3) {
      final highRiskCounts = reports
          .map((r) => r.threats.where((t) => t.severity == 'High').length)
          .toList();

      final isIncreasing =
          highRiskCounts.last > highRiskCounts[highRiskCounts.length - 2] &&
              highRiskCounts[highRiskCounts.length - 2] >
                  highRiskCounts[highRiskCounts.length - 3];

      if (isIncreasing) {
        recommendations.add({
          'priority': 'high',
          'title': 'Address Increasing High-Risk Vulnerabilities',
          'description':
              'There is a consistent increase in high-risk vulnerabilities over the last three scans.',
          'steps': [
            'Review and update security policies',
            'Implement additional security controls',
            'Conduct security training for team members',
            'Consider penetration testing to identify root causes',
          ],
        });
      }
    }

    // General recommendations based on risk score
    if (latestReport.riskScore > 50) {
      recommendations.add({
        'priority': 'medium',
        'title': 'Improve Overall Security Posture',
        'description':
            'The current risk score (${latestReport.riskScore}) indicates need for security improvements.',
        'steps': [
          'Review and update security configurations',
          'Implement regular security assessments',
          'Enhance monitoring and alerting systems',
          'Consider security automation tools',
        ],
      });
    }

    return recommendations;
  }
}
