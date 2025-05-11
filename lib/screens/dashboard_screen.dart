import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/dashboard_card.dart';
import '../themes/app_theme.dart';
import '../widgets/quick_action_item.dart';
import '../widgets/ai_assistant.dart';
import '../services/ml_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/scan_data_provider.dart';
import '../widgets/scan_results_list.dart';
import '../widgets/current_scan_card.dart';
import '../widgets/threat_overview_chart.dart';
import '../widgets/vulnerability_distribution.dart';
import '../widgets/stats_card.dart';
import '../widgets/ai_insights_panel.dart';
import '../widgets/detailed_threat_report.dart';
import '../screens/settings_screen.dart';
import '../screens/history_screen.dart';
import '../widgets/ai_insights_card.dart';
import '../services/ai_insight_service.dart';
import '../models/ai_insight.dart';
import '../models/detailed_scan_report.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedTarget = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ScanDataProvider>(
      builder: (context, scanData, _) {
        final aiInsights = AIInsightService()
            .generateInsightsFromReport(scanData.toDetailedScanReport());
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            title: Row(
              children: [
                Image.asset(
                  'assets/app_icon.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 15),
                Text(
                  'HexHunt',
                  style: theme.appBarTheme.titleTextStyle,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.history_outlined, color: theme.iconTheme.color),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HistoryScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: theme.iconTheme.color),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: theme.iconTheme.color),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Icon(Icons.person_outline, color: theme.colorScheme.onPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                'Admin',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Content Area (75% width)
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Top Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            Widget threatOverviewSection = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Threat Overview for:',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: DropdownButton<String>(
                                        dropdownColor: theme.cardColor,
                                        value: selectedTarget,
                                        isExpanded: true,
                                        items: [
                                          DropdownMenuItem(
                                            value: 'All',
                                            child: Text('All',
                                                style: theme.textTheme.bodyLarge),
                                          ),
                                          ...scanData.allTargets
                                              .map((target) => DropdownMenuItem(
                                                    value: target,
                                                    child: Text(
                                                      target,
                                                      style: theme.textTheme.bodyLarge,
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  )),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            selectedTarget = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 300,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ThreatOverviewChart(
                                      selectedTarget: selectedTarget),
                                ),
                              ],
                            );
                            return constraints.maxWidth < 800
                                ? Column(
                                    children: [
                                      const CurrentScanCard(),
                                      const SizedBox(height: 16),
                                      threatOverviewSection,
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 400,
                                        child: CurrentScanCard(),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: threatOverviewSection,
                                      ),
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Stats Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return constraints.maxWidth < 800
                                ? Column(
                                    children: [
                                      StatsCard(
                                        title: 'Total Scans',
                                        value: scanData.totalScans.toString(),
                                        icon: Icons.analytics_outlined,
                                        iconColor: theme.colorScheme.primary,
                                        iconSize: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      StatsCard(
                                        title: 'Active Threats',
                                        value: scanData.activeThreats.toString(),
                                        icon: Icons.warning_outlined,
                                        iconColor: theme.colorScheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      StatsCard(
                                        title: 'Risk Score',
                                        value: '${scanData.riskScore}/100',
                                        icon: Icons.shield_outlined,
                                        iconColor: theme.colorScheme.secondary,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: StatsCard(
                                          title: 'Total Scans',
                                          value: scanData.totalScans.toString(),
                                          icon: Icons.analytics_outlined,
                                          iconColor: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: StatsCard(
                                          title: 'Active Threats',
                                          value: scanData.activeThreats.toString(),
                                          icon: Icons.warning_outlined,
                                          iconColor: theme.colorScheme.error,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: StatsCard(
                                          title: 'Risk Score',
                                          value: '${scanData.riskScore}/100',
                                          icon: Icons.shield_outlined,
                                          iconColor: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Vulnerability Distribution
                        SizedBox(
                          height: 400,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                          child: VulnerabilityDistribution(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Detailed Threat Report
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const DetailedThreatReport(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: AIInsightsCard(insights: aiInsights),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension ScanDataProviderExtension on ScanDataProvider {
  DetailedScanReport toDetailedScanReport() {
    // Map your provider's data to a DetailedScanReport for AI insights
    return DetailedScanReport(
      startTime: DateTime.now().subtract(const Duration(minutes: 5)),
      endTime: DateTime.now(),
      target: currentTarget ?? 'Unknown',
      scanType: currentScanType ?? 'web',
      scannerVersion: '1.0.0',
      signatureVersion: '2024.06',
      hostInfo: HostInformation(ipAddress: '127.0.0.1'),
      portScanResults: [],
      vulnerabilityAnalysis: VulnerabilityAnalysis(
        vulnerabilityScore: riskScore / 100.0,
        cveIds: [],
        cvssScores: {},
        cveDescriptions: {},
        hasExploit: false,
        threatLevel: 'Medium',
        confidenceScore: 0.9,
      ),
      discoveredSubdomains: [],
      threatIntelligence: ThreatIntelligence(
        ipReputation: 'Clean',
        isBlacklisted: false,
        knownMaliciousActivities: [],
        reputationScores: {},
      ),
      anomalyDetection: AnomalyDetection(
        flaggedBehaviors: [],
        abnormalityScores: {},
        aiAnalysis: '',
      ),
      totalIpsScanned: 1,
      totalOpenPorts: 0,
      criticalVulnerabilities:
          threats.where((t) => t.severity == 'Critical').length,
      hostsWithExploits: 0,
      scanDuration: const Duration(minutes: 5),
      recommendations: [],
    );
  }
}
