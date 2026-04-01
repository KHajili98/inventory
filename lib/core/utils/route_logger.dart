import 'dart:developer' as dev;

import 'package:flutter/material.dart';

/// Pretty-prints navigation events to the debug console.
///
/// Push:  ▶ PriceCalculationPage → CalculationDetailPage
/// Pop:   ◀ CalculationDetailPage ← PriceCalculationPage
/// Replace: ↔ LoginPage  →  InvoicesPage
class RouteLogger extends NavigatorObserver {
  static const String _tag = '🧭 Router';

  static String _name(Route<dynamic>? route) {
    if (route == null) return '(none)';
    final settings = route.settings;
    if (settings.name != null && settings.name!.isNotEmpty) return settings.name!;
    // MaterialPageRoute / custom routes — extract type name
    return route.runtimeType.toString().replaceAll('_', '').replaceAll('MaterialPageRoute<', 'Page<');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    dev.log('▶  ${_name(previousRoute)}  →  ${_name(route)}', name: _tag);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    dev.log('◀  ${_name(route)}  ←  ${_name(previousRoute)}', name: _tag);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    dev.log('↔  ${_name(oldRoute)}  →  ${_name(newRoute)}', name: _tag);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    dev.log('✕  ${_name(route)}  (removed, below: ${_name(previousRoute)})', name: _tag);
  }
}
