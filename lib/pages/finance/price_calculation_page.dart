import 'package:flutter/material.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/pages/finance/calculation_detail_page.dart';
import 'package:inventory/pages/finance/edit_product_price_by_stock_page.dart';

// ── Model ────────────────────────────────────────────────────────────────────

enum PriceRequestStatus { pending, approved, rejected, onReview }

class PriceRequest {
  final String name;
  final String source;
  final String user;
  final String createdAt;
  final PriceRequestStatus status;

  const PriceRequest({required this.name, required this.source, required this.user, required this.createdAt, required this.status});
}

// ── Mock data ────────────────────────────────────────────────────────────────

const List<PriceRequest> _mockRequests = [
  PriceRequest(
    name: 'Birinci request',
    source: 'Sederek magaza',
    user: 'Kamran Hacili',
    createdAt: '22.10.2025 10:30',
    status: PriceRequestStatus.onReview,
  ),
  PriceRequest(
    name: 'İkinci request',
    source: 'Bakı mərkəz mağaza',
    user: 'Aytən Memmedli',
    createdAt: '23.10.2025 09:15',
    status: PriceRequestStatus.approved,
  ),
  PriceRequest(
    name: 'Üçüncü request',
    source: 'Gəncə filialı',
    user: 'Rauf Hacili',
    createdAt: '24.10.2025 14:45',
    status: PriceRequestStatus.pending,
  ),
  PriceRequest(
    name: 'Dördüncü request',
    source: 'Sumqayıt mağaza',
    user: 'Nigar Memmedli',
    createdAt: '25.10.2025 11:00',
    status: PriceRequestStatus.rejected,
  ),
  PriceRequest(
    name: 'Beşinci request',
    source: 'Sederek magaza',
    user: 'Elvin Memmedli',
    createdAt: '26.10.2025 16:20',
    status: PriceRequestStatus.onReview,
  ),
  PriceRequest(
    name: 'Altıncı request',
    source: 'Bakı mərkəz mağaza',
    user: 'Kamran Hacili',
    createdAt: '27.10.2025 08:50',
    status: PriceRequestStatus.approved,
  ),
  PriceRequest(
    name: 'Yeddinci request',
    source: 'Lənkəran filialı',
    user: 'Sevinc Memmedli',
    createdAt: '28.10.2025 13:10',
    status: PriceRequestStatus.pending,
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class PriceCalculationPage extends StatefulWidget {
  const PriceCalculationPage({super.key});

  @override
  State<PriceCalculationPage> createState() => _PriceCalculationPageState();
}

class _PriceCalculationPageState extends State<PriceCalculationPage> {
  String _searchQuery = '';

  List<PriceRequest> get _filtered => _mockRequests.where((r) {
    final q = _searchQuery.toLowerCase();
    return r.name.toLowerCase().contains(q) || r.source.toLowerCase().contains(q) || r.user.toLowerCase().contains(q);
  }).toList();

  // ── Status helpers ───────────────────────────────────────────────────────

  Color _statusBg(PriceRequestStatus s) {
    switch (s) {
      case PriceRequestStatus.approved:
        return const Color(0xFFDCFCE7);
      case PriceRequestStatus.rejected:
        return const Color(0xFFFFE4E6);
      case PriceRequestStatus.onReview:
        return const Color(0xFFFEF9C3);
      case PriceRequestStatus.pending:
        return const Color(0xFFE0E7FF);
    }
  }

  Color _statusFg(PriceRequestStatus s) {
    switch (s) {
      case PriceRequestStatus.approved:
        return const Color(0xFF16A34A);
      case PriceRequestStatus.rejected:
        return const Color(0xFFDC2626);
      case PriceRequestStatus.onReview:
        return const Color(0xFFCA8A04);
      case PriceRequestStatus.pending:
        return const Color(0xFF4F46E5);
    }
  }

  String _statusLabel(PriceRequestStatus s) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case PriceRequestStatus.approved:
        return l10n.approvedStatus;
      case PriceRequestStatus.rejected:
        return l10n.rejectedStatus;
      case PriceRequestStatus.onReview:
        return l10n.onReviewStatus;
      case PriceRequestStatus.pending:
        return l10n.pendingStatus;
    }
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  Widget _buildStatCard({required String label, required int count, required Color color, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
                ),
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final l10n = AppLocalizations.of(context)!;
    final total = _mockRequests.length;
    final approved = _mockRequests.where((r) => r.status == PriceRequestStatus.approved).length;
    final onReview = _mockRequests.where((r) => r.status == PriceRequestStatus.onReview).length;
    final rejected = _mockRequests.where((r) => r.status == PriceRequestStatus.rejected).length;

    final isMobile = context.isMobile;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildStatCard(label: l10n.totalRequests, count: total, color: const Color(0xFF6366F1), icon: Icons.receipt_long_outlined),
              const SizedBox(width: 10),
              _buildStatCard(label: l10n.approvedStatus, count: approved, color: const Color(0xFF16A34A), icon: Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(label: l10n.onReviewStatus, count: onReview, color: const Color(0xFFCA8A04), icon: Icons.hourglass_top_outlined),
              const SizedBox(width: 10),
              _buildStatCard(label: l10n.rejectedStatus, count: rejected, color: const Color(0xFFDC2626), icon: Icons.cancel_outlined),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildStatCard(label: l10n.totalRequests, count: total, color: const Color(0xFF6366F1), icon: Icons.receipt_long_outlined),
        const SizedBox(width: 12),
        _buildStatCard(label: l10n.approvedStatus, count: approved, color: const Color(0xFF16A34A), icon: Icons.check_circle_outline),
        const SizedBox(width: 12),
        _buildStatCard(label: l10n.onReviewStatus, count: onReview, color: const Color(0xFFCA8A04), icon: Icons.hourglass_top_outlined),
        const SizedBox(width: 12),
        _buildStatCard(label: l10n.rejectedStatus, count: rejected, color: const Color(0xFFDC2626), icon: Icons.cancel_outlined),
      ],
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────

  Widget _buildTable() {
    final l10n = AppLocalizations.of(context)!;
    final rows = _filtered;
    final isMobile = context.isMobile;

    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(l10n.noResultsFound, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      );
    }

    if (isMobile) {
      return ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CalculationDetailPage(request: rows[i]))),
          child: _buildMobileCard(rows[i]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n.requestName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n.sourceColumn,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n.userColumn,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n.creationDate,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n.statusColumn,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // ── Rows ────────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CalculationDetailPage(request: r))),
                    child: Container(
                      color: i.isEven ? Colors.white : const Color(0xFFFAFAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.description_outlined, size: 15, color: Color(0xFF6366F1)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              r.source,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFF6366F1),
                                  child: Text(
                                    r.user.isNotEmpty ? r.user[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r.user,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(r.createdAt, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(alignment: Alignment.centerLeft, child: _statusBadge(r.status)),
                          ),
                        ],
                      ),
                    ),
                  ); // InkWell
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard(PriceRequest r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                ),
              ),
              _statusBadge(r.status),
            ],
          ),
          const SizedBox(height: 10),
          _cardRow(Icons.store_outlined, r.source),
          const SizedBox(height: 6),
          _cardRow(Icons.person_outline, r.user),
          const SizedBox(height: 6),
          _cardRow(Icons.calendar_today_outlined, r.createdAt),
        ],
      ),
    );
  }

  Widget _cardRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _statusBadge(PriceRequestStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _statusBg(s), borderRadius: BorderRadius.circular(20)),
      child: Text(
        _statusLabel(s),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusFg(s)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    return Padding(
      padding: context.responsiveHorizontalPadding.add(EdgeInsets.symmetric(vertical: context.responsivePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.priceCalculation,
                    style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.priceRequestsSubtitle,
                    style: TextStyle(fontSize: isMobile ? 12 : 13, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProductPriceByStockPage())),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.adjustPrices),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 12),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // ── Stats ────────────────────────────────────────────────────────
          _buildStatsRow(),
          SizedBox(height: isMobile ? 16 : 20),

          // ── Search ───────────────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: l10n.searchPlaceholder,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 14 : 18),

          // ── Table ────────────────────────────────────────────────────────
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }
}
