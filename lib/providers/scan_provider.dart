import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../models/threat.dart';
import '../services/scan_service.dart';

class ScanProvider with ChangeNotifier {
  final ScanService _scanService = ScanService();
  List<ScanResult> _scanResults = [];
  Map<int, List<Threat>> _threatsByScan = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ScanResult> get scanResults => _scanResults;
  Map<int, List<Threat>> get threatsByScan => _threatsByScan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await loadScanResults();
  }

  // Load scan results
  Future<void> loadScanResults() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _scanResults = await _scanService.getScanResults();

      // Load threats for each scan
      for (var result in _scanResults) {
        if (result.id != null) {
          _threatsByScan[result.id!] =
              await _scanService.getThreatsForScan(result.id!);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start a new scan
  Future<ScanResult> startScan({
    required String targetPath,
    required String scanType,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _scanService.startScan(
        targetPath: targetPath,
        scanType: scanType,
      );

      // Add to results list
      _scanResults.insert(0, result);
      _threatsByScan[result.id!] = [];

      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update scan result
  Future<void> updateScanResult(ScanResult result) async {
    try {
      final index = _scanResults.indexWhere((r) => r.id == result.id);
      if (index != -1) {
        _scanResults[index] = result;

        // Reload threats if scan is completed
        if (result.status == 'completed' && result.id != null) {
          _threatsByScan[result.id!] =
              await _scanService.getThreatsForScan(result.id!);
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get threats for a scan
  List<Threat> getThreatsForScan(int scanId) {
    return _threatsByScan[scanId] ?? [];
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
