import 'package:flutter/foundation.dart';
import 'threat.dart';

class ScanReport {
  final String id;
  final DateTime timestamp;
  final String target;
  final String scanType;
  final Map<String, int> vulnerabilityDistribution;
  final List<Map<String, dynamic>> findings;
  final List<Threat> threats;
  final Map<String, bool> enabledOptions;
  final int riskScore;
  final String summary;
  final List<Map<String, dynamic>> recommendations;
  final Map<String, dynamic> scanMetadata;
  final List<Map<String, dynamic>> openPorts;
  final int scanDuration;
  final String? ipAddress;
  final List<String>? dnsRecords;
  final List<String>? subdomains;
  final Map<String, dynamic>? threatIntelligence;
  final Map<String, dynamic>? aiScorecard;

  ScanReport({
    String? id,
    required this.timestamp,
    required this.target,
    this.scanType = 'web',
    required this.vulnerabilityDistribution,
    required this.findings,
    required this.threats,
    Map<String, bool>? enabledOptions,
    required this.riskScore,
    required this.summary,
    List<Map<String, dynamic>>? recommendations,
    required this.scanMetadata,
    required this.openPorts,
    required this.scanDuration,
    this.ipAddress,
    this.dnsRecords,
    this.subdomains,
    this.threatIntelligence,
    this.aiScorecard,
  })  : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        this.enabledOptions = enabledOptions ?? {},
        this.recommendations = recommendations ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'target': target,
      'scanType': scanType,
      'vulnerabilityDistribution': vulnerabilityDistribution,
      'findings': findings,
      'threats': threats.map((e) => e.toJson()).toList(),
      'enabledOptions': enabledOptions,
      'riskScore': riskScore,
      'summary': summary,
      'recommendations': recommendations,
      'scanMetadata': scanMetadata,
      'openPorts': openPorts,
      'scanDuration': scanDuration,
      'ipAddress': ipAddress,
      'dnsRecords': dnsRecords,
      'subdomains': subdomains,
      'threatIntelligence': threatIntelligence,
      'aiScorecard': aiScorecard,
    };
  }

  factory ScanReport.fromMap(Map<String, dynamic> map) {
    return ScanReport(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      target: map['target'] as String,
      scanType: map['scanType'] as String,
      vulnerabilityDistribution:
          Map<String, int>.from(map['vulnerabilityDistribution'] as Map),
      findings: List<Map<String, dynamic>>.from(map['findings'] as List),
      threats: (map['threats'] as List)
          .map((e) => Threat.fromJson(e as Map<String, dynamic>))
          .toList(),
      enabledOptions: Map<String, bool>.from(map['enabledOptions'] as Map),
      riskScore: map['riskScore'] as int,
      summary: map['summary'] as String,
      recommendations:
          List<Map<String, dynamic>>.from(map['recommendations'] as List),
      scanMetadata: Map<String, dynamic>.from(map['scanMetadata'] as Map),
      openPorts: List<Map<String, dynamic>>.from(map['openPorts'] as List),
      scanDuration: map['scanDuration'] as int,
      ipAddress: map['ipAddress'] as String?,
      dnsRecords: map['dnsRecords'] != null
          ? List<String>.from(map['dnsRecords'] as List)
          : null,
      subdomains: map['subdomains'] != null
          ? List<String>.from(map['subdomains'])
          : null,
      threatIntelligence: map['threatIntelligence'] != null
          ? Map<String, dynamic>.from(map['threatIntelligence'])
          : null,
      aiScorecard: map['aiScorecard'] != null
          ? Map<String, dynamic>.from(map['aiScorecard'])
          : null,
    );
  }

  factory ScanReport.fromJson(Map<String, dynamic> json) {
    return ScanReport(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      target: json['target'] as String,
      scanType: json['scanType'] as String,
      vulnerabilityDistribution:
          Map<String, int>.from(json['vulnerabilityDistribution'] as Map),
      findings: List<Map<String, dynamic>>.from(json['findings'] as List),
      threats: (json['threats'] as List)
          .map((threat) => Threat.fromJson(threat as Map<String, dynamic>))
          .toList(),
      enabledOptions: Map<String, bool>.from(json['enabledOptions'] as Map),
      riskScore: (json['riskScore'] as num).toInt(),
      summary: json['summary'] as String,
      recommendations: json['recommendations'] != null
          ? List<Map<String, dynamic>>.from(json['recommendations'] as List)
          : null,
      scanMetadata: Map<String, dynamic>.from(json['scanMetadata'] as Map),
      openPorts: List<Map<String, dynamic>>.from(json['openPorts'] as List),
      scanDuration: (json['scanDuration'] as num).toInt(),
      ipAddress: json['ipAddress'] as String?,
      dnsRecords: json['dnsRecords'] != null
          ? List<String>.from(json['dnsRecords'] as List)
          : null,
      subdomains: json['subdomains'] != null
          ? List<String>.from(json['subdomains'])
          : null,
      threatIntelligence: json['threatIntelligence'] != null
          ? Map<String, dynamic>.from(json['threatIntelligence'])
          : null,
      aiScorecard: json['aiScorecard'] != null
          ? Map<String, dynamic>.from(json['aiScorecard'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'target': target,
      'scanType': scanType,
      'vulnerabilityDistribution': vulnerabilityDistribution,
      'findings': findings,
      'threats': threats.map((e) => e.toJson()).toList(),
      'enabledOptions': enabledOptions,
      'riskScore': riskScore,
      'summary': summary,
      'recommendations': recommendations,
      'scanMetadata': scanMetadata,
      'openPorts': openPorts,
      'scanDuration': scanDuration,
      'ipAddress': ipAddress,
      'dnsRecords': dnsRecords,
      'subdomains': subdomains,
      'threatIntelligence': threatIntelligence,
      'aiScorecard': aiScorecard,
    };
  }
}
