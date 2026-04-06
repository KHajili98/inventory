import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/stocks/data/models/stock_product_response_model.dart';
import 'package:inventory/features/stocks/data/repositories/stocks_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/pages/finance/price_history_page.dart';
import 'package:intl/intl.dart';

// ── Priced History List Page ──────────────────────────────────────────────────
// Shows all priced=true stock items. Tapping one opens PriceHistoryPage.

class PricedHistoryListPage extends StatefulWidget {
  const PricedHistoryListPage({super.key});

  @override
  State<PricedHistoryListPage> createState() => _PricedHistoryListPageState();
}

class _PricedHistoryListPageState extends State<PricedHistoryListPage> {
  final _repo = StocksRepository.instance;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<StockProductItemModel> _items = [];
  int _totalCount = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _items = [];
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final page = reset ? 1 : _currentPage + 1;
    final search = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

    final result = await _repo.fetchStocks(page: page, pageSize: _pageSize, search: search, priced: true);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _totalCount = data.count;
          _hasMore = data.next != null;
          _currentPage = page;
          _isLoading = false;
          _isLoadingMore = false;
          _items = reset ? data.results : [..._items, ...data.results];
        });
      case Failure(:final message):
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = message;
        });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.priceHistory, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Search + count bar ────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: l10n.searchPlaceholder,
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '$_totalCount ${l10n.items}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : _items.isEmpty
                ? _EmptyView(l10n: l10n)
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification && n.metrics.axis == Axis.vertical) {
                        final px = n.metrics.pixels;
                        final max = n.metrics.maxScrollExtent;
                        if (max > 0 && px >= max - 200 && _hasMore && !_isLoadingMore) {
                          _load(reset: false);
                        }
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return const Center(
                            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        return _ItemCard(
                          item: _items[index],
                          l10n: l10n,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              settings: const RouteSettings(name: 'PriceHistoryPage'),
                              builder: (_) => PriceHistoryPage(item: _items[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Item Card ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final StockProductItemModel item;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastEntry = item.changeHistory.isNotEmpty ? item.changeHistory.last : null;
    final changeCount = item.changeHistory.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // ── Icon ────────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Icon(Icons.history_rounded, color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 14),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productGeneratedName?.isNotEmpty == true ? item.productGeneratedName! : (item.productName ?? '—'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (item.barcode?.isNotEmpty == true) _Tag(item.barcode!),
                      if (item.modelCode?.isNotEmpty == true) _Tag(item.modelCode!),
                      _Tag(item.inventoryName),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Current prices
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (item.costUnitPrice != null)
                        _PriceTag(label: l10n.costUnitPriceLabel, value: item.costUnitPrice!, color: const Color(0xFF6366F1)),
                      if (item.wholeUnitSalesPrice != null)
                        _PriceTag(label: l10n.wholeUnitSalesPriceLabel, value: item.wholeUnitSalesPrice!, color: const Color(0xFF0EA5E9)),
                      if (item.retailUnitPrice != null)
                        _PriceTag(label: l10n.retailUnitPriceLabel, value: item.retailUnitPrice!, color: const Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Right: change count + last date ──────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeCount > 0 ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$changeCount ${l10n.priceChange}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: changeCount > 0 ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (lastEntry?.changedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(lastEntry!.changedAt!.toLocal()),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PriceTag({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(5)),
      child: Text(
        '$label: ₼${value.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Error / Empty ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(l10n.noHistory, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
