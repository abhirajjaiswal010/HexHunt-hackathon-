import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class URLValidatorService {
  static final URLValidatorService _instance = URLValidatorService._internal();
  factory URLValidatorService() => _instance;
  URLValidatorService._internal();

  /// Validates a URL string
  Future<URLValidationResult> validateURL(String url) async {
    try {
      // Basic URL format validation
      if (!_isValidURLFormat(url)) {
        return URLValidationResult(
          isValid: false,
          error: 'Invalid URL format',
          details: 'The URL does not follow the correct format (e.g., https://example.com)',
        );
      }

      // Normalize URL
      final normalizedUrl = _normalizeURL(url);
      
      // Check if URL is reachable
      final reachabilityResult = await _checkURLReachability(normalizedUrl);
      if (!reachabilityResult.isValid) {
        return reachabilityResult;
      }

      // Check for common fake URL patterns
      if (_isFakeURL(normalizedUrl)) {
        return URLValidationResult(
          isValid: false,
          error: 'Suspicious URL detected',
          details: 'This URL appears to be fake or malicious',
        );
      }

      // Check for valid SSL/TLS
      final sslResult = await _validateSSL(normalizedUrl);
      if (!sslResult.isValid) {
        return sslResult;
      }

      return URLValidationResult(
        isValid: true,
        url: normalizedUrl,
        details: 'URL is valid and secure',
      );
    } catch (e) {
      return URLValidationResult(
        isValid: false,
        error: 'Validation error',
        details: e.toString(),
      );
    }
  }

  /// Checks if the URL string follows a valid format
  bool _isValidURLFormat(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Normalizes the URL by adding scheme if missing and removing trailing slashes
  String _normalizeURL(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Checks if the URL is reachable
  Future<URLValidationResult> _checkURLReachability(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 400) {
        return URLValidationResult(
          isValid: true,
          url: url,
          details: 'URL is reachable',
        );
      } else {
        return URLValidationResult(
          isValid: false,
          error: 'URL not reachable',
          details: 'Server returned status code ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return URLValidationResult(
        isValid: false,
        error: 'Connection timeout',
        details: 'The URL took too long to respond',
      );
    } catch (e) {
      return URLValidationResult(
        isValid: false,
        error: 'Connection error',
        details: e.toString(),
      );
    }
  }

  /// Checks for common fake URL patterns
  bool _isFakeURL(String url) {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    // Check for common fake domain patterns
    final fakePatterns = [
      'fake',
      'scam',
      'phishing',
      'malicious',
      'suspicious',
      'dangerous',
      'hack',
      'crack',
      'warez',
      'illegal',
      'free-',
      'download-',
      'get-',
      'secure-',
      'verify-',
      'confirm-',
      'update-',
      'login-',
      'account-',
      'bank-',
      'paypal-',
      'amazon-',
      'ebay-',
      'facebook-',
      'google-',
      'apple-',
      'microsoft-',
      'netflix-',
      'spotify-',
    ];

    // Check for suspicious TLDs
    final suspiciousTLDs = [
      '.xyz',
      '.tk',
      '.ml',
      '.ga',
      '.cf',
      '.gq',
      '.pw',
      '.top',
      '.work',
      '.click',
      '.download',
      '.loan',
      '.win',
      '.bid',
      '.stream',
    ];

    // Check for IP addresses (often used in phishing)
    final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipPattern.hasMatch(host)) {
      return true;
    }

    // Check for suspicious patterns in the hostname
    for (final pattern in fakePatterns) {
      if (host.contains(pattern)) {
        return true;
      }
    }

    // Check for suspicious TLDs
    for (final tld in suspiciousTLDs) {
      if (host.endsWith(tld)) {
        return true;
      }
    }

    return false;
  }

  /// Validates SSL/TLS configuration
  Future<URLValidationResult> _validateSSL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'https') {
        return URLValidationResult(
          isValid: false,
          error: 'Insecure connection',
          details: 'URL must use HTTPS for security',
        );
      }

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('SSL validation timed out');
        },
      );

      if (response.statusCode == 200) {
        return URLValidationResult(
          isValid: true,
          url: url,
          details: 'SSL/TLS is properly configured',
        );
      } else {
        return URLValidationResult(
          isValid: false,
          error: 'SSL validation failed',
          details: 'Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return URLValidationResult(
        isValid: false,
        error: 'SSL validation error',
        details: e.toString(),
      );
    }
  }
}

class URLValidationResult {
  final bool isValid;
  final String? url;
  final String? error;
  final String details;

  URLValidationResult({
    required this.isValid,
    this.url,
    this.error,
    required this.details,
  });
} 
