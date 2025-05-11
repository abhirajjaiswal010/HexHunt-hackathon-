import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/threat.dart';
import '../providers/scan_data_provider.dart';

class ScanResultsList extends StatelessWidget {
  const ScanResultsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanDataProvider>(
      builder: (context, provider, _) {
        if (provider.isScanning) {
          return const Center(child: CircularProgressIndicator());
        }

        final threats = provider.threats;

        if (threats.isEmpty) {
          return const Center(
            child: Text(
              'No threats detected yet. Start a new scan!',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: threats.length,
          itemBuilder: (context, index) {
            final threat = threats[index];
            return _ThreatCard(threat: threat);
          },
        );
      },
    );
  }
}

class _ThreatCard extends StatelessWidget {
  final Threat threat;

  const _ThreatCard({required this.threat});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFF2A2D3E),
      child: ExpansionTile(
        title: Row(
          children: [
            _getSeverityIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                threat.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Location: ${threat.location}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', threat.type),
                const SizedBox(height: 8),
                _buildDetailRow('Description', threat.description),
                const SizedBox(height: 8),
                _buildDetailRow('Recommendation', threat.recommendation),
                const SizedBox(height: 8),
                _buildDetailRow('Detected', _formatDate(threat.detectedAt)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!threat.isIgnored && !threat.isFixed) ...[
                      TextButton.icon(
                        onPressed: () {
                          Provider.of<ScanDataProvider>(context, listen: false)
                              .ignoreThreat(threat);
                        },
                        icon:
                            const Icon(Icons.visibility_off_outlined, size: 20),
                        label: const Text('Ignore'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<ScanDataProvider>(context, listen: false)
                              .markThreatAsFixed(threat);
                        },
                        icon: const Icon(Icons.security, size: 20),
                        label: const Text('Fix Now'),
                      ),
                    ] else if (threat.isFixed)
                      const Chip(
                        label: Text('Fixed'),
                        backgroundColor: Colors.green,
                      )
                    else if (threat.isIgnored)
                      const Chip(
                        label: Text('Ignored'),
                        backgroundColor: Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _getSeverityIcon() {
    IconData icon;
    Color color;

    switch (threat.severity.toLowerCase()) {
      case 'critical':
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case 'high':
        icon = Icons.warning_outlined;
        color = Colors.orange;
        break;
      case 'medium':
        icon = Icons.info_outline;
        color = Colors.yellow;
        break;
      default:
        icon = Icons.check_circle_outline;
        color = Colors.green;
    }

    return Icon(icon, color: color, size: 20);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
