class Threat {
  final String name;
  final String description;
  final String severity;
  final String location;
  final String recommendation;
  final DateTime detectedAt;
  final String type;
  final Map<String, dynamic> metadata;
  bool isIgnored;
  bool isFixed;

  Threat({
    required this.name,
    required this.description,
    required this.severity,
    required this.location,
    required this.recommendation,
    required this.detectedAt,
    required this.type,
    this.metadata = const {},
    this.isIgnored = false,
    this.isFixed = false,
  });

  Threat copyWith({
    String? name,
    String? description,
    String? severity,
    String? location,
    String? recommendation,
    DateTime? detectedAt,
    String? type,
    Map<String, dynamic>? metadata,
    bool? isIgnored,
    bool? isFixed,
  }) {
    return Threat(
      name: name ?? this.name,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      recommendation: recommendation ?? this.recommendation,
      detectedAt: detectedAt ?? this.detectedAt,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      isIgnored: isIgnored ?? this.isIgnored,
      isFixed: isFixed ?? this.isFixed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'severity': severity,
      'location': location,
      'recommendation': recommendation,
      'detectedAt': detectedAt.toIso8601String(),
      'type': type,
      'metadata': metadata,
      'isIgnored': isIgnored,
      'isFixed': isFixed,
    };
  }

  factory Threat.fromJson(Map<String, dynamic> json) {
    return Threat(
      name: json['name'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      location: json['location'] as String,
      recommendation: json['recommendation'] as String,
      detectedAt: DateTime.parse(json['detectedAt']),
      type: json['type'] as String,
      metadata: json['metadata'] ?? {},
      isIgnored: json['isIgnored'] ?? false,
      isFixed: json['isFixed'] ?? false,
    );
  }

  String get severityLevel {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  int get severityScore {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }
}
