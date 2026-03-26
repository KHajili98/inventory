import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  bool _collapsed = false;

  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 68;
  static const Duration _duration = Duration(milliseconds: 220);
  static const Curve _curve = Curves.easeInOut;

  static const _navItems = [
    _NavItem(label: 'Invoices', icon: Icons.receipt_long_rounded, path: '/invoices'),
    _NavItem(label: 'Inventory Products', icon: Icons.inventory_2_rounded, path: '/inventory-products'),
    _NavItem(label: 'Finance', icon: Icons.account_balance_wallet_rounded, path: '/finance'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems.indexWhere((item) => location.startsWith(item.path));
    return index < 0 ? 0 : index;
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
            body: Row(
              children: [
                // ── Animated sidebar ───────────────────────────────────────
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
                                    message: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
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
                                      : const Padding(
                                          padding: EdgeInsets.only(left: 12),
                                          child: Text(
                                            'Inventory',
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
                        return _SidebarTile(item: item, isSelected: isSelected, collapsed: _collapsed, onTap: () => context.go(item.path));
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
                                  message: 'Expand sidebar',
                                  preferBelow: false,
                                  child: InkWell(
                                    onTap: () => setState(() => _collapsed = false),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                                    ),
                                  ),
                                )
                              : const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF475569)),
                                    SizedBox(width: 6),
                                    Text('v1.0.0 · Inventory App', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
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
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _navItems[selectedIndex].label,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
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
    return Tooltip(
      message: widget.collapsed ? 'Expand sidebar' : 'Collapse sidebar',
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

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.path});
}

// ── Sidebar tile ──────────────────────────────────────────────────────────────

class _SidebarTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.isSelected, required this.collapsed, required this.onTap});

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
                          child: Text(
                            widget.item.label,
                            style: TextStyle(
                              color: widget.isSelected ? Colors.white : const Color(0xFFCBD5E1),
                              fontSize: 14,
                              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
      child: widget.collapsed ? Tooltip(message: widget.item.label, preferBelow: false, child: tile) : tile,
    );
  }
}
