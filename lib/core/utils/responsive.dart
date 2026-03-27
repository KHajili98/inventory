import 'package:flutter/material.dart';

/// Responsive breakpoints for the application
class Breakpoints {
  /// Mobile: 0-600px
  static const double mobile = 600;

  /// Tablet: 601-900px
  static const double tablet = 900;

  /// Desktop: 901-1200px
  static const double desktop = 1200;

  /// Large desktop: 1201px+
  static const double largeDesktop = 1400;
}

/// Extension methods for responsive design
extension ResponsiveContext on BuildContext {
  /// Returns true if the screen width is less than or equal to mobile breakpoint
  bool get isMobile => MediaQuery.of(this).size.width <= Breakpoints.mobile;

  /// Returns true if the screen width is between mobile and tablet breakpoints
  bool get isTablet =>
      MediaQuery.of(this).size.width > Breakpoints.mobile &&
      MediaQuery.of(this).size.width <= Breakpoints.tablet;

  /// Returns true if the screen width is between tablet and desktop breakpoints
  bool get isDesktop =>
      MediaQuery.of(this).size.width > Breakpoints.tablet &&
      MediaQuery.of(this).size.width <= Breakpoints.desktop;

  /// Returns true if the screen width is greater than desktop breakpoint
  bool get isLargeDesktop => MediaQuery.of(this).size.width > Breakpoints.desktop;

  /// Returns true if the screen is mobile or tablet
  bool get isSmallScreen => MediaQuery.of(this).size.width <= Breakpoints.tablet;

  /// Returns true if the screen is desktop or larger
  bool get isLargeScreen => MediaQuery.of(this).size.width > Breakpoints.tablet;

  /// Returns the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Returns responsive padding based on screen size
  double get responsivePadding {
    if (isMobile) return 16;
    if (isTablet) return 20;
    return 24;
  }

  /// Returns responsive horizontal padding based on screen size
  EdgeInsets get responsiveHorizontalPadding => EdgeInsets.symmetric(horizontal: responsivePadding);

  /// Returns responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop && largeDesktop != null) return largeDesktop;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

/// Responsive builder widget for different screen sizes
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context)? mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;
  final Widget Function(BuildContext context)? largeDesktop;

  const ResponsiveBuilder({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isLargeDesktop && largeDesktop != null) {
      return largeDesktop!(context);
    }
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    }
    if (context.isTablet && tablet != null) {
      return tablet!(context);
    }
    if (mobile != null) {
      return mobile!(context);
    }

    // Fallback: use the first available builder
    return (largeDesktop ?? desktop ?? tablet ?? mobile)!(context);
  }
}

/// Helper class for responsive font sizes
class ResponsiveFontSize {
  static double heading1(BuildContext context) => context.responsive(
    mobile: 20,
    tablet: 22,
    desktop: 24,
  );

  static double heading2(BuildContext context) => context.responsive(
    mobile: 18,
    tablet: 19,
    desktop: 20,
  );

  static double heading3(BuildContext context) => context.responsive(
    mobile: 16,
    tablet: 17,
    desktop: 18,
  );

  static double body(BuildContext context) => context.responsive(
    mobile: 14,
    tablet: 14,
    desktop: 14,
  );

  static double small(BuildContext context) => context.responsive(
    mobile: 12,
    tablet: 12,
    desktop: 13,
  );

  static double tiny(BuildContext context) => context.responsive(
    mobile: 10,
    tablet: 11,
    desktop: 11,
  );
}

/// Helper class for responsive spacing
class ResponsiveSpacing {
  static double small(BuildContext context) => context.responsive(
    mobile: 4,
    tablet: 6,
    desktop: 8,
  );

  static double medium(BuildContext context) => context.responsive(
    mobile: 8,
    tablet: 10,
    desktop: 12,
  );

  static double large(BuildContext context) => context.responsive(
    mobile: 12,
    tablet: 16,
    desktop: 20,
  );

  static double xLarge(BuildContext context) => context.responsive(
    mobile: 16,
    tablet: 20,
    desktop: 24,
  );
}
