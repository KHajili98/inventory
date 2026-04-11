import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads configuration from web/config.json
class AppConfig {
  static String? _baseUrl;

  static String get baseUrl => _baseUrl ?? 'http://13.53.43.184:8000';

  /// Load configuration from config.json
  /// Call this once at app startup
  static Future<void> load() async {
    try {
      final configString = await rootBundle.loadString('config.json');
      final config = jsonDecode(configString) as Map<String, dynamic>;
      _baseUrl = config['baseUrl'] as String?;
    } catch (e) {
      // If config.json doesn't exist or fails to load, use default
      print('Failed to load config.json: $e');
      _baseUrl = 'http://13.53.43.184:8000';
    }
  }
}
