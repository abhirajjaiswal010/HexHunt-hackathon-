import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/scan_data_provider.dart';

class CurrentScanCard extends StatefulWidget {
  const CurrentScanCard({super.key});

  @override
  State<CurrentScanCard> createState() => _CurrentScanCardState();
}

class _CurrentScanCardState extends State<CurrentScanCard> {
  final _formKey = GlobalKey<FormState>();
  String _target = '';
  String _scanType = 'url';
  bool _showAdvanced = false;
  String? _selectedPath;

  final Map<String, String> _scanTypes = {
    'url': 'Web URL',
    'ip': 'IP Address',
    'system': 'System Scan',
    'network': 'Network Scan',
    'memory': 'Memory Scan',
  };

  final Map<String, bool> _scanOptions = {
    'Vulnerability Scan': true,
    'Directory Enumeration': true,
    'SSL/TLS Analysis': true,
    'Header Analysis': true,
    'Port Scan': false,
    'Subdomain Enumeration': false,
    'API Security Scan': false,
    'Authentication Test': false,
  };

  Future<void> _pickTarget() async {
    try {
      switch (_scanType) {
        case 'system':
          final XTypeGroup typeGroup = XTypeGroup(
            label: 'All Files',
            extensions: ['*'],
          );
          final files = await openFiles(acceptedTypeGroups: [typeGroup]);
          if (files.isNotEmpty) {
            setState(() {
              _target = files.map((f) => f.path).join(', ');
              _selectedPath = _target;
            });
          }
          break;
        case 'network':
          setState(() {
            _target = 'network://interfaces';
            _selectedPath = _target;
          });
          break;
        case 'memory':
          setState(() {
            _target = 'memory://processes';
            _selectedPath = _target;
          });
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting target: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ScanDataProvider>(
      builder: (context, scanData, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scan Control',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (scanData.isScanning)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              if (scanData.isScanning) ...[
                const SizedBox(height: 24),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 168,
                        width: 168,
                        child: CircularProgressIndicator(
                          value: scanData.scanProgress,
                          strokeWidth: 12,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(scanData.scanProgress * 100).toInt()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Complete',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Time Remaining',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      scanData.timeRemaining,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => scanData.stopScan(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Stop Scan',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onError,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _scanTypes.entries.map((entry) {
                          return _buildScanTypeButton(
                            title: entry.value,
                            isSelected: _scanType == entry.key,
                            onTap: () {
                              setState(() {
                                _scanType = entry.key;
                                _target = '';
                                _selectedPath = null;
                              });
                              if (['system', 'network', 'memory']
                                  .contains(entry.key)) {
                                _pickTarget();
                              }
                            },
                            theme: theme,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (_scanType == 'url' || _scanType == 'ip')
                        TextFormField(
                          controller: TextEditingController(text: _target),
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: _scanType == 'url'
                                ? 'Enter target URL (e.g., https://example.com)'
                                : 'Enter IP address',
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: theme.scaffoldBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              _scanType == 'url' ? Icons.link : Icons.lan,
                              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a target';
                            }
                            if (_scanType == 'url' &&
                                !value.startsWith('http')) {
                              return 'URL must start with http:// or https://';
                            }
                            return null;
                          },
                          onChanged: (value) => _target = value,
                          onSaved: (value) => _target = value ?? '',
                          enableInteractiveSelection: true,
                          enableSuggestions: true,
                          autocorrect: false,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(38),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _scanType == 'system'
                                    ? Icons.folder_open
                                    : _scanType == 'network'
                                        ? Icons.wifi
                                        : Icons.memory,
                                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedPath ?? 'Select target to scan',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _selectedPath != null
                                        ? theme.textTheme.bodyLarge?.color
                                        : theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              if (_scanType == 'system')
                                TextButton.icon(
                                  icon: Icon(Icons.folder_open, color: theme.colorScheme.primary),
                                  label: Text('Browse', style: TextStyle(color: theme.colorScheme.primary)),
                                  onPressed: _pickTarget,
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => setState(
                                () => _showAdvanced = !_showAdvanced),
                            child: Row(
                              children: [
                                AnimatedRotation(
                                  turns: _showAdvanced ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.expand_more,
                                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Advanced Options',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scan Options',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Divider(
                                      color: theme.dividerColor,
                                      height: 24,
                                    ),
                                    Wrap(
                                      spacing: 24,
                                      runSpacing: 16,
                                      children:
                                          _scanOptions.entries.map((entry) {
                                        if (_scanType == 'url' &&
                                            ['Port Scan']
                                                .contains(entry.key)) {
                                          return const SizedBox.shrink();
                                        }
                                        if (_scanType == 'ip' &&
                                            [
                                              'Directory Enumeration',
                                              'SSL/TLS Analysis',
                                              'Header Analysis'
                                            ].contains(entry.key)) {
                                          return const SizedBox.shrink();
                                        }
                                        if (_scanType == 'system' &&
                                            [
                                              'SSL/TLS Analysis',
                                              'Header Analysis',
                                              'API Security Scan'
                                            ].contains(entry.key)) {
                                          return const SizedBox.shrink();
                                        }
                                        if (_scanType == 'network' &&
                                            [
                                              'Directory Enumeration',
                                              'SSL/TLS Analysis',
                                              'Header Analysis',
                                              'API Security Scan'
                                            ].contains(entry.key)) {
                                          return const SizedBox.shrink();
                                        }
                                        return SizedBox(
                                          width: 220,
                                          child: CheckboxListTile(
                                            title: Text(
                                              entry.key,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                              ),
                                            ),
                                            value: entry.value,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                _scanOptions[entry.key] =
                                                    value ?? false;
                                              });
                                            },
                                            checkColor: theme.colorScheme.onPrimary,
                                            activeColor: theme.colorScheme.primary,
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            crossFadeState: _showAdvanced
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              scanData.startScan(
                                _target,
                                _scanType,
                                _scanOptions,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Start Scan',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanTypeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
