import 'package:flutter/material.dart';
import 'package:inventory/l10n/app_localizations.dart';

class ExpenseTrackingPage extends StatelessWidget {
  const ExpenseTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text(l10n.expenseTracking, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    );
  }
}
