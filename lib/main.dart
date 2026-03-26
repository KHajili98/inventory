import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:inventory/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

/// Custom scroll behaviour that enables mouse-drag scrolling on web/desktop
/// and suppresses the glow overscroll indicator (which can trigger browser
/// back/forward on some platforms).
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  // Allow scrolling with mouse, touch, and stylus
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  // Remove the overscroll glow that can bleed into browser navigation gestures
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Inventory',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      scrollBehavior: const _AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
    );
  }
}
