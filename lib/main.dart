import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'providers/scan_data_provider.dart';
import 'providers/theme_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'themes/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _setWindowIcon() async {
  if (Platform.isWindows) {
    try {
      // For Windows, use the ICO file
      final ByteData iconData = await rootBundle.load('assets/app_icon.ico');
      final appDir = await getApplicationDocumentsDirectory();
      final iconPath = '${appDir.path}/app_icon.ico';
      final File iconFile = File(iconPath);
      await iconFile.writeAsBytes(iconData.buffer.asUint8List());
      await windowManager.setIcon(iconPath);
    } catch (e) {
      print('Error setting Windows icon: $e');
    }
  } else if (Platform.isLinux || Platform.isMacOS) {
    try {
      // For Linux/MacOS, use the PNG file
      final ByteData iconData = await rootBundle.load('assets/app_icon.png');
      final appDir = await getApplicationDocumentsDirectory();
      final iconPath = '${appDir.path}/app_icon.png';
      final File iconFile = File(iconPath);
      await iconFile.writeAsBytes(iconData.buffer.asUint8List());
      await windowManager.setIcon(iconPath);
    } catch (e) {
      print('Error setting Linux/MacOS icon: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window settings for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setTitle('HexHunt');
    await windowManager.setMinimumSize(const Size(1024, 768));
    await windowManager.setSize(const Size(1280, 800));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanDataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'HexHunt',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
