import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_selector/file_selector.dart';
import '../models/scan_target.dart';

/// Service class for desktop-specific functionality
class DesktopService {
  /// Singleton instance
  static final DesktopService _instance = DesktopService._internal();

  /// Private constructor
  DesktopService._internal();

  /// Factory constructor to return the singleton instance
  factory DesktopService() => _instance;

  /// Whether the app should start at login
  bool _startAtLogin = false;

  /// Initialize desktop-specific functionality
  Future<void> initialize() async {
    if (!isDesktop()) {
      return;
    }

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _startAtLogin = prefs.getBool('startAtLogin') ?? false;
  }

  /// Check if the app is running on a desktop platform
  bool isDesktop() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// Toggle whether the app should start at login
  Future<bool> toggleStartAtLogin() async {
    _startAtLogin = !_startAtLogin;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('startAtLogin', _startAtLogin);

    // In a real app, you would use platform-specific logic to actually
    // add/remove the app from the startup items

    return _startAtLogin;
  }

  /// Open the file picker to select files for scanning
  Future<List<ScanTarget>?> pickFilesToScan() async {
    if (!isDesktop()) {
      return null;
    }

    try {
      final typeGroup = XTypeGroup(
        label: 'Scannable Files',
        extensions: ['exe', 'dll', 'js', 'php', 'py', 'jar', 'apk'],
      );

      final files = await openFiles(
        acceptedTypeGroups: [typeGroup],
        initialDirectory: (await getDownloadsDirectory())?.path,
      );

      if (files.isNotEmpty) {
        // Convert file paths to ScanTarget objects
        List<String> filePaths = files.map((file) => file.path).toList();
        return await ScanTarget.fromFilePaths(filePaths);
      }
    } catch (e) {
      print('Error picking files: $e');
    }

    return null;
  }

  /// Open the file picker to select a directory for scanning
  Future<List<ScanTarget>?> pickDirectoryToScan() async {
    if (!isDesktop()) {
      return null;
    }

    try {
      final directory = await getDirectoryPath(
        initialDirectory: (await getDownloadsDirectory())?.path,
      );

      if (directory != null) {
        return [
          ScanTarget(
            id: directory,
            path: directory,
            name: directory.split(Platform.pathSeparator).last,
            type: ScanTargetType.directory,
            size: await _getDirectorySize(Directory(directory)),
            lastModified: await _getDirectoryLastModified(Directory(directory)),
          )
        ];
      }
    } catch (e) {
      print('Error picking directory: $e');
    }

    return null;
  }

  /// Get the size of a directory in bytes
  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      await for (var entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    return size;
  }

  /// Get the last modified time of the most recently modified file in a directory
  Future<DateTime> _getDirectoryLastModified(Directory directory) async {
    DateTime lastModified = directory.statSync().modified;
    try {
      await for (var entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileModified = await entity.lastModified();
          if (fileModified.isAfter(lastModified)) {
            lastModified = fileModified;
          }
        }
      }
    } catch (e) {
      print('Error getting directory last modified time: $e');
    }
    return lastModified;
  }
}
