import 'package:uuid/uuid.dart';
import 'threat.dart';

class ScanRecord {
  final String id;
  final DateTime timestamp;
  final String target;
  final String scanType;
  final Map<String, dynamic> scanOptions;
  final List<Threat> threats;
  final Map<String, int> vulnerabilityDistribution;
  final int riskScore;
  final String summary;
  final Map<String, dynamic> scanMetadata;
  final List<Map<String, dynamic>> openPorts;
  final int scanDuration;
  final Map<String, dynamic> trainingData;

  ScanRecord({
    String? id,
    required this.timestamp,
    required this.target,
    required this.scanType,
    required this.scanOptions,
    required this.threats,
    required this.vulnerabilityDistribution,
    required this.riskScore,
    required this.summary,
    required this.scanMetadata,
    required this.openPorts,
    required this.scanDuration,
    this.trainingData = const {},
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'target': target,
      'scanType': scanType,
      'scanOptions': scanOptions,
      'threats': threats.map((t) => t.toJson()).toList(),
      'vulnerabilityDistribution': vulnerabilityDistribution,
      'riskScore': riskScore,
      'summary': summary,
      'scanMetadata': scanMetadata,
      'openPorts': openPorts,
      'scanDuration': scanDuration,
      'trainingData': trainingData,
    };
  }

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      target: json['target'] as String,
      scanType: json['scanType'] as String,
      scanOptions: json['scanOptions'] as Map<String, dynamic>,
      threats: (json['threats'] as List)
          .map((t) => Threat.fromJson(t as Map<String, dynamic>))
          .toList(),
      vulnerabilityDistribution:
          Map<String, int>.from(json['vulnerabilityDistribution'] as Map),
      riskScore: json['riskScore'] as int,
      summary: json['summary'] as String,
      scanMetadata: json['scanMetadata'] as Map<String, dynamic>,
      openPorts: List<Map<String, dynamic>>.from(json['openPorts'] as List),
      scanDuration: json['scanDuration'] as int,
      trainingData: json['trainingData'] as Map<String, dynamic>? ?? {},
    );
  }
}
