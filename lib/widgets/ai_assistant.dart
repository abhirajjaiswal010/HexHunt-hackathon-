import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AiAssistant extends StatefulWidget {
  final bool enabled;

  const AiAssistant({
    Key? key,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _expanded = false;
  final Map<String, String> _baseTips = {
    'Dashboard':
        'This is your central command center where you can monitor system health and recent scans.',
    'Scan':
        'Run deep scans on your system to identify potential threats and vulnerabilities.',
    'Reports':
        'View detailed reports from previous scans and export them in various formats.',
    'Settings':
        'Configure application preferences, scan behavior, and notification settings.',
  };

  List<Map<String, dynamic>> _learnedInsights = [];
  Timer? _analysisTimer;
  int _insightIndex = 0;
  bool _isLearning = false;
  String _currentInsight = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Load learned insights and start the learning process
    _loadLearnedInsights();
    _startAutomatedLearning();
  }

  @override
  void dispose() {
    _controller.dispose();
    _analysisTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLearnedInsights() async {
    final prefs = await SharedPreferences.getInstance();
    final insightsJson = prefs.getString('learned_insights') ?? '[]';

    try {
      final List<dynamic> decoded = jsonDecode(insightsJson);
      setState(() {
        _learnedInsights =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        if (_learnedInsights.isEmpty) {
          // Add some initial insights if none exist
          _learnedInsights = [
            {
              'id': 'initial_1',
              'text':
                  'I\'ve noticed that most threats are detected during full system scans.',
              'confidence': 0.8,
              'category': 'scan_pattern'
            },
            {
              'id': 'initial_2',
              'text':
                  'Regular scanning helps maintain optimal system security.',
              'confidence': 0.9,
              'category': 'best_practice'
            }
          ];
          _saveLearnedInsights();
        }
      });
    } catch (e) {
      print('Error loading insights: $e');
      _learnedInsights = [];
    }
  }

  Future<void> _saveLearnedInsights() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learned_insights', jsonEncode(_learnedInsights));
  }

  void _startAutomatedLearning() {
    // Simulate the AI learning from scan data
    _analysisTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_learnedInsights.isEmpty) return;

      setState(() {
        _isLearning = !_isLearning;
        if (_isLearning) {
          _currentInsight = 'Analyzing scan patterns...';
        } else {
          _insightIndex = (_insightIndex + 1) % _learnedInsights.length;
          _currentInsight = _learnedInsights[_insightIndex]['text'];

          // Occasionally generate new insights
          if (math.Random().nextDouble() > 0.7) {
            _generateNewInsight();
          }
        }
      });
    });
  }

  void _generateNewInsight() {
    final scanTypes = ['quick', 'full', 'custom', 'targeted'];
    final threatTypes = [
      'malware',
      'vulnerability',
      'network',
      'phishing',
      'data breach'
    ];
    final actions = ['patched', 'detected', 'prevented', 'analyzed'];

    final random = math.Random();
    final scanType = scanTypes[random.nextInt(scanTypes.length)];
    final threatType = threatTypes[random.nextInt(threatTypes.length)];
    final action = actions[random.nextInt(actions.length)];
    final number = random.nextInt(10) + 1;

    final newInsights = [
      'Based on recent scans, ${threatType} threats are ${number}x more common during ${scanType} scans.',
      'I\'ve learned that ${action} ${threatType} issues improve system security by approximately ${random.nextInt(40) + 60}%.',
      'Your scanning pattern shows that ${scanType} scans are most effective at ${action} ${threatType} threats.',
      'Analysis of past scan data suggests running ${scanType} scans more frequently to better detect ${threatType} issues.',
      'I\'ve noticed that ${threatType} threats tend to appear more after system updates.',
    ];

    final newInsightText = newInsights[random.nextInt(newInsights.length)];
    final newInsight = {
      'id': 'insight_${DateTime.now().millisecondsSinceEpoch}',
      'text': newInsightText,
      'confidence': 0.7 + (random.nextDouble() * 0.3),
      'category': '${threatType}_insight'
    };

    setState(() {
      _learnedInsights.add(newInsight);
      _currentInsight = newInsightText;
    });

    _saveLearnedInsights();
  }

  String _getCurrentContextTip() {
    // This would normally detect the current screen and return relevant help
    // For now we'll use learned insights and base tips
    if (_currentInsight.isNotEmpty && !_isLearning) {
      return _currentInsight;
    }

    if (_isLearning) {
      return 'Analyzing scan patterns...';
    }

    // Fall back to base tips if no insights are available
    final currentContext = ModalRoute.of(context)?.settings.name ?? 'Dashboard';
    return _baseTips[currentContext] ??
        'I can help you navigate the various features of HexHunt.';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_expanded)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: 200,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_isLearning)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 12,
                          height: 12,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accentColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCurrentContextTip(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _isLearning
                              ? 'Learning from scan data...'
                              : 'Adaptive insights powered by AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _generateNewInsight();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Generated new security insight')),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              AppTheme.accentColor.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Ask a question'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          MouseRegion(
            onEnter: (_) => _controller.forward(),
            onExit: (_) => _controller.reverse(),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isLearning
                        ? AppTheme.primaryColor
                        : AppTheme.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isLearning
                                ? AppTheme.primaryColor
                                : AppTheme.accentColor)
                            .withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLearning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
