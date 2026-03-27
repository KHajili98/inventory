# Localization Guide

This project supports multiple languages using Flutter's built-in localization system.

## Supported Languages

- **English (en)**: Default language
- **Azerbaijani (az)**: Azerbaijan language

## How to Use Localization in Your Code

### 1. Import the localization package

```dart
import 'package:inventory/l10n/app_localizations.dart';
```

### 2. Access localized strings

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Text(l10n.invoices); // Will show "Invoices" or "Qaimələr" based on locale
}
```

### 3. Add New Translations

To add new translatable strings:

1. **Add to English ARB file** (`lib/l10n/app_en.arb`):
```json
{
  "myNewKey": "My New Text",
  "@myNewKey": {
    "description": "Description of what this text is for"
  }
}
```

2. **Add to Azerbaijan ARB file** (`lib/l10n/app_az.arb`):
```json
{
  "myNewKey": "Mənim Yeni Mətn"
}
```

3. **Regenerate localization files**:
```bash
flutter gen-l10n
```

4. **Use in your code**:
```dart
Text(l10n.myNewKey)
```

## Available Translations

See `lib/l10n/app_en.arb` for all available translation keys. Some commonly used ones:

- `l10n.appTitle` - App title
- `l10n.invoices` - Invoices
- `l10n.inventoryProducts` - Inventory Products
- `l10n.finance` - Finance
- `l10n.pending` - Pending status
- `l10n.confirmed` - Confirmed status
- `l10n.cancel` - Cancel button
- `l10n.delete` - Delete action
- `l10n.edit` - Edit button
- `l10n.export` - Export action
- And many more...

## Adding More Languages

To add support for additional languages:

1. Create a new ARB file: `lib/l10n/app_{locale}.arb` (e.g., `app_tr.arb` for Turkish)
2. Copy all keys from `app_en.arb` and translate the values
3. Add the locale to `supportedLocales` in `lib/main.dart`:
```dart
supportedLocales: const [
  Locale('en'),
  Locale('az'),
  Locale('tr'), // New language
],
```
4. Run `flutter gen-l10n` to generate the new localization files

## How the System Detects Language

The app uses **Cubit** (from flutter_bloc) to manage the selected language. A language selector button is available in the top-right corner of the app header.

### Changing Language Programmatically

You can change the language from anywhere in the app using:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/cubit/locale_cubit.dart';

// Change to English
context.read<LocaleCubit>().setEnglish();

// Change to Azerbaijani
context.read<LocaleCubit>().setAzerbaijani();

// Toggle between languages
context.read<LocaleCubit>().toggleLanguage();

// Change to any locale
context.read<LocaleCubit>().changeLanguage(const Locale('az'));
```

### Current Language

To get the current language:

```dart
// Using BlocBuilder
BlocBuilder<LocaleCubit, Locale>(
  builder: (context, locale) {
    return Text('Current: ${locale.languageCode}');
  },
)

// Or directly
final currentLocale = context.read<LocaleCubit>().state;
```

## Files Structure

```
lib/
  cubit/
    locale_cubit.dart           # Language state management
  l10n/
    app_en.arb                  # English translations
    app_az.arb                  # Azerbaijan translations
    app_localizations.dart      # Generated - DO NOT EDIT
    app_localizations_en.dart   # Generated - DO NOT EDIT
    app_localizations_az.dart   # Generated - DO NOT EDIT
  widgets/
    app_shell.dart              # Contains language selector button
    language_selector.dart      # Standalone language selector widget
l10n.yaml                       # Localization configuration
pubspec.yaml                    # Dependencies (flutter_bloc, intl, etc.)
```

## Tips

1. **Always use `l10n` for user-facing text** - Never hardcode strings in widgets
2. **Provide meaningful keys** - Use descriptive names like `totalInvoices` instead of `text1`
3. **Add descriptions** - Always include `@keyName` descriptions in ARB files
4. **Keep translations updated** - When adding new English text, immediately add Azerbaijan translation
5. **Test both languages** - Change your device language to test the Azerbaijan version

## Examples in the Codebase

Check these files for localization examples:
- `lib/widgets/app_shell.dart` - Navigation and sidebar
- `lib/pages/invoices_page.dart` - Invoices page with stats and actions
- `lib/pages/finance_page.dart` - Simple page example
- `lib/main.dart` - App configuration with localization setup
