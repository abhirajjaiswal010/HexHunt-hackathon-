import 'dart:convert';

class MLResult {
  final int? id;
  final int scanResultId;
  final String modelName;
  final double confidence;
  final String prediction;
  final Map<String, dynamic>? features;

  MLResult({
    this.id,
    required this.scanResultId,
    required this.modelName,
    required this.confidence,
    required this.prediction,
    this.features,
  });

  factory MLResult.fromMap(Map<String, dynamic> map) {
    return MLResult(
      id: map['id'] as int?,
      scanResultId: map['scan_result_id'] as int,
      modelName: map['model_name'] as String,
      confidence: map['confidence'] as double,
      prediction: map['prediction'] as String,
      features: map['features'] != null
          ? jsonDecode(map['features'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scan_result_id': scanResultId,
      'model_name': modelName,
      'confidence': confidence,
      'prediction': prediction,
      'features': features != null ? jsonEncode(features) : null,
    };
  }

  MLResult copyWith({
    int? id,
    int? scanResultId,
    String? modelName,
    double? confidence,
    String? prediction,
    Map<String, dynamic>? features,
  }) {
    return MLResult(
      id: id ?? this.id,
      scanResultId: scanResultId ?? this.scanResultId,
      modelName: modelName ?? this.modelName,
      confidence: confidence ?? this.confidence,
      prediction: prediction ?? this.prediction,
      features: features ?? this.features,
    );
  }
}
