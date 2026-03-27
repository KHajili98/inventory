import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/router/app_router.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/cubit/locale_cubit.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => LocaleCubit(),
      child: const MyApp(),
    ),
  );
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
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp.router(
          title: 'Inventory',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          scrollBehavior: const _AppScrollBehavior(),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('az'), // Azerbaijan
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
            fontFamily: 'Inter',
            useMaterial3: true,
          ),
        );
      },
    );
  }
}
