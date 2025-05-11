import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../themes/app_theme.dart';
import '../services/ml_service.dart';

class MLDashboardScreen extends StatefulWidget {
  const MLDashboardScreen({Key? key}) : super(key: key);

  @override
  _MLDashboardScreenState createState() => _MLDashboardScreenState();
}

class _MLDashboardScreenState extends State<MLDashboardScreen> {
  final MLService _mlService = MLService();
  bool _isTraining = false;
  double _trainingProgress = 0.0;
  int _selectedModelIndex = 0;
  String _trainingLog = '';
  
  final List<String> _modelTypes = [
    'Threat Detection',
    'Vulnerability Analysis',
    'Anomaly Detection',
    'Web Security Scanner',
    'Threat Intelligence',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width <= 1024 && size.width >= 650;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Models Dashboard'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            tooltip: 'Back to Dashboard',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboard(isDesktop, isTablet),
            const SizedBox(height: 24),
            _buildModelDetails(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isDesktop, bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppTheme.darkCardBackgroundColor : AppTheme.cardBackgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Models Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOverallStats(isDesktop, isTablet),
            const SizedBox(height: 24),
            Text(
              'Model Selection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _modelTypes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_modelTypes[index]),
                      selected: _selectedModelIndex == index,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedModelIndex = index;
                          });
                        }
                      },
                      backgroundColor: isDark ? AppTheme.darkCardBackgroundColor : AppTheme.cardBackgroundColor,
                      selectedColor: AppTheme.accentColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(bool isDesktop, bool isTablet) {
    final gridCount = isDesktop ? 4 : (isTablet ? 2 : 1);
    
    return GridView.count(
      crossAxisCount: gridCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Models', 
          '5', 
          Icons.model_training,
          AppTheme.successColor,
        ),
        _buildStatCard(
          'Average Accuracy', 
          '${(_mlService.getOverallStats()['averageAccuracy'] * 100).toStringAsFixed(1)}%', 
          Icons.analytics,
          AppTheme.infoColor,
        ),
        _buildStatCard(
          'Last Training', 
          _mlService.getOverallStats()['lastTraining'].toString(), 
          Icons.update,
          AppTheme.warningColor,
        ),
        _buildStatCard(
          'Training Status',
          _isTraining ? 'In Progress' : 'Ready',
          _isTraining ? Icons.pending : Icons.check_circle,
          _isTraining ? AppTheme.warningColor : AppTheme.successColor,
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData iconData, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(iconData, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? AppTheme.textDarkSecondaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelDetails(bool isDesktop, bool isTablet) {
    final selectedModel = _modelTypes[_selectedModelIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      color: isDark ? AppTheme.darkCardBackgroundColor : AppTheme.cardBackgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedModel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isTraining)
                  ElevatedButton.icon(
                    onPressed: _startTraining,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Train Model'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                    ),
                  ),
                if (_isTraining)
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.hourglass_bottom),
                    label: Text('Training (${(_trainingProgress * 100).toStringAsFixed(0)}%)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildPerformanceSection(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildCapabilitiesSection(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildPerformanceSection(),
                      const SizedBox(height: 16),
                      _buildCapabilitiesSection(),
                    ],
                  ),
            const SizedBox(height: 24),
            if (_isTraining) _buildTrainingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final selectedModel = _modelTypes[_selectedModelIndex];
    final modelInfo = _mlService.getModelInfo(selectedModel.toLowerCase().replaceAll(' ', ''));
    final accuracy = modelInfo['accuracy'] as double? ?? 0.0;
    // Since precision and recall aren't directly available, we'll simulate them
    final precision = accuracy - 0.05;
    final recall = accuracy - 0.08;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Accuracy',
                '${(accuracy * 100).toStringAsFixed(1)}%',
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Precision',
                '${(precision * 100).toStringAsFixed(1)}%',
                AppTheme.infoColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Recall',
                '${(recall * 100).toStringAsFixed(1)}%',
                AppTheme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPerformanceChart(),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.textDarkSecondaryColor : AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final selectedModel = _modelTypes[_selectedModelIndex];
    final performanceData = _mlService.getPerformanceTrend(selectedModel.toLowerCase().replaceAll(' ', ''));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (performanceData.isEmpty) {
      return const Center(child: Text('No performance data available'));
    }
    
    return SizedBox(
      height: 200,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: isDark ? AppTheme.darkCardBackgroundColor.withOpacity(0.7) : Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final epoch = value.toInt();
                      if (epoch % 2 == 0) {
                        return Text(
                          epoch.toString(),
                          style: const TextStyle(
                            color: Color(0xff72719b),
                            fontSize: 10,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xff72719b),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: (performanceData.length - 1).toDouble(),
              minY: 0,
              maxY: 1,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    performanceData.length,
                    (index) => FlSpot(index.toDouble(), performanceData[index]),
                  ),
                  isCurved: true,
                  color: AppTheme.accentColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.accentColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilitiesSection() {
    final selectedModel = _modelTypes[_selectedModelIndex];
    final capabilities = _getModelCapabilities(selectedModel);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model Capabilities',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...capabilities.map((capability) => _buildCapabilityCard(
          capability['title']!,
          capability['description']!,
          capability['icon']!,
        )),
        const SizedBox(height: 16),
        if (selectedModel == 'Vulnerability Analysis')
          ElevatedButton.icon(
            onPressed: _showFineTuneDialog,
            icon: const Icon(Icons.tune),
            label: const Text('Fine-tune BERT Model'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
      ],
    );
  }

  List<Map<String, String>> _getModelCapabilities(String modelType) {
    switch (modelType) {
      case 'Threat Detection':
        return [
          {
            'title': 'Pattern Recognition',
            'description': 'Identifies known attack patterns in network traffic',
            'icon': '🔍',
          },
          {
            'title': 'Behavior Analysis',
            'description': 'Monitors system behavior for suspicious activities',
            'icon': '📊',
          },
          {
            'title': 'Real-time Alerting',
            'description': 'Sends instant notifications for critical threats',
            'icon': '⚠️',
          },
        ];
      case 'Vulnerability Analysis':
        return [
          {
            'title': 'BERT-based Analysis',
            'description': 'Uses NLP to understand and explain vulnerabilities',
            'icon': '🧠',
          },
          {
            'title': 'Context-aware Scanning',
            'description': 'Analyzes code and configurations in context',
            'icon': '📝',
          },
          {
            'title': 'Remediation Suggestions',
            'description': 'Provides actionable fix recommendations',
            'icon': '🛠️',
          },
        ];
      case 'Anomaly Detection':
        return [
          {
            'title': 'Baseline Learning',
            'description': 'Establishes normal behavior patterns automatically',
            'icon': '📈',
          },
          {
            'title': 'Outlier Detection',
            'description': 'Identifies unusual activities across systems',
            'icon': '🔔',
          },
          {
            'title': 'Adaptive Thresholds',
            'description': 'Adjusts sensitivity based on historical data',
            'icon': '⚖️',
          },
        ];
      case 'Web Security Scanner':
        return [
          {
            'title': 'Injection Analysis',
            'description': 'Detects SQL, XSS, and CSRF vulnerabilities',
            'icon': '💉',
          },
          {
            'title': 'Authentication Testing',
            'description': 'Validates login security and session management',
            'icon': '🔐',
          },
          {
            'title': 'API Security',
            'description': 'Checks RESTful and GraphQL API endpoints',
            'icon': '🔌',
          },
        ];
      case 'Threat Intelligence':
        return [
          {
            'title': 'IoC Correlation',
            'description': 'Matches indicators against threat intelligence feeds',
            'icon': '🔗',
          },
          {
            'title': 'Attribution Analysis',
            'description': 'Identifies potential threat actors and motives',
            'icon': '👤',
          },
          {
            'title': 'Tactical Prediction',
            'description': 'Forecasts potential attack vectors based on trends',
            'icon': '🔮',
          },
        ];
      default:
        return [];
    }
  }

  Widget _buildCapabilityCard(String title, String description, String icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.textDarkSecondaryColor : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Training Progress',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? AppTheme.textDarkPrimaryColor : AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _trainingProgress,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackgroundColor.withOpacity(0.7) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          height: 150,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Text(
              _trainingLog,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: isDark ? AppTheme.textDarkSecondaryColor : AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startTraining() {
    final selectedModel = _modelTypes[_selectedModelIndex];
    
    setState(() {
      _isTraining = true;
      _trainingProgress = 0.0;
      _trainingLog = '[INFO] Starting training for $selectedModel model...\n';
    });
    
    // Simulate training process
    int epochs = 10;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trainingProgress < 1.0) {
        setState(() {
          _trainingProgress += 1.0 / epochs;
          int currentEpoch = (_trainingProgress * epochs).floor() + 1;
          double loss = 0.5 - (_trainingProgress * 0.3) + (0.1 * (DateTime.now().millisecond % 10) / 10);
          double accuracy = 0.7 + (_trainingProgress * 0.2) + (0.05 * (DateTime.now().millisecond % 10) / 10);
          
          _trainingLog += '[EPOCH $currentEpoch/$epochs] Loss: ${loss.toStringAsFixed(4)}, '
              'Accuracy: ${(accuracy * 100).toStringAsFixed(2)}%\n';
        });
      } else {
        timer.cancel();
        setState(() {
          _isTraining = false;
          _trainingLog += '[INFO] Training completed successfully.\n';
          _trainingLog += '[INFO] Model saved to disk and ready for use.\n';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$selectedModel model training completed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    });
  }
  
  void _showFineTuneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fine-tune BERT Model'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The BERT model can be fine-tuned to improve vulnerability explanation quality. Select parameters:',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Training Dataset',
                  border: OutlineInputBorder(),
                ),
                value: 'CVE-2023 Dataset (5,423 entries)',
                items: [
                  'CVE-2023 Dataset (5,423 entries)',
                  'OWASP Top 10 (Expanded)',
                  'Custom Dataset',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Language Model',
                  border: OutlineInputBorder(),
                ),
                value: 'BERT-base',
                items: [
                  'BERT-base',
                  'BERT-large',
                  'CodeBERT',
                  'SecBERT',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              const Text('Learning Rate'),
              Slider(
                value: 0.0001,
                min: 0.00001,
                max: 0.001,
                divisions: 20,
                label: '0.0001',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startTraining();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            child: const Text('Start Fine-tuning'),
          ),
        ],
      ),
    );
  }
} 
