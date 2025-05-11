import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// A custom card widget for dashboard elements following the HexHunt design system
class DashboardCard extends StatelessWidget {
  /// Primary content of the card
  final Widget child;
  
  /// The title of the card
  final String title;
  
  /// Optional icon to display in the left of the title
  final IconData icon;
  
  /// Optional icon color
  final Color? iconColor;
  
  /// Optional actions to display in the right of the title
  final List<Widget>? actions;
  
  /// Optional padding for the card
  final EdgeInsetsGeometry? padding;
  
  /// Optional background color for the card
  final Color? backgroundColor;
  
  const DashboardCard({
    Key? key,
    required this.child,
    required this.title,
    required this.icon,
    this.iconColor,
    this.actions,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: backgroundColor ?? theme.cardColor,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor ?? theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (actions != null) Row(children: actions!),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
} 
