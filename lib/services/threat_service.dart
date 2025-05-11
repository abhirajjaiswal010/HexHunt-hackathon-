import 'dart:convert';
import 'package:shared_preferences.dart';
import '../models/threat.dart';

class ThreatService {
  static const String _threatsKey = 'threats';
  final SharedPreferences _prefs;

  ThreatService(this._prefs);

  Future<List<Threat>> getThreats() async {
    final String? threatsJson = _prefs.getString(_threatsKey);
    if (threatsJson == null) return [];

    final List<dynamic> threatsList = json.decode(threatsJson);
    return threatsList.map((json) => Threat.fromJson(json)).toList();
  }

  Future<void> addThreat(Threat threat) async {
    final List<Threat> threats = await getThreats();
    threats.add(threat);
    await _saveThreats(threats);
  }

  Future<void> updateThreat(Threat threat) async {
    final List<Threat> threats = await getThreats();
    final index = threats.indexWhere((t) => t.name == threat.name);
    if (index != -1) {
      threats[index] = threat;
      await _saveThreats(threats);
    }
  }

  Future<void> deleteThreat(String threatName) async {
    final List<Threat> threats = await getThreats();
    threats.removeWhere((t) => t.name == threatName);
    await _saveThreats(threats);
  }

  Future<void> ignoreThreat(String threatName) async {
    final List<Threat> threats = await getThreats();
    final index = threats.indexWhere((t) => t.name == threatName);
    if (index != -1) {
      threats[index] = threats[index].copyWith(isIgnored: true);
      await _saveThreats(threats);
    }
  }

  Future<void> markThreatAsFixed(String threatName) async {
    final List<Threat> threats = await getThreats();
    final index = threats.indexWhere((t) => t.name == threatName);
    if (index != -1) {
      threats[index] = threats[index].copyWith(isFixed: true);
      await _saveThreats(threats);
    }
  }

  Future<void> _saveThreats(List<Threat> threats) async {
    final String threatsJson = json.encode(threats.map((t) => t.toJson()).toList());
    await _prefs.setString(_threatsKey, threatsJson);
  }
} 