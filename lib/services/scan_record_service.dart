import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scan_record.dart';

class ScanRecordService {
  static const String _recordsDirName = 'scan_records';
  static const String _trainingDirName = 'training_data';

  Future<void> saveScanRecord(ScanRecord record) async {
    final recordsDir = await _getRecordsDirectory();
    final file = File('${recordsDir.path}/${record.id}.json');
    await file.writeAsString(jsonEncode(record.toJson()));
  }

  Future<List<ScanRecord>> getAllScanRecords() async {
    final recordsDir = await _getRecordsDirectory();
    final files = await recordsDir.list().toList();
    final records = <ScanRecord>[];

    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        records.add(ScanRecord.fromJson(json));
      }
    }

    return records;
  }

  Future<void> exportTrainingData() async {
    final records = await getAllScanRecords();
    final trainingDir = await _getTrainingDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${trainingDir.path}/training_data_$timestamp.json');

    final trainingData = {
      'timestamp': timestamp,
      'total_records': records.length,
      'records': records.map((r) => r.toJson()).toList(),
      'statistics': _generateStatistics(records),
    };

    await file.writeAsString(jsonEncode(trainingData));
  }

  Map<String, dynamic> _generateStatistics(List<ScanRecord> records) {
    final totalThreats =
        records.fold<int>(0, (sum, record) => sum + record.threats.length);
    final avgRiskScore = records.isEmpty
        ? 0
        : records.fold<int>(0, (sum, record) => sum + record.riskScore) /
            records.length;

    final threatTypes = <String, int>{};
    final severityDistribution = <String, int>{};

    for (var record in records) {
      for (var threat in record.threats) {
        threatTypes[threat.type] = (threatTypes[threat.type] ?? 0) + 1;
        severityDistribution[threat.severity] =
            (severityDistribution[threat.severity] ?? 0) + 1;
      }
    }

    return {
      'total_scans': records.length,
      'total_threats': totalThreats,
      'average_risk_score': avgRiskScore,
      'threat_types': threatTypes,
      'severity_distribution': severityDistribution,
    };
  }

  Future<Directory> _getRecordsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordsDir = Directory('${appDir.path}/$_recordsDirName');
    if (!await recordsDir.exists()) {
      await recordsDir.create(recursive: true);
    }
    return recordsDir;
  }

  Future<Directory> _getTrainingDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final trainingDir = Directory('${appDir.path}/$_trainingDirName');
    if (!await trainingDir.exists()) {
      await trainingDir.create(recursive: true);
    }
    return trainingDir;
  }
}
