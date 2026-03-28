import 'package:flutter/material.dart';
import 'package:inventory/l10n/app_localizations.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text(l10n.finance, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    );
  }
}
