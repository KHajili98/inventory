import 'package:inventory/features/kassa/data/models/kassa_models.dart';

sealed class KassaState {
  const KassaState();
}

final class KassaInitial extends KassaState {
  const KassaInitial();
}

final class KassaLoading extends KassaState {
  const KassaLoading();
}

final class KassaLoaded extends KassaState {
  final KassaSessionSummary? activeSession;
  final List<Kassa> history;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final bool isActionLoading;

  const KassaLoaded({
    this.activeSession,
    required this.history,
    required this.totalCount,
    this.hasMore = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.isActionLoading = false,
  });

  bool get hasActiveSession => activeSession != null;

  KassaLoaded copyWith({
    KassaSessionSummary? activeSession,
    bool clearActiveSession = false,
    List<Kassa>? history,
    int? totalCount,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    bool? isActionLoading,
  }) => KassaLoaded(
    activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
    history: history ?? this.history,
    totalCount: totalCount ?? this.totalCount,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isActionLoading: isActionLoading ?? this.isActionLoading,
  );
}

final class KassaError extends KassaState {
  final String message;
  const KassaError(this.message);
}

final class KassaActionSuccess extends KassaState {
  final String message;
  const KassaActionSuccess(this.message);
}
