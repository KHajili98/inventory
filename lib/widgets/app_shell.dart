import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(label: 'Invoices', icon: Icons.receipt_long, path: '/invoices'),
    _NavItem(label: 'Inventory Products', icon: Icons.inventory_2, path: '/inventory-products'),
    _NavItem(label: 'Finance', icon: Icons.account_balance_wallet, path: '/finance'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems.indexWhere((item) => location.startsWith(item.path));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      body: Row(
        children: [
          // ── Left sidebar ──────────────────────────────────────────────
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(2, 0))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / App name
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Inventory',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                const SizedBox(height: 12),

                // Nav items
                ...List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isSelected = index == selectedIndex;

                  return _SidebarTile(item: item, isSelected: isSelected, onTap: () => context.go(item.path));
                }),
              ],
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
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

                // Page body
                Expanded(
                  child: Container(color: const Color(0xFFF8FAFC), child: child),
                ),
              ],
            ),
          ),
        ],
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
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.isSelected, required this.onTap});

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
        ? Colors.white.withOpacity(0.07)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(widget.item.icon, color: widget.isSelected ? Colors.white : const Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 12),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
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
