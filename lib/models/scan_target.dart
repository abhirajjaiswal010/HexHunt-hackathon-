import 'dart:io';

/// Model class representing a scan target (file, directory, URL, etc.)
class ScanTarget {
  /// Unique identifier for the target
  final String id;
  
  /// Display name of the target
  final String name;
  
  /// Type of scan target
  final ScanTargetType type;
  
  /// Full path for file/directory targets, URL for web targets
  final String path;
  
  /// File extension (if applicable)
  final String? extension;
  
  /// File size in bytes (if applicable)
  final int? size;
  
  /// Last modified date (if applicable)
  final DateTime? lastModified;
  
  /// Associated application (desktop only)
  final String? associatedApp;
  
  /// File or directory permissions (desktop only)
  final FileStat? fileStat;
  
  /// Desktop-specific file info
  final DesktopFileInfo? desktopInfo;
  
  /// Whether this target is currently being scanned
  bool isScanning;
  
  /// Whether this target has been scanned
  bool isScanned;
  
  /// Timestamp of the last scan
  DateTime? lastScanTime;
  
  /// Risk score from the last scan (0-100)
  int? riskScore;
  
  /// Number of vulnerabilities found
  int? vulnerabilityCount;
  
  ScanTarget({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    this.extension,
    this.size,
    this.lastModified,
    this.associatedApp,
    this.fileStat,
    this.desktopInfo,
    this.isScanning = false,
    this.isScanned = false,
    this.lastScanTime,
    this.riskScore,
    this.vulnerabilityCount,
  });
  
  /// Create a ScanTarget from a file
  static Future<ScanTarget> fromFile(File file) async {
    final fileStats = await file.stat();
    final String fileName = file.path.split(Platform.pathSeparator).last;
    final String? extension = fileName.contains('.') 
      ? fileName.substring(fileName.lastIndexOf('.') + 1) 
      : null;
    
    return ScanTarget(
      id: file.path,
      name: fileName,
      type: ScanTargetType.file,
      path: file.path,
      extension: extension,
      size: fileStats.size,
      lastModified: fileStats.modified,
      fileStat: fileStats,
      desktopInfo: Platform.isWindows || Platform.isLinux || Platform.isMacOS 
        ? await DesktopFileInfo.fromFile(file)
        : null,
    );
  }
  
  /// Create multiple ScanTargets from a list of file paths
  static Future<List<ScanTarget>> fromFilePaths(List<String> filePaths) async {
    List<ScanTarget> targets = [];
    
    for (String path in filePaths) {
      final file = File(path);
      if (await file.exists()) {
        targets.add(await fromFile(file));
      }
    }
    
    return targets;
  }
  
  /// Mark this target as being scanned
  void startScan() {
    isScanning = true;
    isScanned = false;
    lastScanTime = DateTime.now();
  }
  
  /// Update with scan results
  void completeScan({required int riskScore, required int vulnerabilityCount}) {
    this.riskScore = riskScore;
    this.vulnerabilityCount = vulnerabilityCount;
    isScanning = false;
    isScanned = true;
  }
  
  /// Check if this target is a high risk
  bool get isHighRisk => riskScore != null && riskScore! >= 70;
  
  /// Get the risk level category
  RiskLevel get riskLevel {
    if (riskScore == null) return RiskLevel.unknown;
    if (riskScore! >= 80) return RiskLevel.critical;
    if (riskScore! >= 60) return RiskLevel.high;
    if (riskScore! >= 40) return RiskLevel.medium;
    return RiskLevel.low;
  }
}

/// Types of scan targets
enum ScanTargetType {
  file,
  directory,
  url,
  process,
  network,
}

/// Risk level categories
enum RiskLevel {
  unknown,
  low,
  medium,
  high,
  critical,
}

/// Desktop-specific file information
class DesktopFileInfo {
  /// File owner username
  final String? owner;
  
  /// File permissions string (e.g., 'rwxr-xr--')
  final String? permissions;
  
  /// Whether the file is hidden
  final bool isHidden;
  
  /// Whether the file is a system file
  final bool isSystem;
  
  /// Whether the file is executable
  final bool isExecutable;
  
  /// File signature information (if available)
  final String? signature;
  
  /// Associated application that opens this file
  final String? defaultApp;
  
  DesktopFileInfo({
    this.owner,
    this.permissions,
    this.isHidden = false,
    this.isSystem = false,
    this.isExecutable = false,
    this.signature,
    this.defaultApp,
  });
  
  /// Create DesktopFileInfo from a file
  static Future<DesktopFileInfo> fromFile(File file) async {
    bool isHidden = false;
    bool isSystem = false;
    bool isExecutable = false;
    String? owner;
    String? permissions;
    
    if (Platform.isWindows) {
      // Windows-specific logic
      isHidden = file.path.split(Platform.pathSeparator).last.startsWith('.');
      // Additional Windows file attribute detection would go here
    } else if (Platform.isLinux || Platform.isMacOS) {
      // Unix-like systems
      isHidden = file.path.split(Platform.pathSeparator).last.startsWith('.');
      isExecutable = (await file.stat()).mode & 0x111 != 0;
      // Additional Unix permission detection would go here
    }
    
    // Basic implementation - in a real app, platform-specific code would
    // use native channels to get detailed information about file attributes
    
    return DesktopFileInfo(
      owner: owner,
      permissions: permissions,
      isHidden: isHidden,
      isSystem: isSystem,
      isExecutable: isExecutable,
    );
  }
} 