import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory/core/utils/route_logger.dart';
import 'package:inventory/features/auth/auth_cubit.dart';
import 'package:inventory/features/auth/auth_service.dart';
import 'package:inventory/models/auth_models.dart';
import 'package:inventory/pages/auth/login_page.dart';
import 'package:inventory/pages/finance/analytics_page.dart';
import 'package:inventory/pages/finance/expense/expense_tracking_page.dart';
import 'package:inventory/pages/kassa/kassa_page.dart';
import 'package:inventory/pages/inventory/inventory_products_page.dart';
import 'package:inventory/pages/requests/product_requests_page.dart';
import 'package:inventory/pages/stock/stock_page.dart';
import 'package:inventory/pages/invoice/invoices_page.dart';
import 'package:inventory/pages/finance/price_calculation/price_calculation_page.dart';
import 'package:inventory/pages/pos/pos/pos_page.dart';
import 'package:inventory/pages/pos/transactions/transaction_list_page.dart';
import 'package:inventory/pages/pos/returns/returned_products_page.dart';
import 'package:inventory/pages/customers/loyal_customers_page.dart';
import 'package:inventory/widgets/app_shell.dart';
import 'package:inventory/widgets/kassa_status_guard.dart';

/// Global navigator key — used by the Dio interceptor to redirect on 401
/// without needing a BuildContext.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that don't require authentication.
const _publicRoutes = ['/login'];

/// Routes forbidden for [UserRole.salesRep].
const _salesRepForbiddenRoutes = ['/invoices', '/finance/analytics', '/finance/price-calculation'];

/// Routes allowed for [UserRole.warehouseStaff] (whitelist).
const _warehouseStaffAllowedRoutes = ['/invoices', '/inventory-products'];

/// Returns the default landing path for [role].
String _defaultPathForRole(UserRole role) {
  if (role == UserRole.warehouseStaff) return '/invoices';
  return '/invoices';
}

/// A [ChangeNotifier] that bridges [AuthCubit] state changes into GoRouter's
/// [refreshListenable], so the router re-runs redirect on every auth change.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    routerNeglect: kIsWeb,
    debugLogDiagnostics: false,
    observers: [RouteLogger()],
    refreshListenable: _AuthNotifier(authCubit),
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);
      final isLoggedIn = await AuthService.instance.isLoggedIn();

      // Not logged in → always redirect to /login
      if (!isLoggedIn && !isPublic) return '/login';

      // Already logged in → redirect away from /login
      if (isLoggedIn && isPublic) {
        final loginResponse = await AuthService.instance.getLoginResponse();
        final role = loginResponse?.user.role ?? UserRole.unknown;
        return _defaultPathForRole(role);
      }

      // Role-based access control for authenticated users
      if (isLoggedIn && !isPublic) {
        final loginResponse = await AuthService.instance.getLoginResponse();
        final role = loginResponse?.user.role ?? UserRole.unknown;

        // warehouse_staff: only allowed routes whitelist
        if (role == UserRole.warehouseStaff) {
          final allowed = _warehouseStaffAllowedRoutes.any((r) => location.startsWith(r));
          if (!allowed) return '/invoices';
        }

        // sales_rep: block forbidden routes
        if (role == UserRole.salesRep) {
          final forbidden = _salesRepForbiddenRoutes.any((r) => location.startsWith(r));
          if (forbidden) return '/inventory-products';
        }
      }

      return null; // no redirect needed
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        observers: [RouteLogger()],
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/sell-module/pos',
            builder: (context, state) => const KassaStatusGuard(child: PosPage()),
          ),
          GoRoute(path: '/sell-module/transactions', builder: (context, state) => const TransactionListPage()),
          GoRoute(path: '/sell-module/returns', builder: (context, state) => const ReturnedProductsPage()),
          GoRoute(path: '/invoices', builder: (context, state) => const InvoicesPage()),
          GoRoute(path: '/inventory-products', builder: (context, state) => const InventoryProductsPage()),
          GoRoute(path: '/stock', builder: (context, state) => const StockPage()),
          GoRoute(path: '/product-requests', builder: (context, state) => const ProductRequestsPage()),
          GoRoute(path: '/loyal-customers', builder: (context, state) => const LoyalCustomersPage()),
          GoRoute(path: '/finance/price-calculation', builder: (context, state) => const PriceCalculationPage()),
          GoRoute(path: '/finance/expense-tracking', builder: (context, state) => const ExpenseTrackingPage()),
          GoRoute(path: '/finance/analytics', builder: (context, state) => const AnalyticsPage()),
          GoRoute(path: '/kassa', builder: (context, state) => const KassaPage()),
        ],
      ),
    ],
  );
}

// Keep a late reference so DioClient interceptor can still call appRouter.go()
late final GoRouter appRouter;
