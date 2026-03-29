import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/cubit/locale_cubit.dart';
import 'package:inventory/core/utils/responsive.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  bool _collapsed = false;
  // Track which nav items have their submenu expanded (by index)
  final Set<int> _expandedItems = {};

  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 68;
  static const Duration _duration = Duration(milliseconds: 220);
  static const Curve _curve = Curves.easeInOut;

  static const _navItems = [
    _NavItem(labelKey: 'pos', icon: Icons.point_of_sale_rounded, path: '/pos'),
    _NavItem(labelKey: 'invoices', icon: Icons.receipt_long_rounded, path: '/invoices'),
    _NavItem(labelKey: 'inventoryProducts', icon: Icons.inventory_2_rounded, path: '/inventory-products'),
    _NavItem(labelKey: 'stock', icon: Icons.warehouse_rounded, path: '/stock'),
    _NavItem(
      labelKey: 'finance',
      icon: Icons.account_balance_wallet_rounded,
      path: '/finance/analytics',
      subItems: [
        _SubNavItem(labelKey: 'analytics', path: '/finance/analytics'),

        _SubNavItem(labelKey: 'priceCalculation', path: '/finance/price-calculation'),
        _SubNavItem(labelKey: 'expenseTracking', path: '/finance/expense-tracking'),
      ],
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems.indexWhere((item) => location.startsWith(item.path) || item.subItems.any((sub) => location.startsWith(sub.path)));
    return index < 0 ? 0 : index;
  }

  String _getNavLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'pos':
        return l10n.pos;
      case 'invoices':
        return l10n.invoices;
      case 'inventoryProducts':
        return l10n.inventoryProducts;
      case 'stock':
        return l10n.stock;
      case 'finance':
        return l10n.finance;
      case 'priceCalculation':
        return l10n.priceCalculation;
      case 'expenseTracking':
        return l10n.expenseTracking;
      case 'analytics':
        return l10n.analytics;
      default:
        return key;
    }
  }

  /// Consumes the pointer signal so the browser never sees it
  /// as a back/forward swipe. Only blocks when horizontal component
  /// is dominant (pure vertical scrolls are left alone).
  void _onPointerSignal(PointerSignalEvent event) {
    if (!kIsWeb) return;
    if (event is PointerScrollEvent) {
      final dx = event.scrollDelta.dx.abs();
      final dy = event.scrollDelta.dy.abs();
      // If horizontal scroll dominates → consume it completely
      if (dx > dy || dx > 10) {
        GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
      child: Listener(
        // Block horizontal trackpad swipe from reaching the browser
        onPointerSignal: _onPointerSignal,
        // Also block pointer pan/zoom events (two-finger drag on trackpad)
        onPointerPanZoomUpdate: kIsWeb
            ? (event) {
                final dx = event.panDelta.dx.abs();
                final dy = event.panDelta.dy.abs();
                if (dx > dy || dx > 5) {
                  // Absorb — prevent browser back/forward
                }
              }
            : null,
        behavior: HitTestBehavior.translucent,
        child: ScrollConfiguration(
          // Completely disable browser-native scrolling gestures
          // by overriding the scroll behavior for all descendants
          behavior: _NoHistoryScrollBehavior(),
          child: Scaffold(
            // Mobile: use drawer, Desktop: inline sidebar
            drawer: isMobile ? _buildMobileDrawer(context, selectedIndex, l10n) : null,
            // Mobile: use bottom navigation
            // bottomNavigationBar: isMobile ? _buildBottomNav(context, selectedIndex, l10n) : null,
            body: Row(
              children: [
                // ── Sidebar (desktop only) ────────────────────────────────
                if (!isMobile)
                  AnimatedContainer(
                    duration: _duration,
                    curve: _curve,
                    width: _collapsed ? _collapsedWidth : _expandedWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(2, 0))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logo row ─────────────────────────────────────────
                        SizedBox(
                          height: 72,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _collapsed = !_collapsed),
                                    child: Tooltip(
                                      message: _collapsed ? l10n.expandSidebar : l10n.collapseSidebar,
                                      preferBelow: false,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ),
                                ClipRect(
                                  child: AnimatedSize(
                                    duration: _duration,
                                    curve: _curve,
                                    child: _collapsed
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.only(left: 12),
                                            child: Text(
                                              l10n.appTitle,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                        ),
                        const SizedBox(height: 10),

                        // ── Nav items ────────────────────────────────────────
                        ...List.generate(_navItems.length, (index) {
                          final item = _navItems[index];
                          final isSelected = index == selectedIndex;
                          final hasSubItems = item.subItems.isNotEmpty;
                          final isExpanded = _expandedItems.contains(index);
                          final location = GoRouterState.of(context).uri.toString();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SidebarTile(
                                item: item,
                                isSelected: isSelected,
                                collapsed: _collapsed,
                                hasSubItems: hasSubItems,
                                isExpanded: isExpanded,
                                onTap: () {
                                  if (hasSubItems) {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedItems.remove(index);
                                      } else {
                                        _expandedItems.add(index);
                                      }
                                    });
                                    if (!isExpanded) context.go(item.path);
                                  } else {
                                    context.go(item.path);
                                  }
                                },
                                label: _getNavLabel(context, item.labelKey),
                              ),
                              if (hasSubItems && isExpanded && !_collapsed)
                                ...item.subItems.map((sub) {
                                  final isSubSelected = location.startsWith(sub.path);
                                  return _SubSidebarTile(
                                    sub: sub,
                                    isSelected: isSubSelected,
                                    onTap: () => context.go(sub.path),
                                    label: _getNavLabel(context, sub.labelKey),
                                  );
                                }),
                            ],
                          );
                        }),

                        const Spacer(),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: AnimatedSwitcher(
                            duration: _duration,
                            child: _collapsed
                                ? Tooltip(
                                    message: l10n.expandSidebar,
                                    preferBelow: false,
                                    child: InkWell(
                                      onTap: () => setState(() => _collapsed = false),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF475569)),
                                      const SizedBox(width: 6),
                                      Text(l10n.versionInfo, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Main content ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: isMobile ? 56 : 64,
                        padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            // Mobile: show hamburger menu
                            if (isMobile)
                              Builder(
                                builder: (context) => IconButton(
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                  icon: const Icon(Icons.menu_rounded, size: 24),
                                  style: IconButton.styleFrom(foregroundColor: const Color(0xFF1E293B)),
                                ),
                              ),
                            if (isMobile) const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getNavLabel(context, _navItems[selectedIndex].labelKey),
                                style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const _LanguageSelector(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(color: const Color(0xFFF8FAFC), child: widget.child),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mobile drawer
  Widget _buildMobileDrawer(BuildContext context, int selectedIndex, AppLocalizations l10n) {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.appTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 10),

            // Nav items
            ...List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = index == selectedIndex;
              final hasSubItems = item.subItems.isNotEmpty;
              final isExpanded = _expandedItems.contains(index);
              final location = GoRouterState.of(context).uri.toString();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MobileDrawerTile(
                    item: item,
                    isSelected: isSelected,
                    hasSubItems: hasSubItems,
                    isExpanded: isExpanded,
                    onTap: () {
                      if (hasSubItems) {
                        setState(() {
                          if (isExpanded) {
                            _expandedItems.remove(index);
                          } else {
                            _expandedItems.add(index);
                          }
                        });
                        if (!isExpanded) {
                          Navigator.pop(context);
                          context.go(item.path);
                        }
                      } else {
                        Navigator.pop(context);
                        context.go(item.path);
                      }
                    },
                    label: _getNavLabel(context, item.labelKey),
                  ),
                  if (hasSubItems && isExpanded)
                    ...item.subItems.map((sub) {
                      final isSubSelected = location.startsWith(sub.path);
                      return _MobileDrawerSubTile(
                        sub: sub,
                        isSelected: isSubSelected,
                        onTap: () {
                          Navigator.pop(context);
                          context.go(sub.path);
                        },
                        label: _getNavLabel(context, sub.labelKey),
                      );
                    }),
                ],
              );
            }),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Text(l10n.versionInfo, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom navigation bar for mobile
  Widget _buildBottomNav(BuildContext context, int selectedIndex, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = index == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8), size: 24),
                      const SizedBox(height: 4),
                      Text(
                        _getNavLabel(context, item.labelKey),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Scroll behavior that strips browser history gestures ──────────────────────

class _NoHistoryScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child; // no glow — glow on web can trigger browser nav gestures

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics(); // clamp instead of bouncing — bounce can trigger browser nav
}

// ── Animated burger / arrow toggle ────────────────────────────────────────────

class _CollapseButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _CollapseButton({required this.collapsed, required this.onTap});

  @override
  State<_CollapseButton> createState() => _CollapseButtonState();
}

class _CollapseButtonState extends State<_CollapseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: widget.collapsed ? l10n.expandSidebar : l10n.collapseSidebar,
      preferBelow: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: widget.collapsed
                  ? const Icon(Icons.menu_open_rounded, key: ValueKey('open'), color: Color(0xFF94A3B8), size: 18)
                  : const Icon(Icons.menu_rounded, key: ValueKey('closed'), color: Color(0xFF94A3B8), size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _SubNavItem {
  final String labelKey;
  final String path;
  const _SubNavItem({required this.labelKey, required this.path});
}

class _NavItem {
  final String labelKey;
  final IconData icon;
  final String path;
  final List<_SubNavItem> subItems;
  const _NavItem({required this.labelKey, required this.icon, required this.path, this.subItems = const []});
}

// ── Sidebar tile ──────────────────────────────────────────────────────────────

class _SidebarTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final bool collapsed;
  final bool hasSubItems;
  final bool isExpanded;
  final VoidCallback onTap;
  final String label;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.collapsed,
    required this.onTap,
    required this.label,
    this.hasSubItems = false,
    this.isExpanded = false,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? const Color(0xFF6366F1)
        : _hovered
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.transparent;

    final iconColor = widget.isSelected ? Colors.white : const Color(0xFF94A3B8);

    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.isSelected ? Colors.white.withValues(alpha: 0.6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.item.icon, color: iconColor, size: 15),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: widget.collapsed
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: widget.isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                    fontSize: 14,
                                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (widget.hasSubItems)
                                AnimatedRotation(
                                  turns: widget.isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: widget.isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: widget.collapsed ? Tooltip(message: widget.label, preferBelow: false, child: tile) : tile,
    );
  }
}

// ── Sub-sidebar tile ──────────────────────────────────────────────────────────

class _SubSidebarTile extends StatefulWidget {
  final _SubNavItem sub;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  const _SubSidebarTile({required this.sub, required this.isSelected, required this.onTap, required this.label});

  @override
  State<_SubSidebarTile> createState() => _SubSidebarTileState();
}

class _SubSidebarTileState extends State<_SubSidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? Colors.white.withValues(alpha: 0.12)
        : _hovered
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 10, top: 1, bottom: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: widget.isSelected ? const Color(0xFF6366F1) : const Color(0xFF475569), shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile Drawer Tile ────────────────────────────────────────────────────────

class _MobileDrawerTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool hasSubItems;
  final bool isExpanded;
  final VoidCallback onTap;
  final String label;

  const _MobileDrawerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.label,
    this.hasSubItems = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(item.icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (hasSubItems)
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                )
              else if (isSelected)
                const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile Drawer Sub Tile ────────────────────────────────────────────────────

class _MobileDrawerSubTile extends StatelessWidget {
  final _SubNavItem sub;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  const _MobileDrawerSubTile({required this.sub, required this.isSelected, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 12, top: 1, bottom: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF475569), shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected) const Icon(Icons.check_rounded, color: Color(0xFF6366F1), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language Selector ─────────────────────────────────────────────────────────

class _LanguageSelector extends StatefulWidget {
  const _LanguageSelector();

  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  bool _hovered = false;

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'az':
        return 'Azərbaycan';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  String _getFlagEmoji(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧';
      case 'az':
        return '🇦🇿';
      default:
        return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, currentLocale) {
        return PopupMenuButton<Locale>(
          offset: const Offset(0, 50),
          tooltip: currentLocale.languageCode == 'en' ? 'Change Language' : 'Dili Dəyiş',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (locale) {
            context.read<LocaleCubit>().changeLanguage(locale);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
            PopupMenuItem<Locale>(
              value: const Locale('en'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(_getFlagEmoji(const Locale('en')), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    const Text('English', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    if (currentLocale.languageCode == 'en') const Icon(Icons.check_rounded, size: 18, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<Locale>(
              value: const Locale('az'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(_getFlagEmoji(const Locale('az')), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    const Text('Azərbaycan', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    if (currentLocale.languageCode == 'az') const Icon(Icons.check_rounded, size: 18, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ),
          ],
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: isMobile ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6) : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _hovered ? const Color(0xFFF1F5F9) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _hovered ? const Color(0xFFE2E8F0) : Colors.transparent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getFlagEmoji(currentLocale), style: TextStyle(fontSize: isMobile ? 18 : 20)),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Text(
                      _getLanguageName(currentLocale),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _hovered ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
