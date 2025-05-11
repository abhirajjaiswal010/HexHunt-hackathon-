import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'threat.dart';

class HostInformation {
  final String ipAddress;
  final String? hostname;
  final String? operatingSystem;
  final String? geoLocation;
  final String? ispInfo;

  HostInformation({
    required this.ipAddress,
    this.hostname,
    this.operatingSystem,
    this.geoLocation,
    this.ispInfo,
  });

  Map<String, dynamic> toJson() => {
        'ipAddress': ipAddress,
        'hostname': hostname,
        'operatingSystem': operatingSystem,
        'geoLocation': geoLocation,
        'ispInfo': ispInfo,
      };

  factory HostInformation.fromJson(Map<String, dynamic> json) =>
      HostInformation(
        ipAddress: json['ipAddress'],
        hostname: json['hostname'],
        operatingSystem: json['operatingSystem'],
        geoLocation: json['geoLocation'],
        ispInfo: json['ispInfo'],
      );
}

class PortScanResult {
  final int portNumber;
  final String protocol;
  final String serviceName;
  final String? serviceVersion;
  final String status;
  final String? detectedTechnology;
  final Map<String, dynamic>? sslInfo;

  PortScanResult({
    required this.portNumber,
    required this.protocol,
    required this.serviceName,
    this.serviceVersion,
    required this.status,
    this.detectedTechnology,
    this.sslInfo,
  });

  Map<String, dynamic> toJson() => {
        'portNumber': portNumber,
        'protocol': protocol,
        'serviceName': serviceName,
        'serviceVersion': serviceVersion,
        'status': status,
        'detectedTechnology': detectedTechnology,
        'sslInfo': sslInfo,
      };

  factory PortScanResult.fromJson(Map<String, dynamic> json) => PortScanResult(
        portNumber: json['portNumber'],
        protocol: json['protocol'],
        serviceName: json['serviceName'],
        serviceVersion: json['serviceVersion'],
        status: json['status'],
        detectedTechnology: json['detectedTechnology'],
        sslInfo: json['sslInfo'],
      );
}

class VulnerabilityAnalysis {
  final double vulnerabilityScore;
  final List<String> cveIds;
  final Map<String, double> cvssScores;
  final Map<String, String> cveDescriptions;
  final bool hasExploit;
  final String threatLevel;
  final double confidenceScore;

  VulnerabilityAnalysis({
    required this.vulnerabilityScore,
    required this.cveIds,
    required this.cvssScores,
    required this.cveDescriptions,
    required this.hasExploit,
    required this.threatLevel,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() => {
        'vulnerabilityScore': vulnerabilityScore,
        'cveIds': cveIds,
        'cvssScores': cvssScores,
        'cveDescriptions': cveDescriptions,
        'hasExploit': hasExploit,
        'threatLevel': threatLevel,
        'confidenceScore': confidenceScore,
      };

  factory VulnerabilityAnalysis.fromJson(Map<String, dynamic> json) =>
      VulnerabilityAnalysis(
        vulnerabilityScore: json['vulnerabilityScore'],
        cveIds: List<String>.from(json['cveIds']),
        cvssScores: Map<String, double>.from(json['cvssScores']),
        cveDescriptions: Map<String, String>.from(json['cveDescriptions']),
        hasExploit: json['hasExploit'],
        threatLevel: json['threatLevel'],
        confidenceScore: json['confidenceScore'],
      );
}

class ThreatIntelligence {
  final String ipReputation;
  final bool isBlacklisted;
  final List<String> knownMaliciousActivities;
  final Map<String, dynamic> reputationScores;

  ThreatIntelligence({
    required this.ipReputation,
    required this.isBlacklisted,
    required this.knownMaliciousActivities,
    required this.reputationScores,
  });

  Map<String, dynamic> toJson() => {
        'ipReputation': ipReputation,
        'isBlacklisted': isBlacklisted,
        'knownMaliciousActivities': knownMaliciousActivities,
        'reputationScores': reputationScores,
      };

  factory ThreatIntelligence.fromJson(Map<String, dynamic> json) =>
      ThreatIntelligence(
        ipReputation: json['ipReputation'],
        isBlacklisted: json['isBlacklisted'],
        knownMaliciousActivities:
            List<String>.from(json['knownMaliciousActivities']),
        reputationScores: json['reputationScores'],
      );
}

class AnomalyDetection {
  final List<String> flaggedBehaviors;
  final Map<String, double> abnormalityScores;
  final String aiAnalysis;

  AnomalyDetection({
    required this.flaggedBehaviors,
    required this.abnormalityScores,
    required this.aiAnalysis,
  });

  Map<String, dynamic> toJson() => {
        'flaggedBehaviors': flaggedBehaviors,
        'abnormalityScores': abnormalityScores,
        'aiAnalysis': aiAnalysis,
      };

  factory AnomalyDetection.fromJson(Map<String, dynamic> json) =>
      AnomalyDetection(
        flaggedBehaviors: List<String>.from(json['flaggedBehaviors']),
        abnormalityScores: Map<String, double>.from(json['abnormalityScores']),
        aiAnalysis: json['aiAnalysis'],
      );
}

class ActionableRecommendation {
  final String category;
  final String description;
  final String priority;
  final List<String> steps;
  final Map<String, dynamic>? additionalInfo;

  ActionableRecommendation({
    required this.category,
    required this.description,
    required this.priority,
    required this.steps,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
        'priority': priority,
        'steps': steps,
        'additionalInfo': additionalInfo,
      };

  factory ActionableRecommendation.fromJson(Map<String, dynamic> json) =>
      ActionableRecommendation(
        category: json['category'],
        description: json['description'],
        priority: json['priority'],
        steps: List<String>.from(json['steps']),
        additionalInfo: json['additionalInfo'],
      );
}

class DetailedScanReport {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String target;
  final String scanType;
  final String scannerVersion;
  final String signatureVersion;

  final HostInformation hostInfo;
  final List<PortScanResult> portScanResults;
  final VulnerabilityAnalysis vulnerabilityAnalysis;
  final List<String> discoveredSubdomains;
  final ThreatIntelligence threatIntelligence;
  final AnomalyDetection anomalyDetection;

  final int totalIpsScanned;
  final int totalOpenPorts;
  final int criticalVulnerabilities;
  final int hostsWithExploits;
  final Duration scanDuration;

  final List<ActionableRecommendation> recommendations;

  DetailedScanReport({
    String? id,
    required this.startTime,
    required this.endTime,
    required this.target,
    required this.scanType,
    required this.scannerVersion,
    required this.signatureVersion,
    required this.hostInfo,
    required this.portScanResults,
    required this.vulnerabilityAnalysis,
    required this.discoveredSubdomains,
    required this.threatIntelligence,
    required this.anomalyDetection,
    required this.totalIpsScanned,
    required this.totalOpenPorts,
    required this.criticalVulnerabilities,
    required this.hostsWithExploits,
    required this.scanDuration,
    required this.recommendations,
  }) : this.id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'target': target,
        'scanType': scanType,
        'scannerVersion': scannerVersion,
        'signatureVersion': signatureVersion,
        'hostInfo': hostInfo.toJson(),
        'portScanResults': portScanResults.map((p) => p.toJson()).toList(),
        'vulnerabilityAnalysis': vulnerabilityAnalysis.toJson(),
        'discoveredSubdomains': discoveredSubdomains,
        'threatIntelligence': threatIntelligence.toJson(),
        'anomalyDetection': anomalyDetection.toJson(),
        'totalIpsScanned': totalIpsScanned,
        'totalOpenPorts': totalOpenPorts,
        'criticalVulnerabilities': criticalVulnerabilities,
        'hostsWithExploits': hostsWithExploits,
        'scanDuration': scanDuration.inSeconds,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
      };

  factory DetailedScanReport.fromJson(Map<String, dynamic> json) =>
      DetailedScanReport(
        id: json['id'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        target: json['target'],
        scanType: json['scanType'],
        scannerVersion: json['scannerVersion'],
        signatureVersion: json['signatureVersion'],
        hostInfo: HostInformation.fromJson(json['hostInfo']),
        portScanResults: (json['portScanResults'] as List)
            .map((p) => PortScanResult.fromJson(p))
            .toList(),
        vulnerabilityAnalysis:
            VulnerabilityAnalysis.fromJson(json['vulnerabilityAnalysis']),
        discoveredSubdomains: List<String>.from(json['discoveredSubdomains']),
        threatIntelligence:
            ThreatIntelligence.fromJson(json['threatIntelligence']),
        anomalyDetection: AnomalyDetection.fromJson(json['anomalyDetection']),
        totalIpsScanned: json['totalIpsScanned'],
        totalOpenPorts: json['totalOpenPorts'],
        criticalVulnerabilities: json['criticalVulnerabilities'],
        hostsWithExploits: json['hostsWithExploits'],
        scanDuration: Duration(seconds: json['scanDuration']),
        recommendations: (json['recommendations'] as List)
            .map((r) => ActionableRecommendation.fromJson(r))
            .toList(),
      );
}
