import 'dart:convert';

class ScanResult {
  final int? id;
  final String targetPath;
  final String scanType;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final Map<String, dynamic>? findings;
  final String? riskLevel;

  ScanResult({
    this.id,
    required this.targetPath,
    required this.scanType,
    required this.startTime,
    this.endTime,
    required this.status,
    this.findings,
    this.riskLevel,
  });

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] as int?,
      targetPath: map['target_path'] as String,
      scanType: map['scan_type'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      status: map['status'] as String,
      findings: map['findings'] != null
          ? jsonDecode(map['findings'] as String)
          : null,
      riskLevel: map['risk_level'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_path': targetPath,
      'scan_type': scanType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'findings': findings != null ? jsonEncode(findings) : null,
      'risk_level': riskLevel,
    };
  }

  ScanResult copyWith({
    int? id,
    String? targetPath,
    String? scanType,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    Map<String, dynamic>? findings,
    String? riskLevel,
  }) {
    return ScanResult(
      id: id ?? this.id,
      targetPath: targetPath ?? this.targetPath,
      scanType: scanType ?? this.scanType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      findings: findings ?? this.findings,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }
}
