import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory/pages/auth/login_page.dart';
import 'package:inventory/pages/finance/analytics_page.dart';
import 'package:inventory/pages/finance/expense_tracking_page.dart';
import 'package:inventory/pages/inventory/inventory_products_page.dart';
import 'package:inventory/pages/inventory/product_requests_page.dart';
import 'package:inventory/pages/inventory/stock_page.dart';
import 'package:inventory/pages/invoice/invoices_page.dart';
import 'package:inventory/pages/finance/price_calculation_page.dart';
import 'package:inventory/pages/pos/pos_page.dart';
import 'package:inventory/widgets/app_shell.dart';

/// Global navigator key — used by the Dio interceptor to redirect on 401
/// without needing a BuildContext.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routerNeglect: kIsWeb,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/pos', builder: (context, state) => const PosPage()),
        GoRoute(path: '/invoices', builder: (context, state) => const InvoicesPage()),
        GoRoute(path: '/inventory-products', builder: (context, state) => const InventoryProductsPage()),
        GoRoute(path: '/stock', builder: (context, state) => const StockPage()),
        GoRoute(path: '/product-requests', builder: (context, state) => const ProductRequestsPage()),
        GoRoute(path: '/finance/price-calculation', builder: (context, state) => const PriceCalculationPage()),
        GoRoute(path: '/finance/expense-tracking', builder: (context, state) => const ExpenseTrackingPage()),
        GoRoute(path: '/finance/analytics', builder: (context, state) => const AnalyticsPage()),
      ],
    ),
  ],
);
