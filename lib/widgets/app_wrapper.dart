import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_assistant.dart';

class AppWrapper extends StatelessWidget {
  final Widget child;

  const AppWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,

        // AI Assistant
        FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final prefs = snapshot.data!;
              final aiEnabled = prefs.getBool('aiAssistantEnabled') ?? true;
              return AiAssistant(enabled: aiEnabled);
            }
            return const AiAssistant(enabled: true); // Default to enabled
          },
        ),
      ],
    );
  }
}
