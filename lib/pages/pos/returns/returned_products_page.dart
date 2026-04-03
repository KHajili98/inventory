import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/returned_products/cubit/returned_products_cubit.dart';
import 'package:inventory/features/returned_products/cubit/returned_products_state.dart';
import 'package:inventory/features/returned_products/data/models/returned_product_models.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ── Entry widget ─────────────────────────────────────────────────────────────

class ReturnedProductsPage extends StatelessWidget {
  const ReturnedProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ReturnedProductsCubit(), child: const _ReturnedProductsView());
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _ReturnedProductsView extends StatefulWidget {
  const _ReturnedProductsView();

  @override
  State<_ReturnedProductsView> createState() => _ReturnedProductsViewState();
}

class _ReturnedProductsViewState extends State<_ReturnedProductsView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _receiptController = TextEditingController();
  Timer? _debounce;

  String _searchQuery = '';
  String _receiptNumber = '';
  bool? _isDefectedFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  void _fetch() {
    context.read<ReturnedProductsCubit>().fetchReturnedProducts(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      receiptNumber: _receiptNumber.isEmpty ? null : _receiptNumber,
      isDefected: _isDefectedFilter,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ReturnedProductsCubit>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value);
      _fetch();
    });
  }

  void _onReceiptChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _receiptNumber = value);
      _fetch();
    });
  }

  void _onDefectFilterChanged(bool? value) {
    setState(() => _isDefectedFilter = value);
    _fetch();
  }

  void _showDetailDialog(ReturnedProduct product) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: product.isDefected ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      product.isDefected ? Icons.warning_rounded : Icons.check_circle_rounded,
                      color: product.isDefected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.returnedProductDetails,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.isDefected ? l10n.defectedProduct : l10n.normalReturn,
                          style: TextStyle(
                            fontSize: 13,
                            color: product.isDefected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 24),
              _DetailRow(label: l10n.barcode, value: product.returnedProductBarcode),
              const SizedBox(height: 16),
              _DetailRow(label: l10n.productUUID, value: product.productUuid),
              const SizedBox(height: 16),
              _DetailRow(label: l10n.quantity, value: product.count.toString()),
              const SizedBox(height: 16),
              _DetailRow(label: l10n.receiptNumber, value: product.receiptNumber),
              const SizedBox(height: 16),
              _DetailRow(label: l10n.createdAt, value: DateFormat('dd.MM.yyyy HH:mm').format(product.createdAt.toLocal())),
              const SizedBox(height: 16),
              _DetailRow(label: l10n.updatedAt, value: DateFormat('dd.MM.yyyy HH:mm').format(product.updatedAt.toLocal())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(l10n.close, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(l10n),
          SizedBox(height: context.isMobile ? 16 : 20),
          _buildSummaryRow(l10n),
          SizedBox(height: context.isMobile ? 12 : 16),
          _buildFilters(l10n),
          SizedBox(height: context.isMobile ? 12 : 16),
          Expanded(child: _buildList(l10n)),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.returnedProducts,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(l10n.returnedProductsSubtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1)),
          onPressed: () => context.read<ReturnedProductsCubit>().refresh(),
          tooltip: l10n.refresh,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(AppLocalizations l10n) {
    return BlocBuilder<ReturnedProductsCubit, ReturnedProductsState>(
      builder: (context, state) {
        final totalCount = state is ReturnedProductsLoaded ? state.totalCount : 0;
        final defectedCount = state is ReturnedProductsLoaded ? state.products.where((p) => p.isDefected).length : 0;
        final normalCount = state is ReturnedProductsLoaded ? state.products.where((p) => !p.isDefected).length : 0;

        return context.isMobile
            ? Column(
                children: [
                  _SummaryCard(label: l10n.totalReturns, value: totalCount.toString(), color: const Color(0xFF6366F1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(label: l10n.defected, value: defectedCount.toString(), color: const Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(label: l10n.normal, value: normalCount.toString(), color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _SummaryCard(label: l10n.totalReturns, value: totalCount.toString(), color: const Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(label: l10n.defected, value: defectedCount.toString(), color: const Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(label: l10n.normal, value: normalCount.toString(), color: const Color(0xFF10B981)),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: context.isMobile ? double.infinity : 280,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        SizedBox(
          width: context.isMobile ? double.infinity : 220,
          child: TextField(
            controller: _receiptController,
            onChanged: _onReceiptChanged,
            decoration: InputDecoration(
              hintText: l10n.receiptNumber,
              prefixIcon: const Icon(Icons.receipt_rounded, color: Color(0xFF94A3B8), size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        Container(
          width: context.isMobile ? double.infinity : 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool?>(
              value: _isDefectedFilter,
              hint: Text(l10n.allProducts, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.allProducts)),
                DropdownMenuItem(value: true, child: Text(l10n.defectedOnly)),
                DropdownMenuItem(value: false, child: Text(l10n.normalOnly)),
              ],
              onChanged: _onDefectFilterChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    return BlocBuilder<ReturnedProductsCubit, ReturnedProductsState>(
      builder: (context, state) {
        return switch (state) {
          ReturnedProductsInitial() => const Center(child: Text('Initialize...')),
          ReturnedProductsLoading() => const Center(child: CircularProgressIndicator()),
          ReturnedProductsError(:final message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<ReturnedProductsCubit>().refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
          ReturnedProductsLoaded(:final products, :final isLoadingMore) =>
            products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(l10n.noReturnedProducts, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: products.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == products.length) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                        );
                      }
                      final product = products[index];
                      return _ProductCard(product: product, onTap: () => _showDetailDialog(product));
                    },
                  ),
        };
      },
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.archive_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ReturnedProduct product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: product.isDefected ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            product.isDefected ? Icons.warning_rounded : Icons.check_circle_rounded,
                            size: 14,
                            color: product.isDefected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.isDefected ? l10n.defected : l10n.normal,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.isDefected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(product.createdAt.toLocal()),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.barcode, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            product.returnedProductBarcode,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.quantity, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(
                          product.count.toString(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.receipt_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('${l10n.receiptNumber}: ${product.receiptNumber}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
