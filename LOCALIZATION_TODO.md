# Localization Update Checklist

## ✅ Completed Files

- [x] `lib/main.dart` - App setup with localization
- [x] `lib/widgets/app_shell.dart` - Navigation sidebar
- [x] `lib/pages/invoices_page.dart` - Main invoices page (partially)
- [x] `lib/pages/finance_page.dart` - Finance page
- [x] `lib/l10n/app_en.arb` - English translations
- [x] `lib/l10n/app_az.arb` - Azerbaijan translations

## 📝 Files Needing Localization Updates

### 1. `lib/pages/invoices_page.dart` - OCR Dialog
The OCR processing dialog still has hardcoded strings. Update these:

```dart
// Current:
const Text('Processing Invoice Image')
const Text('Uploading image…')
const Text('Running OCR…')
const Text('OCR Complete!')

// Should be:
Text(l10n.processingInvoiceImage)
Text(l10n.uploadingImage)
Text(l10n.runningOCR)
Text(l10n.ocrComplete)
```

**Location**: `_OcrProcessingDialog` class (~line 280-516)

### 2. `lib/pages/invoice_detail_page.dart`
Update all hardcoded strings:

```dart
// Add import at top:
import 'package:inventory/l10n/app_localizations.dart';

// Update strings like:
const Text('Export') → Text(l10n.export)
const Text('Edit') → Text(l10n.edit)
const Text('Done') → Text(l10n.done)
const Text('Total Items') → Text(l10n.totalItems)
const Text('Add Row') → Text(l10n.addRow)
```

**Common locations**: Headers, buttons, column headers, summary cards

### 3. `lib/pages/inventory_products_page.dart`
Large file with many strings to translate:

**Key areas to update**:
- Search placeholder: `'Search products...'` → `l10n.search`
- Filter dropdown: `'All Statuses'` → `l10n.allStatuses`
- Status labels: `'In Stock'`, `'Low Stock'`, `'Out of Stock'`
- Column headers: SKU, Name, Color, Quantity, etc.
- Stats cards: Total Products, Total Quantity, etc.
- Action buttons: View, Edit, Delete

**Suggested approach**:
1. Add `final l10n = AppLocalizations.of(context)!;` at the start of build methods
2. Replace each hardcoded string with `l10n.keyName`
3. If you find new strings not in ARB files, add them first

## 🎯 Quick Copy-Paste Template

Add this at the start of any widget's `build` method:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  // ... rest of code
}
```

## 📋 Common String Replacements

| Current String | Replace With |
|---------------|--------------|
| `'Search'` | `l10n.search` |
| `'Delete'` | `l10n.delete` |
| `'Edit'` | `l10n.edit` |
| `'Export'` | `l10n.export` |
| `'Cancel'` | `l10n.cancel` |
| `'Pending'` | `l10n.pending` |
| `'Confirmed'` | `l10n.confirmed` |
| `'Total Items'` | `l10n.totalItems` |
| `'pcs'` | `l10n.pcs` |

## 🔧 Steps to Add Missing Translations

If you find a string that's not in the ARB files:

1. **Add to `lib/l10n/app_en.arb`**:
```json
"yourNewKey": "Your English Text",
"@yourNewKey": {
  "description": "Where this text appears"
}
```

2. **Add to `lib/l10n/app_az.arb`**:
```json
"yourNewKey": "Azərbaycan dilində mətn"
```

3. **Regenerate**:
```bash
flutter gen-l10n
```

4. **Use in code**:
```dart
Text(l10n.yourNewKey)
```

## 🌍 Testing Different Languages

To test Azerbaijan language:

1. **iOS Simulator**: Settings → General → Language & Region → Add Language → Azerbaijani
2. **Android Emulator**: Settings → System → Languages → Add Language → Azərbaycan dili
3. **Chrome DevTools**: Console → `navigator.language` to check current locale

Or add a language selector in your app UI for easier testing.

## 📝 Notes

- The OCR dialog in `invoices_page.dart` has complex nested strings
- Inventory products page is very large (~2000 lines) - take your time
- Some widgets use `Builder` context when parent context doesn't have localization
- Remember to import `app_localizations.dart` in each file you update
