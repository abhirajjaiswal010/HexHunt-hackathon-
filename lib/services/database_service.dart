import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_report.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Directory? _storageDir;
  static Map<String, List<Map<String, dynamic>>> _cache = {};
  late final SharedPreferences _prefs;

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<Directory> get storageDir async {
    if (_storageDir != null) return _storageDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _storageDir = Directory(path.join(appDir.path, 'hexhunt_data'));
    if (!await _storageDir!.exists()) {
      await _storageDir!.create(recursive: true);
    }
    return _storageDir!;
  }

  Future<void> _ensureTableFile(String tableName) async {
    final dir = await storageDir;
    final file = File(path.join(dir.path, '$tableName.json'));
    if (!await file.exists()) {
      await file.writeAsString('[]');
    }
  }

  Future<List<Map<String, dynamic>>> _readTable(String tableName) async {
    if (_cache.containsKey(tableName)) {
      return List<Map<String, dynamic>>.from(_cache[tableName]!);
    }

    await _ensureTableFile(tableName);
    final dir = await storageDir;
    final file = File(path.join(dir.path, '$tableName.json'));
    final content = await file.readAsString();
    final data = List<Map<String, dynamic>>.from((jsonDecode(content) as List)
        .map((item) => Map<String, dynamic>.from(item)));
    _cache[tableName] = data;
    return data;
  }

  Future<void> _writeTable(
      String tableName, List<Map<String, dynamic>> data) async {
    _cache[tableName] = data;
    final dir = await storageDir;
    final file = File(path.join(dir.path, '$tableName.json'));
    await file.writeAsString(jsonEncode(data));
  }

  // Scan Results Operations
  Future<int> insertScanResult(Map<String, dynamic> scanResult) async {
    final data = await _readTable('scan_results');
    final id = data.isEmpty ? 1 : (data.last['id'] as int) + 1;
    scanResult['id'] = id;
    data.add(scanResult);
    await _writeTable('scan_results', data);
    return id;
  }

  Future<List<Map<String, dynamic>>> getScanResults() async {
    final data = await _readTable('scan_results');
    return data
      ..sort((a, b) =>
          (b['start_time'] as String).compareTo(a['start_time'] as String));
  }

  Future<Map<String, dynamic>?> getScanResult(int id) async {
    final data = await _readTable('scan_results');
    return data.firstWhere((item) => item['id'] == id, orElse: () => {});
  }

  // Threats Operations
  Future<int> insertThreat(Map<String, dynamic> threat) async {
    final data = await _readTable('threats');
    final id = data.isEmpty ? 1 : (data.last['id'] as int) + 1;
    threat['id'] = id;
    data.add(threat);
    await _writeTable('threats', data);
    return id;
  }

  Future<List<Map<String, dynamic>>> getThreatsForScan(int scanResultId) async {
    final data = await _readTable('threats');
    return data
        .where((item) => item['scan_result_id'] == scanResultId)
        .toList();
  }

  // ML Results Operations
  Future<int> insertMLResult(Map<String, dynamic> mlResult) async {
    final data = await _readTable('ml_results');
    final id = data.isEmpty ? 1 : (data.last['id'] as int) + 1;
    mlResult['id'] = id;

    // Ensure features are properly serialized
    if (mlResult['features'] != null && mlResult['features'] is Map) {
      mlResult['features'] = jsonEncode(mlResult['features']);
    }

    data.add(mlResult);
    await _writeTable('ml_results', data);
    return id;
  }

  Future<List<Map<String, dynamic>>> getMLResultsForScan(
      int scanResultId) async {
    final data = await _readTable('ml_results');
    final results =
        data.where((item) => item['scan_result_id'] == scanResultId).toList();

    // Deserialize features
    for (var result in results) {
      if (result['features'] != null && result['features'] is String) {
        try {
          result['features'] = jsonDecode(result['features'] as String);
        } catch (e) {
          print('Error deserializing ML features: $e');
        }
      }
    }

    return results;
  }

  // Settings Operations
  Future<void> setSetting(String key, String value) async {
    final data = await _readTable('settings');
    final index = data.indexWhere((item) => item['key'] == key);
    if (index >= 0) {
      data[index]['value'] = value;
    } else {
      data.add({'key': key, 'value': value});
    }
    await _writeTable('settings', data);
  }

  Future<String?> getSetting(String key) async {
    final data = await _readTable('settings');
    final setting = data.firstWhere(
      (item) => item['key'] == key,
      orElse: () => {},
    );
    return setting['value'] as String?;
  }

  // Cleanup
  Future<void> close() async {
    _cache.clear();
  }

  Future<void> insertScanReport(ScanReport report) async {
    try {
      // Get existing reports
      final reports = await getScanReports();

      // Add new report
      reports.add(report);

      // Save updated list
      final reportsJson = reports.map((r) => r.toMap()).toList();
      await _prefs.setString('scan_reports', jsonEncode(reportsJson));
    } catch (e) {
      print('Error saving scan report: $e');
      rethrow;
    }
  }

  Future<List<ScanReport>> getScanReports() async {
    try {
      final reportsJson = _prefs.getString('scan_reports');
      if (reportsJson == null) return [];

      final List<dynamic> reportsList = jsonDecode(reportsJson);
      return reportsList
          .map((json) => ScanReport.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting scan reports: $e');
      return [];
    }
  }

  Future<void> deleteScanReport(String reportId) async {
    try {
      final reports = await getScanReports();
      reports.removeWhere((r) => r.id == reportId);

      final reportsJson = reports.map((r) => r.toMap()).toList();
      await _prefs.setString('scan_reports', jsonEncode(reportsJson));
    } catch (e) {
      print('Error deleting scan report: $e');
      rethrow;
    }
  }

  Future<void> clearAllReports() async {
    try {
      await _prefs.remove('scan_reports');
    } catch (e) {
      print('Error clearing scan reports: $e');
      rethrow;
    }
  }
}
