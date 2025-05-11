import 'package:flutter/material.dart';
import '../models/ai_insight.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AIInsightsCard extends StatelessWidget {
  final List<AIInsight> insights;

  const AIInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (insights.isEmpty) {
      return Card(
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No AI insights available.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Insights',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightTile(insight, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(AIInsight insight, ThemeData theme) {
    return ExpansionTile(
      leading: _getInsightIcon(insight.icon, theme),
      title: Text(
        insight.title,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getConfidenceColor(insight.confidence, theme),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${insight.confidence}% confidence',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            insight.category,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              _buildHistorySection(insight, theme),
              const SizedBox(height: 16),
              _buildComparisonSection(insight, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(AIInsight insight, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: insight.history
                .map((h) => Card(
                      color: theme.scaffoldBackgroundColor,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MM/dd').format(h.date),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              h.summary,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonSection(AIInsight insight, ThemeData theme) {
    final comparison = insight.comparison;
    final trendColor = _getTrendColor(comparison.trend, theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparison',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous: ${comparison.previous}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    'Current: ${comparison.current}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _getTrendIcon(comparison.trend),
                        color: trendColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comparison.trend.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendation:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comparison.recommendation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Icon _getInsightIcon(String icon, ThemeData theme) {
    IconData iconData;
    switch (icon.toLowerCase()) {
      case 'network':
        iconData = Icons.network_check;
        break;
      case 'security':
        iconData = Icons.security;
        break;
      case 'shield':
        iconData = Icons.shield;
        break;
      case 'analytics':
        iconData = Icons.analytics;
        break;
      default:
        iconData = Icons.insights;
    }
    return Icon(iconData, color: theme.colorScheme.primary);
  }

  Color _getConfidenceColor(int confidence, ThemeData theme) {
    if (confidence >= 90) return theme.colorScheme.primary;
    if (confidence >= 70) return theme.colorScheme.secondary;
    return theme.colorScheme.error;
  }

  Color _getTrendColor(String trend, ThemeData theme) {
    switch (trend.toLowerCase()) {
      case 'improved':
        return theme.colorScheme.primary;
      case 'worsened':
        return theme.colorScheme.error;
      case 'increased':
        return theme.colorScheme.secondary;
      case 'decreased':
        return theme.colorScheme.primary;
      default:
        return theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'improved':
        return Icons.trending_up;
      case 'worsened':
        return Icons.trending_down;
      case 'increased':
        return Icons.arrow_upward;
      case 'decreased':
        return Icons.arrow_downward;
      default:
        return Icons.trending_flat;
    }
  }
}
