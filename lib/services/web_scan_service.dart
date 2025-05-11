import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import '../models/scan_result.dart';
import '../models/threat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import '../models/scan_report.dart';
import '../screens/scan_report_screen.dart';
import 'database_service.dart';
import '../screens/enhanced_scan_report_popup.dart';
import 'url_validator_service.dart';

class WebScanException implements Exception {
  final String message;
  WebScanException(this.message);

  @override
  String toString() => message;
}

class WebScanResult extends ScanReport {
  final String url;
  final List<Map<String, dynamic>> findings;
  final List<Threat> threats;
  final int riskScore;
  final String summary;
  final Map<String, dynamic> scanMetadata;

  WebScanResult({
    required this.url,
    required this.findings,
    required this.threats,
    required this.riskScore,
    required this.summary,
    required this.scanMetadata,
  }) : super(
          target: url,
          timestamp: DateTime.now(),
          scanType: 'web',
          vulnerabilityDistribution:
              _calculateResultVulnerabilityDistribution(threats),
          findings: findings,
          threats: threats,
          riskScore: riskScore,
          summary: summary,
          recommendations: [],
          scanMetadata: scanMetadata,
          openPorts: [],
          scanDuration: 0,
        );

  static Map<String, int> _calculateResultVulnerabilityDistribution(
      List<Threat> threats) {
    final distribution = <String, int>{
      'Critical': 0,
      'High': 0,
      'Medium': 0,
      'Low': 0,
      'Info': 0,
    };

    for (final threat in threats) {
      distribution[threat.severity] = (distribution[threat.severity] ?? 0) + 1;
    }

    return distribution;
  }
}

class WebScanService {
  static final WebScanService _instance = WebScanService._internal();
  factory WebScanService() => _instance;
  WebScanService._internal();

  final DatabaseService _db = DatabaseService();
  final http.Client _client = http.Client();
  final URLValidatorService _urlValidator = URLValidatorService();
  String _currentTarget = '';
  final List<Map<String, dynamic>> _findings = [];

  Future<void> startScan(String target, BuildContext context) async {
    _currentTarget = target;
    _findings.clear();

    try {
      final validationResult = await _urlValidator.validateURL(target);
      if (!validationResult.isValid) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('URL validation failed: ${validationResult.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await scanUrl(validationResult.url!);
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => EnhancedScanReportPopup(
            report: result,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ScanReport> scanUrl(String url) async {
    try {
      final findings = <Map<String, dynamic>>[];
      var currentStep = 0;
      final totalSteps = 5;

      // Step 1: Initial connection and header analysis
      currentStep++;
      await Future.delayed(const Duration(seconds: 2));
      final response = await http.get(Uri.parse(url));
      
      // Check for potential SQL injection points
      final sqlInjectionFindings = _checkPotentialSQLInjection(url, response.body);
      findings.addAll(sqlInjectionFindings);

      // Step 2: Analyze headers
      currentStep++;
      await Future.delayed(const Duration(seconds: 2));
      final headerFindings = _analyzeHeaders(response.headers);
      findings.addAll(headerFindings);
      
      // Step 3: SSL analysis
      currentStep++;
      await Future.delayed(const Duration(seconds: 3));
      try {
        final sslFindings = await _generateSSLFindings(url);
        findings.addAll(sslFindings);
      } catch (e) {
        debugPrint('SSL analysis failed: $e');
        findings.add({
          'type': 'SSL Analysis Error',
          'severity': 'Medium',
          'description': 'Failed to complete SSL analysis',
          'location': 'SSL/TLS',
          'details': {'error': e.toString()},
          'recommendation': 'Try again later or use a different SSL analysis tool',
        });
      }
      
      // Step 4: Port scan
      currentStep++;
      await Future.delayed(const Duration(seconds: 3));
      try {
        final portFindings = await _generatePortScanFindings(url);
        findings.addAll(portFindings);
      } catch (e) {
        debugPrint('Port scan failed: $e');
        findings.add({
          'type': 'Port Scan Error',
          'severity': 'Medium',
          'description': 'Failed to complete port scan',
          'location': 'Network',
          'details': {'error': e.toString()},
          'recommendation': 'Check network connectivity and try again',
        });
      }
      
      // Step 5: Final analysis and report generation
      currentStep++;
      await Future.delayed(const Duration(seconds: 2));
      
      // Get threat intelligence (if available)
      Map<String, dynamic> threatIntel = {};
      try {
        final domain = Uri.parse(url).host;
        threatIntel = await fetchThreatIntel(domain, 'YOUR_VIRUSTOTAL_API_KEY');
      } catch (e) {
        debugPrint('Threat intelligence failed: $e');
      }

      // Get subdomains (if available)
      List<String> subdomains = [];
      try {
        final domain = Uri.parse(url).host;
        subdomains = await enumerateSubdomains(domain);
      } catch (e) {
        debugPrint('Subdomain enumeration failed: $e');
      }

      final threats = _convertFindingsToThreats(findings);
      final vulnDist = _calculateVulnerabilityDistribution();
      final riskScore = _calculateRiskScore();
      final summary = _generateSummary();

      return ScanReport(
        timestamp: DateTime.now(),
        target: url,
        scanType: 'web',
        findings: findings,
        vulnerabilityDistribution: vulnDist,
        threats: threats,
        riskScore: riskScore,
        summary: summary,
        scanMetadata: {
          'scan_duration': 12,
          'protocol': response.request?.url.scheme ?? 'https',
          'server': response.headers['server'] ?? 'Unknown',
          'headers': response.headers.entries.map((e) => '${e.key}: ${e.value}').toList(),
          'ssl_info': findings.where((f) => f['type'] == 'SSL Assessment').toList(),
          'threat_intelligence': threatIntel,
          'subdomains': subdomains,
        },
        openPorts: findings.where((f) => f['type'] == 'Open Port').toList(),
        scanDuration: 12,
        subdomains: subdomains,
        threatIntelligence: threatIntel,
      );
    } catch (e) {
      throw Exception('Failed to scan URL: $e');
    }
  }

  List<Map<String, dynamic>> _checkPotentialSQLInjection(String url, String html) {
    final findings = <Map<String, dynamic>>[];
    final uri = Uri.parse(url);
    
    // Check URL parameters
    if (uri.queryParameters.isNotEmpty) {
      final suspiciousParams = uri.queryParameters.entries.where((param) {
        final value = param.value.toLowerCase();
        return value.contains('select') || 
               value.contains('union') || 
               value.contains('insert') ||
               value.contains('delete') ||
               value.contains('update') ||
               value.contains('exec') ||
               value.contains('--') ||
               value.contains('/*') ||
               value.contains('*/');
      }).toList();

      if (suspiciousParams.isNotEmpty) {
        findings.add({
          'type': 'Potential SQL Injection',
          'severity': 'High',
          'description': 'URL contains suspicious parameters that could indicate SQL injection attempts',
          'location': 'URL Parameters',
          'details': {
            'parameters': suspiciousParams.map((p) => p.key).toList(),
            'values': suspiciousParams.map((p) => p.value).toList(),
            'risk': 'Parameters contain SQL-like patterns that may be used in injection attempts',
          },
          'recommendation': 'Implement proper input validation, use parameterized queries, and consider implementing WAF rules',
        });
      } else {
        findings.add({
          'type': 'Potential SQL Injection',
          'severity': 'Medium',
          'description': 'URL contains query parameters that could be vulnerable to SQL injection',
          'location': 'URL Parameters',
          'details': {
            'parameters': uri.queryParameters.keys.toList(),
            'risk': 'Parameters may be used in database queries without proper sanitization',
          },
          'recommendation': 'Implement proper input validation and use parameterized queries',
        });
      }
    }

    // Check for forms
    if (html.toLowerCase().contains('<form')) {
      final formFields = _extractFormFields(html);
      if (formFields.isNotEmpty) {
        // Check for common sensitive field names
        final sensitiveFields = formFields.where((field) {
          final lowerField = field.toLowerCase();
          return lowerField.contains('id') ||
                 lowerField.contains('user') ||
                 lowerField.contains('pass') ||
                 lowerField.contains('email') ||
                 lowerField.contains('name') ||
                 lowerField.contains('search') ||
                 lowerField.contains('query');
        }).toList();

        if (sensitiveFields.isNotEmpty) {
          findings.add({
            'type': 'Potential SQL Injection',
            'severity': 'High',
            'description': 'Forms found with sensitive fields that could be vulnerable to SQL injection',
            'location': 'Form Fields',
            'details': {
              'fields': sensitiveFields,
              'risk': 'Sensitive form fields may be used in database queries without proper sanitization',
              'common_attack_vectors': [
                'UNION-based attacks',
                'Error-based attacks',
                'Time-based blind attacks',
                'Boolean-based blind attacks'
              ],
            },
            'recommendation': 'Implement proper input validation, use parameterized queries, and consider implementing CSRF protection',
          });
        } else {
          findings.add({
            'type': 'Potential SQL Injection',
            'severity': 'Medium',
            'description': 'Forms found that could be vulnerable to SQL injection',
            'location': 'Form Fields',
            'details': {
              'fields': formFields,
              'risk': 'Form fields may be used in database queries without proper sanitization',
            },
            'recommendation': 'Implement proper input validation and use parameterized queries',
          });
        }
      }
    }

    // Check for database error messages
    final errorPatterns = [
      'sql syntax',
      'mysql error',
      'postgresql error',
      'oracle error',
      'sqlite error',
      'syntax error',
      'unclosed quotation mark',
      'unterminated string',
    ];

    for (final pattern in errorPatterns) {
      if (html.toLowerCase().contains(pattern)) {
        findings.add({
          'type': 'SQL Error Disclosure',
          'severity': 'High',
          'description': 'Database error messages are being displayed to users',
          'location': 'Error Messages',
          'details': {
            'pattern_found': pattern,
            'risk': 'Error messages may reveal database structure and implementation details',
          },
          'recommendation': 'Implement proper error handling and do not expose database errors to users',
        });
        break;
      }
    }

    return findings;
  }

  List<String> _extractFormFields(String html) {
    final fields = <String>[];
    final formFieldPattern = RegExp(r'''<input[^>]*name=['"]([^'"]+)['"]''');
    final matches = formFieldPattern.allMatches(html);
    for (final match in matches) {
      if (match.groupCount >= 1) {
        fields.add(match.group(1)!);
      }
    }
    return fields;
  }

  Future<List<Map<String, dynamic>>> _generateSSLFindings(String target) async {
    final findings = <Map<String, dynamic>>[];
    try {
      final sslLabsApi = 'https://api.ssllabs.com/api/v3';

      // Start new assessment
      final startResponse = await http.post(
        Uri.parse('$sslLabsApi/analyze'),
        body: {'host': target, 'startNew': 'on'},
      );

      if (startResponse.statusCode != 200) {
        throw WebScanException('Failed to start SSL Labs assessment');
      }

      final startData = json.decode(startResponse.body);
      final assessmentId = startData['id'];

      // Poll for results
      bool isComplete = false;
      Map<String, dynamic>? finalData;

      while (!isComplete) {
        await Future.delayed(const Duration(seconds: 5));
        final statusResponse = await http.get(
          Uri.parse('$sslLabsApi/analyze?id=$assessmentId'),
        );

        if (statusResponse.statusCode != 200) {
          throw WebScanException('Failed to get SSL Labs assessment status');
        }

        finalData = json.decode(statusResponse.body);
        isComplete = finalData?['status'] == 'READY';
      }

      if (finalData == null) {
        throw WebScanException('SSL Labs assessment failed');
      }

      final endpoints = finalData['endpoints'] as List? ?? [];

      for (var endpoint in endpoints) {
        final grade = endpoint['grade'] as String?;
        final protocols = endpoint['details']?['protocols'] as List?;
        final ciphers = endpoint['details']?['ciphers'] as List?;
        final cert = endpoint['details']?['cert'] as Map<String, dynamic>?;

        // Check for known vulnerabilities
        final vulnerabilities = endpoint['details']?['vulnBeast'] as bool?;
        final poodle = endpoint['details']?['poodle'] as bool?;
        final heartbleed = endpoint['details']?['heartbleed'] as bool?;
        final freak = endpoint['details']?['freak'] as bool?;
        final logjam = endpoint['details']?['logjam'] as bool?;
        final drown = endpoint['details']?['drownVulnerable'] as bool?;

        if (vulnerabilities == true || poodle == true || heartbleed == true || 
            freak == true || logjam == true || drown == true) {
          findings.add({
            'type': 'SSL Vulnerability',
            'severity': 'Critical',
            'description': 'Known SSL/TLS vulnerabilities detected',
            'location': 'SSL/TLS',
            'details': {
              'vulnerabilities': {
                'BEAST': vulnerabilities,
                'POODLE': poodle,
                'Heartbleed': heartbleed,
                'FREAK': freak,
                'Logjam': logjam,
                'DROWN': drown,
              },
            },
            'recommendation': 'Immediately patch or upgrade SSL/TLS implementation',
          });
        }

        // Check certificate validity
        if (cert != null) {
          final notBefore = DateTime.tryParse(cert['notBefore'] ?? '');
          final notAfter = DateTime.tryParse(cert['notAfter'] ?? '');
          final now = DateTime.now();

          if (notBefore != null && notAfter != null) {
            if (now.isBefore(notBefore)) {
              findings.add({
                'type': 'Certificate Validity',
                'severity': 'High',
                'description': 'Certificate is not yet valid',
                'location': 'SSL/TLS',
                'details': {
                  'valid_from': notBefore.toString(),
                  'valid_to': notAfter.toString(),
                },
                'recommendation': 'Update server time or wait until certificate becomes valid',
              });
            } else if (now.isAfter(notAfter)) {
              findings.add({
                'type': 'Certificate Validity',
                'severity': 'Critical',
                'description': 'Certificate has expired',
                'location': 'SSL/TLS',
                'details': {
                  'valid_from': notBefore.toString(),
                  'valid_to': notAfter.toString(),
                },
                'recommendation': 'Immediately renew the SSL certificate',
              });
            }
          }
        }

        // Check protocol versions
        final supportedProtocols = protocols?.map((p) => p['name'] as String).toList() ?? [];
        if (supportedProtocols.contains('TLS 1.0') || supportedProtocols.contains('TLS 1.1')) {
          findings.add({
            'type': 'Outdated Protocol',
            'severity': 'High',
            'description': 'Outdated TLS versions are supported',
            'location': 'SSL/TLS',
            'details': {
              'supported_protocols': supportedProtocols,
            },
            'recommendation': 'Disable support for TLS 1.0 and 1.1, use TLS 1.2 or higher',
          });
        }

        // Check cipher suites
        if (ciphers != null) {
          final List<String> weakCiphers = [];
          for (final cipher in ciphers) {
            final name = cipher['name'] as String?;
            if (name != null && (
                name.contains('RC4') ||
                name.contains('DES') ||
                name.contains('3DES') ||
                name.contains('MD5') ||
                name.contains('NULL') ||
                name.contains('EXPORT'))
            ) {
              weakCiphers.add(name);
            }
          }
          if (weakCiphers.isNotEmpty) {
            findings.add({
              'type': 'Weak Ciphers',
              'severity': 'High',
              'description': 'Weak cipher suites are supported',
              'location': 'SSL/TLS',
              'details': {
                'weak_ciphers': weakCiphers,
              },
              'recommendation': 'Disable weak cipher suites and use only strong ciphers',
            });
          }
        }

        // Add overall SSL assessment
        findings.add({
          'type': 'SSL Assessment',
          'severity': _getSeverityFromGrade(grade),
          'description': 'SSL/TLS configuration assessment',
          'location': 'SSL/TLS',
          'details': {
            'grade': grade ?? 'Unknown',
            'protocols': supportedProtocols,
            'ciphers': ciphers?.map((c) => c['name']).toList() ?? [],
          },
          'recommendation': _getSSLRecommendation(grade),
        });
      }

      return findings;
    } catch (e) {
      debugPrint('SSL/TLS check error: $e');
      return [];
    }
  }

  String _getSeverityFromGrade(String? grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return 'Low';
      case 'B':
        return 'Medium';
      case 'C':
        return 'High';
      default:
        return 'Critical';
    }
  }

  String _getSSLRecommendation(String? grade) {
    if (grade == null || grade.isEmpty) {
      return 'Unable to assess SSL configuration. Please verify SSL setup.';
    }
    
    final recommendations = <String>[];
    
    if (grade == 'A+' || grade == 'A') {
      recommendations.add('Current SSL configuration is strong.');
      recommendations.add('Continue monitoring for new vulnerabilities.');
      recommendations.add('Consider implementing HSTS if not already enabled.');
    } else {
      recommendations.add('Consider upgrading SSL configuration to achieve grade A or better.');
      recommendations.add('Disable support for outdated protocols (TLS 1.0, 1.1).');
      recommendations.add('Use only strong cipher suites (AES-GCM, ChaCha20).');
      recommendations.add('Implement HSTS with appropriate max-age.');
      recommendations.add('Ensure certificate is valid and not expiring soon.');
    }
    
    return recommendations.join(' ');
  }

  Future<List<Map<String, dynamic>>> _generatePortScanFindings(String target) async {
    final ports = [
      20, 21, 22, 23, 25, 53, 80, 110, 143, 443, 465, 587, 993, 995, 3306, 3389,
      5432, 8080, 8443, 27017, 6379, 9200, 9300, 11211, 27017, 5000, 5001, 5002,
      5003, 5004, 5005, 5006, 5007, 5008, 5009, 5010, 5011, 5012, 5013, 5014,
      5015, 5016, 5017, 5018, 5019, 5020, 5021, 5022, 5023, 5024, 5025, 5026,
      5027, 5028, 5029, 5030, 5031, 5032, 5033, 5034, 5035, 5036, 5037, 5038,
      5039, 5040, 5041, 5042, 5043, 5044, 5045, 5046, 5047, 5048, 5049, 5050
    ];
    final findings = <Map<String, dynamic>>[];

    for (final port in ports) {
      try {
        final socket = await Socket.connect(target, port,
            timeout: const Duration(seconds: 5));

        // Try to get service banner
        String? banner;
        try {
          socket.write('HEAD / HTTP/1.1\r\nHost: $target\r\n\r\n');
          final data = await socket.first;
          banner = utf8.decode(data);
        } catch (e) {
          // Try alternative banner grab for non-HTTP services
          try {
            socket.write('\r\n');
            final data = await socket.first;
            banner = utf8.decode(data);
          } catch (e) {
            // Ignore banner reading errors
          }
        }

        final serviceName = _getServiceName(port);
        final severity = _getPortSeverity(port);
        final protocol = _getProtocol(port);
        final vulnerabilities = _getCommonVulnerabilities(port);
        final version = _extractVersionFromBanner(banner);
        final exposedInfo = _analyzeBannerForExposedInfo(banner);

        findings.add({
          'type': 'Open Port',
          'severity': severity,
          'description': 'Port $port is open running $serviceName${version != null ? ' $version' : ''}',
          'location': 'Network',
          'details': {
            'port': port,
            'service': serviceName,
            'status': 'open',
            'banner': banner,
            'protocol': protocol,
            'version': version,
            'exposed_information': exposedInfo,
            'common_vulnerabilities': vulnerabilities,
            'risk_level': _getRiskLevel(port, version, exposedInfo),
            'attack_surface': _getAttackSurface(port, serviceName),
          },
          'recommendation': _getPortRecommendation(port, version, exposedInfo),
        });

        socket.destroy();
      } catch (e) {
        // Port is closed - no finding needed
      }
    }
    return findings;
  }

  String? _extractVersionFromBanner(String? banner) {
    if (banner == null) return null;
    
    final versionPatterns = [
      RegExp(r'Server: ([^\r\n]+)'),
      RegExp(r'Apache/([\d.]+)'),
      RegExp(r'nginx/([\d.]+)'),
      RegExp(r'OpenSSH_([\d.]+)'),
      RegExp(r'MySQL/([\d.]+)'),
      RegExp(r'PostgreSQL/([\d.]+)'),
      RegExp(r'MongoDB/([\d.]+)'),
      RegExp(r'Redis/([\d.]+)'),
    ];

    for (final pattern in versionPatterns) {
      final match = pattern.firstMatch(banner);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  List<String> _analyzeBannerForExposedInfo(String? banner) {
    if (banner == null) return [];
    
    final exposedInfo = <String>[];
    
    // Check for server software
    if (banner.contains('Server:')) {
      exposedInfo.add('Server software information');
    }
    
    // Check for OS information
    if (banner.contains('OS:') || banner.contains('Operating System:')) {
      exposedInfo.add('Operating system information');
    }
    
    // Check for version information
    if (banner.contains('Version:') || banner.contains('v.')) {
      exposedInfo.add('Software version information');
    }
    
    // Check for build information
    if (banner.contains('Build:') || banner.contains('Built:')) {
      exposedInfo.add('Build information');
    }
    
    // Check for configuration information
    if (banner.contains('Config:') || banner.contains('Configuration:')) {
      exposedInfo.add('Configuration information');
    }
    
    return exposedInfo;
  }

  String _getRiskLevel(int port, String? version, List<String> exposedInfo) {
    if (exposedInfo.isNotEmpty) {
      return 'High';
    }
    
    final criticalPorts = [21, 23, 3306, 5432, 27017, 6379];
    if (criticalPorts.contains(port)) {
      return 'High';
    }
    
    if (version != null) {
      // Check for known vulnerable versions
      if (_isKnownVulnerableVersion(port, version)) {
        return 'Critical';
      }
    }
    
    return 'Low';
  }

  bool _isKnownVulnerableVersion(int port, String version) {
    // This is a simplified version - in a real implementation, you would
    // check against a database of known vulnerabilities
    final vulnerableVersions = {
      22: ['7.0', '7.1', '7.2'], // OpenSSH
      3306: ['5.0', '5.1', '5.5'], // MySQL
      5432: ['9.0', '9.1', '9.2'], // PostgreSQL
      27017: ['2.0', '2.2', '2.4'], // MongoDB
      6379: ['2.0', '2.2', '2.4'], // Redis
    };

    final versions = vulnerableVersions[port];
    if (versions != null) {
      return versions.any((v) => version.startsWith(v));
    }
    return false;
  }

  Map<String, dynamic> _getAttackSurface(int port, String service) {
    return {
      'remote_access': _isRemoteAccessPort(port),
      'data_storage': _isDataStoragePort(port),
      'authentication': _isAuthenticationPort(port),
      'management': _isManagementPort(port),
      'common_attack_vectors': _getCommonAttackVectors(port, service),
    };
  }

  bool _isRemoteAccessPort(int port) {
    return [22, 23, 3389].contains(port);
  }

  bool _isDataStoragePort(int port) {
    return [3306, 5432, 27017, 6379].contains(port);
  }

  bool _isAuthenticationPort(int port) {
    return [389, 636, 1812, 1813].contains(port);
  }

  bool _isManagementPort(int port) {
    return [8080, 8443, 5000, 5001].contains(port);
  }

  List<String> _getCommonAttackVectors(int port, String service) {
    final vectors = <String>[];
    
    if (_isRemoteAccessPort(port)) {
      vectors.addAll([
        'Brute force attacks',
        'Default credentials',
        'Weak authentication',
      ]);
    }
    
    if (_isDataStoragePort(port)) {
      vectors.addAll([
        'SQL injection',
        'NoSQL injection',
        'Data exfiltration',
      ]);
    }
    
    if (_isAuthenticationPort(port)) {
      vectors.addAll([
        'Credential stuffing',
        'Password spraying',
        'LDAP injection',
      ]);
    }
    
    if (_isManagementPort(port)) {
      vectors.addAll([
        'Unauthorized access',
        'Configuration manipulation',
        'Privilege escalation',
      ]);
    }
    
    return vectors;
  }

  String _getPortRecommendation(int port, String? version, List<String> exposedInfo) {
    final recommendations = <String>[];
    
    if (exposedInfo.isNotEmpty) {
      recommendations.add('Configure service to hide sensitive information in banners.');
    }
    
    if (version != null && _isKnownVulnerableVersion(port, version)) {
      recommendations.add('Upgrade to a newer, secure version of the service.');
    }
    
    if (_isRemoteAccessPort(port)) {
      recommendations.add('Implement strong authentication and access controls.');
      recommendations.add('Consider using key-based authentication instead of passwords.');
    }
    
    if (_isDataStoragePort(port)) {
      recommendations.add('Implement proper access controls and encryption.');
      recommendations.add('Use parameterized queries to prevent injection attacks.');
    }
    
    if (_isAuthenticationPort(port)) {
      recommendations.add('Implement rate limiting and account lockout policies.');
      recommendations.add('Use strong password policies and multi-factor authentication.');
    }
    
    if (_isManagementPort(port)) {
      recommendations.add('Restrict access to management interfaces.');
      recommendations.add('Implement proper authentication and authorization.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Review if this port needs to be open and restrict access if not necessary.');
    }
    
    return recommendations.join(' ');
  }

  String _getProtocol(int port) {
    switch (port) {
      case 20:
      case 21:
        return 'FTP';
      case 22:
        return 'SSH';
      case 23:
        return 'Telnet';
      case 25:
      case 465:
      case 587:
        return 'SMTP';
      case 53:
        return 'DNS';
      case 80:
      case 8080:
        return 'HTTP';
      case 110:
        return 'POP3';
      case 143:
        return 'IMAP';
      case 443:
      case 8443:
        return 'HTTPS';
      case 993:
        return 'IMAPS';
      case 995:
        return 'POP3S';
      case 3306:
        return 'MySQL';
      case 3389:
        return 'RDP';
      case 5432:
        return 'PostgreSQL';
      default:
        return 'Unknown';
    }
  }

  List<String> _getCommonVulnerabilities(int port) {
    switch (port) {
      case 21:
        return [
          'Anonymous FTP access',
          'Weak authentication',
          'Directory traversal',
        ];
      case 22:
        return [
          'Weak SSH configuration',
          'Default credentials',
          'Outdated SSH version',
        ];
      case 23:
        return [
          'Cleartext communication',
          'No encryption',
          'Default credentials',
        ];
      case 25:
      case 465:
      case 587:
        return [
          'Open relay',
          'Spam abuse',
          'Weak authentication',
        ];
      case 3306:
      case 5432:
        return [
          'Default credentials',
          'Weak authentication',
          'Exposed database',
        ];
      case 3389:
        return [
          'Weak RDP security',
          'Default credentials',
          'BlueKeep vulnerability',
        ];
      default:
        return [];
    }
  }

  String _getPortSeverity(int port) {
    final criticalPorts = [21, 23, 3306, 5432];
    if (criticalPorts.contains(port)) return 'High';
    return 'Low';
  }

  List<Map<String, dynamic>> _analyzeHeaders(Map<String, String> headers) {
    final findings = <Map<String, dynamic>>[];

    // Check security headers
    _checkSecurityHeader(findings, headers, 'Content-Security-Policy',
        'Critical security header missing', 'High');
    _checkSecurityHeader(findings, headers, 'X-Content-Type-Options',
        'Security header missing', 'Medium');
    _checkSecurityHeader(findings, headers, 'X-Frame-Options',
        'Clickjacking protection missing', 'Medium');
    _checkSecurityHeader(findings, headers, 'Strict-Transport-Security',
        'HSTS not enabled', 'High');
    _checkSecurityHeader(findings, headers, 'X-XSS-Protection',
        'XSS protection missing', 'Medium');
    _checkSecurityHeader(
        findings, headers, 'Referrer-Policy', 'Referrer policy not set', 'Low');
    _checkSecurityHeader(findings, headers, 'Permissions-Policy',
        'Permissions policy not set', 'Low');

    // Check for insecure headers
    _checkInsecureHeader(
        findings, headers, 'Server', 'Server information disclosure', 'Low');
    _checkInsecureHeader(findings, headers, 'X-Powered-By',
        'Technology information disclosure', 'Low');
    _checkInsecureHeader(findings, headers, 'X-AspNet-Version',
        'Framework version disclosure', 'Low');
    _checkInsecureHeader(findings, headers, 'X-AspNetMvc-Version',
        'Framework version disclosure', 'Low');

    // Check for missing cache control
    if (!headers.containsKey('cache-control')) {
      findings.add({
        'type': 'Missing Cache Control',
        'severity': 'Low',
        'description': 'Cache control header not set',
        'location': 'HTTP Headers',
        'details': {
          'impact': 'May lead to caching issues and security problems',
          'current_state': 'Not implemented',
        },
        'recommendation': 'Implement appropriate cache control headers',
      });
    }

    return findings;
  }

  void _checkSecurityHeader(
      List<Map<String, dynamic>> findings,
      Map<String, String> headers,
      String header,
      String issue,
      String severity) {
    if (!headers.containsKey(header.toLowerCase())) {
      findings.add({
        'type': 'Missing Security Header',
        'severity': severity,
        'description': issue,
        'location': 'HTTP Headers',
        'details': {
          'header': header,
          'impact': _getHeaderImpact(header),
          'current_state': 'Not implemented',
          'risk': 'Increased vulnerability to specific attacks',
        },
        'recommendation': _getHeaderRecommendation(header),
      });
    }
  }

  String _getHeaderImpact(String header) {
    switch (header) {
      case 'Content-Security-Policy':
        return 'Vulnerable to XSS and other injection attacks';
      case 'X-Content-Type-Options':
        return 'Potential MIME type sniffing attacks';
      case 'X-Frame-Options':
        return 'Vulnerable to clickjacking attacks';
      case 'Strict-Transport-Security':
        return 'Possible downgrade attacks and insecure connections';
      default:
        return 'Security posture weakened';
    }
  }

  String _getHeaderRecommendation(String header) {
    switch (header) {
      case 'Content-Security-Policy':
        return 'Implement a strict Content Security Policy to prevent XSS attacks';
      case 'X-Content-Type-Options':
        return 'Add X-Content-Type-Options: nosniff to prevent MIME type sniffing';
      case 'X-Frame-Options':
        return 'Set X-Frame-Options to DENY or SAMEORIGIN to prevent clickjacking';
      case 'Strict-Transport-Security':
        return 'Enable HSTS with a long max-age to enforce HTTPS connections';
      default:
        return 'Add the ${header} header with appropriate values';
    }
  }

  void _checkInsecureHeader(
      List<Map<String, dynamic>> findings,
      Map<String, String> headers,
      String header,
      String issue,
      String severity) {
    if (headers.containsKey(header.toLowerCase())) {
      findings.add({
        'type': 'Information Disclosure',
        'severity': severity,
        'description': issue,
        'location': 'HTTP Headers',
        'details': {
          'header': header,
          'value': headers[header.toLowerCase()],
          'impact': 'Reveals potentially sensitive information',
          'current_state': 'Present',
        },
        'recommendation':
            'Remove or modify the $header header to prevent information disclosure',
      });
    }
  }

  List<Threat> _convertFindingsToThreats(List<Map<String, dynamic>> findings) {
    return findings
        .map((finding) => Threat(
              name: finding['name'] ?? finding['type'] ?? 'Unknown Issue',
              severity: finding['severity'] as String,
              location: finding['location'] as String,
              description: finding['description'] as String,
              recommendation: finding['recommendation'] as String,
              detectedAt: DateTime.now(),
              type: finding['type'] as String,
            ))
        .toList();
  }

  Map<String, int> _calculateVulnerabilityDistribution() {
    return {
      'Critical': _findings.where((f) => f['severity'] == 'Critical').length,
      'High': _findings.where((f) => f['severity'] == 'High').length,
      'Medium': _findings.where((f) => f['severity'] == 'Medium').length,
      'Low': _findings.where((f) => f['severity'] == 'Low').length,
    };
  }

  int _calculateRiskScore() {
    int score = 0;
    final weights = {
      'Critical': 25,
      'High': 15,
      'Medium': 8,
      'Low': 3,
    };

    for (final finding in _findings) {
      final severity = finding['severity'] as String;
      final weight = weights[severity] ?? 0;
      score += weight;
    }

    return score.clamp(0, 100);
  }

  String _generateSummary() {
    final totalVulnerabilities = _findings.length;
    if (totalVulnerabilities == 0) {
      return 'No vulnerabilities were found in the scan.';
    }

    final buffer = StringBuffer();
    buffer.write('Found $totalVulnerabilities vulnerabilities: ');

    final criticalCount = _findings.where((f) => f['severity'] == 'Critical').length;
    final highCount = _findings.where((f) => f['severity'] == 'High').length;
    final mediumCount = _findings.where((f) => f['severity'] == 'Medium').length;
    final lowCount = _findings.where((f) => f['severity'] == 'Low').length;

    if (criticalCount > 0) buffer.write('$criticalCount critical, ');
    if (highCount > 0) buffer.write('$highCount high risk, ');
    if (mediumCount > 0) buffer.write('$mediumCount medium risk, ');
    if (lowCount > 0) buffer.write('$lowCount low risk. ');

    if (criticalCount > 0 || highCount > 0) {
      buffer.write('Immediate attention required.');
    } else if (mediumCount > 0) {
      buffer.write('Address medium risk issues soon.');
    } else {
      buffer.write('Low risk issues can be addressed as time permits.');
    }

    return buffer.toString();
  }

  String _getServiceName(int port) {
    switch (port) {
      case 20:
      case 21:
        return 'FTP';
      case 22:
        return 'SSH';
      case 23:
        return 'Telnet';
      case 25:
      case 465:
      case 587:
        return 'SMTP';
      case 53:
        return 'DNS';
      case 80:
        return 'HTTP';
      case 110:
        return 'POP3';
      case 143:
        return 'IMAP';
      case 443:
        return 'HTTPS';
      case 993:
        return 'IMAP SSL';
      case 995:
        return 'POP3 SSL';
      case 3306:
        return 'MySQL';
      case 3389:
        return 'RDP';
      case 5432:
        return 'PostgreSQL';
      case 8080:
      case 8443:
        return 'HTTP Alternate';
      default:
        return 'Unknown';
    }
  }
}

Future<List<String>> enumerateSubdomains(String domain) async {
  try {
    final response = await http
        .get(Uri.parse('https://api.sublist3r.com/search.php?domain=$domain'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<String>.from(data);
    }
  } catch (e) {
    print('Subdomain enumeration error: $e');
  }
  return [];
}

Future<Map<String, dynamic>> fetchThreatIntel(
    String ipOrDomain, String apiKey) async {
  try {
    final response = await http.get(
      Uri.parse('https://www.virustotal.com/api/v3/ip_addresses/$ipOrDomain'),
      headers: {'x-apikey': apiKey},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'Reputation': data['data']['attributes']['reputation'].toString(),
        'Harmless': data['data']['attributes']['last_analysis_stats']
                ['harmless']
            .toString(),
        'Malicious': data['data']['attributes']['last_analysis_stats']
                ['malicious']
            .toString(),
        'Suspicious': data['data']['attributes']['last_analysis_stats']
                ['suspicious']
            .toString(),
      };
    }
  } catch (e) {
    print('Threat intelligence error: $e');
  }
  return {};
}

Future<Map<String, dynamic>> analyzeWithAI(
    Map<String, dynamic> scanResults) async {
  final findings = scanResults['findings'] as List<dynamic>? ?? [];
  final openPorts = scanResults['openPorts'] as List<dynamic>? ?? [];
  final threatIntel =
      scanResults['threatIntelligence'] as Map<String, dynamic>? ?? {};

  int score = 0;

  // Add points for each finding by severity
  for (var finding in findings) {
    switch ((finding['severity'] ?? '').toLowerCase()) {
      case 'critical':
        score += 30;
        break;
      case 'high':
        score += 20;
        break;
      case 'medium':
        score += 10;
        break;
      case 'low':
        score += 5;
        break;
    }
  }

  // Add points for open ports
  score += openPorts.length * 3;

  // Add points for threat intelligence
  if (threatIntel['Malicious'] != null) {
    score += int.tryParse(threatIntel['Malicious'].toString()) ?? 0;
  }
  if (threatIntel['Suspicious'] != null) {
    score += int.tryParse(threatIntel['Suspicious'].toString()) ?? 0;
  }

  // Cap score at 100
  score = score.clamp(0, 100);

  // Trend and confidence (simple logic)
  String trend = score > 70 ? 'Rising' : (score > 40 ? 'Stable' : 'Low');
  String confidence =
      findings.length > 5 ? 'High' : (findings.length > 2 ? 'Medium' : 'Low');

  return {
    'AI Risk Score': score,
    'Trend': trend,
    'Confidence': confidence,
  };
}
