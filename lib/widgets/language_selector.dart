import 'package:flutter/material.dart';

/// Language selector widget - can be added to settings or app bar
///
/// Usage example:
/// ```dart
/// LanguageSelector(
///   currentLocale: Localizations.localeOf(context),
///   onLanguageChanged: (locale) {
///     // Implement language change logic here
///     // You'll need to use a state management solution like Provider
///     // or Riverpod to persist and change the app's locale
///   },
/// )
/// ```
class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      initialValue: currentLocale,
      icon: const Icon(Icons.language),
      tooltip: 'Change Language / Dili Dəyiş',
      onSelected: onLanguageChanged,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        const PopupMenuItem<Locale>(
          value: Locale('en'),
          child: Row(
            children: [
              Text('🇬🇧', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text('English'),
            ],
          ),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('az'),
          child: Row(
            children: [
              Text('🇦🇿', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text('Azərbaycan'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple language display chip - shows current language
class LanguageChip extends StatelessWidget {
  final Locale locale;

  const LanguageChip({super.key, required this.locale});

  String get _languageName {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'az':
        return 'Azərbaycan';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  String get _flagEmoji {
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧';
      case 'az':
        return '🇦🇿';
      default:
        return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(_flagEmoji, style: const TextStyle(fontSize: 16)),
      label: Text(_languageName),
      backgroundColor: const Color(0xFFEEF2FF),
      labelStyle: const TextStyle(
        color: Color(0xFF6366F1),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
