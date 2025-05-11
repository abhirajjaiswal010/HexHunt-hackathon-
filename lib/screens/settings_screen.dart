import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../themes/app_theme.dart';
import '../services/desktop_service.dart';
import 'package:provider/provider.dart';
import '../providers/scan_data_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  final bool initialDarkMode;

  const SettingsScreen({
    Key? key,
    this.onThemeChanged,
    this.initialDarkMode = true,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _telemetryEnabled = true;
  bool _autoUpdateEnabled = true;
  bool _aiAssistantEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedScanLevel = 'Standard';
  String _exportFormat = 'PDF';
  String _selectedStartScreen = 'Dashboard';
  double _maxConcurrentScans = 2;
  bool _startAtLogin = false;
  bool _minimizeToTray = true;
  bool _showNotifications = true;
  bool _isLoading = true;
  bool _detailedLogs = false;
  String _logLevel = 'Info';
  String _logPath = '';

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Japanese',
    'Chinese',
  ];

  final List<String> _scanLevels = ['Basic', 'Standard', 'Advanced', 'Custom'];
  final List<String> _exportFormats = ['PDF', 'HTML', 'CSV', 'JSON'];
  final List<String> _startScreens = [
    'Dashboard',
    'Scan',
    'Reports',
    'History',
  ];

  final List<String> _logLevels = [
    'Debug',
    'Info',
    'Warning',
    'Error',
    'Critical'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _telemetryEnabled = prefs.getBool('telemetryEnabled') ?? true;
        _autoUpdateEnabled = prefs.getBool('autoUpdateEnabled') ?? true;
        _aiAssistantEnabled = prefs.getBool('aiAssistantEnabled') ?? true;
        _selectedLanguage = prefs.getString('language') ?? 'English';
        _selectedScanLevel = prefs.getString('scanLevel') ?? 'Standard';
        _exportFormat = prefs.getString('exportFormat') ?? 'PDF';
        _selectedStartScreen = prefs.getString('startScreen') ?? 'Dashboard';
      _maxConcurrentScans = prefs.getDouble('maxConcurrentScans') ?? 2.0;
        _startAtLogin = prefs.getBool('startAtLogin') ?? false;
        _minimizeToTray = prefs.getBool('minimizeToTray') ?? true;
        _showNotifications = prefs.getBool('showNotifications') ?? true;
        _detailedLogs = prefs.getBool('detailedLogs') ?? false;
      _logLevel = prefs.getString('logLevel') ?? 'Info';
      _logPath = prefs.getString('logPath') ?? '';
        _isLoading = false;
      });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('telemetryEnabled', _telemetryEnabled);
    await prefs.setBool('autoUpdateEnabled', _autoUpdateEnabled);
    await prefs.setBool('aiAssistantEnabled', _aiAssistantEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('scanLevel', _selectedScanLevel);
    await prefs.setString('exportFormat', _exportFormat);
    await prefs.setString('startScreen', _selectedStartScreen);
    await prefs.setDouble('maxConcurrentScans', _maxConcurrentScans);
    await prefs.setBool('startAtLogin', _startAtLogin);
    await prefs.setBool('minimizeToTray', _minimizeToTray);
    await prefs.setBool('showNotifications', _showNotifications);
    await prefs.setBool('detailedLogs', _detailedLogs);
    await prefs.setString('logLevel', _logLevel);
    await prefs.setString('logPath', _logPath);
  }

  Future<void> _selectLogPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/logs';
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      setState(() {
        _logPath = path;
      });
      await _saveSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting log path: $e')),
    );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Appearance', theme),
            _buildSettingTile(
              title: 'Dark Mode',
              subtitle: 'Use dark theme throughout the app',
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) => themeProvider.toggleTheme(),
              theme: theme,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Notifications', theme),
            _buildSettingTile(
              title: 'Enable Notifications',
              subtitle: 'Receive alerts for scan results and threats',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSettings();
              },
              theme: theme,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Logging', theme),
            _buildSettingTile(
              title: 'Detailed Logs',
              subtitle: 'Enable detailed logging for debugging and analysis',
              value: _detailedLogs,
              onChanged: (value) {
                setState(() => _detailedLogs = value);
                _saveSettings();
              },
              theme: theme,
            ),
            if (_detailedLogs) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Level',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _logLevel,
                      items: _logLevels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _logLevel = value);
                          _saveSettings();
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Log Directory',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _logPath.isEmpty ? 'Not set' : _logPath,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Browse'),
                          onPressed: _selectLogPath,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildSectionTitle('Application', theme),
            _buildSettingTile(
              title: 'Start at Login',
              subtitle: 'Launch HexHunt when your system starts',
              value: _startAtLogin,
              onChanged: (value) {
                setState(() => _startAtLogin = value);
                _saveSettings();
              },
              theme: theme,
            ),
            _buildSettingTile(
              title: 'Minimize to Tray',
              subtitle: 'Keep HexHunt running in the system tray when closed',
              value: _minimizeToTray,
              onChanged: (value) {
                setState(() => _minimizeToTray = value);
                _saveSettings();
              },
              theme: theme,
            ),
            _buildSettingTile(
              title: 'Auto Update',
              subtitle: 'Automatically check for and install updates',
              value: _autoUpdateEnabled,
              onChanged: (value) {
                setState(() => _autoUpdateEnabled = value);
                _saveSettings();
              },
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }
}
