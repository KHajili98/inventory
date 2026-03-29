import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory/pages/invoice/expense_tracking_page.dart';
import 'package:inventory/pages/invoice/finance_page.dart';
import 'package:inventory/pages/inventory/inventory_products_page.dart';
import 'package:inventory/pages/invoice/invoices_page.dart';
import 'package:inventory/pages/finance/price_calculation_page.dart';
import 'package:inventory/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/invoices',
  // ── Disable browser back/forward history navigation on web ──────────────
  routerNeglect: kIsWeb,
  debugLogDiagnostics: false,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/invoices', builder: (context, state) => const InvoicesPage()),
        GoRoute(path: '/inventory-products', builder: (context, state) => const InventoryProductsPage()),
        GoRoute(path: '/finance', builder: (context, state) => const FinancePage()),
        GoRoute(path: '/finance/price-calculation', builder: (context, state) => const PriceCalculationPage()),
        GoRoute(path: '/finance/expense-tracking', builder: (context, state) => const ExpenseTrackingPage()),
      ],
    ),
  ],
);
