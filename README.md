# HexHunt Security

A comprehensive cybersecurity threat scanning and monitoring application, designed specifically for desktop platforms.

## Features

- **Desktop-Optimized UI**: Purpose-built for large screens with efficient keyboard/mouse navigation
- **System Integration**: System tray support, desktop notifications, and global hotkeys
- **File System Access**: Scan local files and directories for vulnerabilities
- **Threat Visualization**: Rich dashboard with vulnerability distribution and threat trends
- **AI-Powered Analysis**: Machine learning models for identifying and classifying security threats
- **Export Reports**: Export scan results as PDF, CSV, or JSON for further analysis

## Desktop Platform Support

HexHunt supports the following desktop platforms:

- **Windows**: Windows 10 and later
- **macOS**: macOS 10.14 (Mojave) and later
- **Linux**: Major distributions with GTK 3.x

## Installation

### Prerequisites

- Flutter SDK 3.10 or higher
- Dart SDK 3.0 or higher

### Enable Desktop Support

To enable Flutter desktop support for your platform, run:

```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

### Clone and Install

```bash
git clone https://github.com/yourusername/hexhunt.git
cd hexhunt
flutter pub get
```

## Running the Application

### Debug Mode

```bash
# For Windows
flutter run -d windows

# For macOS
flutter run -d macos

# For Linux
flutter run -d linux
```

### Release Mode

```bash
# For Windows
flutter build windows
# The application will be in build/windows/runner/Release/

# For macOS
flutter build macos
# The application will be in build/macos/Build/Products/Release/

# For Linux
flutter build linux
# The application will be in build/linux/x64/release/bundle/
```

## Desktop-Specific Features

### Global Hotkeys

- `Ctrl+Shift+S`: Quick scan (works even when app is in background)
- `Ctrl+N`: Start new scan
- `Ctrl+R`: View reports
- `Ctrl+,`: Open settings

### System Tray Integration

HexHunt minimizes to the system tray and continues monitoring in the background. Right-click the tray icon to access quick actions.

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Export Report | Ctrl+E |
| Configure Scan | Ctrl+C |
| View History | Ctrl+H |
| Compare Results | Ctrl+O |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for desktop support
- [FL Chart](https://pub.dev/packages/fl_chart) for data visualization
- [window_manager](https://pub.dev/packages/window_manager) and [bitsdojo_window](https://pub.dev/packages/bitsdojo_window) for desktop window management
