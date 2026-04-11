import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory/features/kassa/cubit/kassa_status_cubit.dart';

/// Wraps [child] and checks kassa status on mount.
/// - If kassa is **open** → shows [child] normally.
/// - If kassa is **closed** (or error) → blurs [child] and overlays a prompt
///   that routes to `/kassa` when tapped.
class KassaStatusGuard extends StatelessWidget {
  const KassaStatusGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KassaStatusCubit()..checkStatus(),
      child: _KassaGuardView(child: child),
    );
  }
}

class _KassaGuardView extends StatelessWidget {
  const _KassaGuardView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KassaStatusCubit, KassaStatusState>(
      builder: (context, state) {
        final isOpen = state is KassaStatusOpen;
        final isLoading = state is KassaStatusLoading || state is KassaStatusInitial;

        return Stack(
          children: [
            // ── Actual POS content ──────────────────────────────────────────
            child,

            // ── Overlay when kassa is closed or still loading ───────────────
            if (!isOpen) Positioned.fill(child: _KassaClosedOverlay(isLoading: isLoading)),
          ],
        );
      },
    );
  }
}

class _KassaClosedOverlay extends StatelessWidget {
  const _KassaClosedOverlay({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: Center(child: isLoading ? const CircularProgressIndicator(color: Colors.white) : _ClosedCard()),
        ),
      ),
    );
  }
}

class _ClosedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 32, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), shape: BoxShape.circle),
            child: const Icon(Icons.lock_clock_rounded, size: 38, color: Color(0xFFF57C00)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kassa bağlıdır',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Satış əməliyyatları aparmaq üçün əvvəlcə kassanı açmalısınız.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // Close all open dialogs first
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Then navigate to kassa page
                context.go('/kassa');
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              label: const Text('Kassanı Aç', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
