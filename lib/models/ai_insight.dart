import 'package:flutter/foundation.dart';

class InsightHistory {
  final DateTime date;
  final Map<String, dynamic> data;
  final String summary;

  InsightHistory({
    required this.date,
    required this.data,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'data': data,
        'summary': summary,
      };

  factory InsightHistory.fromJson(Map<String, dynamic> json) => InsightHistory(
        date: DateTime.parse(json['date']),
        data: json['data'],
        summary: json['summary'],
      );
}

class InsightComparison {
  final dynamic previous;
  final dynamic current;
  final String trend;
  final String recommendation;

  InsightComparison({
    required this.previous,
    required this.current,
    required this.trend,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'previous': previous,
        'current': current,
        'trend': trend,
        'recommendation': recommendation,
      };

  factory InsightComparison.fromJson(Map<String, dynamic> json) =>
      InsightComparison(
        previous: json['previous'],
        current: json['current'],
        trend: json['trend'],
        recommendation: json['recommendation'],
      );
}

class AIInsight {
  final String title;
  final String description;
  final int confidence;
  final String icon;
  final List<InsightHistory> history;
  final InsightComparison comparison;
  final String category;
  final DateTime timestamp;

  AIInsight({
    required this.title,
    required this.description,
    required this.confidence,
    required this.icon,
    required this.history,
    required this.comparison,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'confidence': confidence,
        'icon': icon,
        'history': history.map((h) => h.toJson()).toList(),
        'comparison': comparison.toJson(),
        'category': category,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AIInsight.fromJson(Map<String, dynamic> json) => AIInsight(
        title: json['title'],
        description: json['description'],
        confidence: json['confidence'],
        icon: json['icon'],
        history: (json['history'] as List)
            .map((h) => InsightHistory.fromJson(h))
            .toList(),
        comparison: InsightComparison.fromJson(json['comparison']),
        category: json['category'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
