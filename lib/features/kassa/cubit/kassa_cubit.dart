import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/kassa/cubit/kassa_state.dart';
import 'package:inventory/features/kassa/data/models/kassa_models.dart';
import 'package:inventory/features/kassa/data/repositories/kassa_repository.dart';

class KassaCubit extends Cubit<KassaState> {
  KassaCubit({KassaRepository? repository}) : _repository = repository ?? KassaRepository.instance, super(const KassaInitial());

  final KassaRepository _repository;

  /// Loads the active session summary + history list simultaneously.
  Future<void> loadPage() async {
    emit(const KassaLoading());

    final sessionResult = await _repository.fetchCurrentSessionSummary();
    final historyResult = await _repository.fetchKassaList(page: 1);

    KassaSessionSummary? session;
    if (sessionResult case Success(:final data)) {
      session = data;
    }

    switch (historyResult) {
      case Success(:final data):
        emit(KassaLoaded(activeSession: session, history: data.results, totalCount: data.count, hasMore: data.next != null, currentPage: 1));
      case Failure(:final message):
        emit(KassaLoaded(activeSession: session, history: const [], totalCount: 0));
        // Emit error then go back to loaded so UI can still show session
        emit(KassaError(message));
        if (session != null) {
          emit(KassaLoaded(activeSession: session, history: const [], totalCount: 0));
        }
    }
  }

  /// Load more history pages.
  Future<void> loadMore() async {
    final current = state;
    if (current is! KassaLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.currentPage + 1;
    final result = await _repository.fetchKassaList(page: nextPage);

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            history: [...current.history, ...data.results],
            totalCount: data.count,
            hasMore: data.next != null,
            currentPage: nextPage,
            isLoadingMore: false,
          ),
        );
      case Failure(:final message):
        emit(current.copyWith(isLoadingMore: false));
        emit(KassaError(message));
        emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Open a new kassa session.
  Future<void> openKassa({required double cashAmount, required double cardAmount, required DateTime date}) async {
    final current = state;
    if (current is KassaLoaded) {
      emit(current.copyWith(isActionLoading: true));
    }

    final result = await _repository.openKassa(openedCashAmount: cashAmount, openedCardAmount: cardAmount, openedDate: date);

    switch (result) {
      case Success():
        await loadPage();
      case Failure(:final message):
        if (current is KassaLoaded) {
          emit(current.copyWith(isActionLoading: false));
        }
        emit(KassaError(message));
        if (current is KassaLoaded) {
          emit(current.copyWith(isActionLoading: false));
        }
    }
  }

  /// Close the current kassa session.
  Future<void> closeKassa({
    required double closedCashAmount,
    required double closedCardAmount,
    required DateTime closedDate,
    double cuttedCashAmount = 0,
    double cuttedCardAmount = 0,
    String? cuttedAmountDescription,
  }) async {
    final current = state;
    if (current is KassaLoaded) {
      emit(current.copyWith(isActionLoading: true));
    }

    final result = await _repository.closeKassa(
      closedCashAmount: closedCashAmount,
      closedCardAmount: closedCardAmount,
      closedDate: closedDate,
      cuttedCashAmount: cuttedCashAmount,
      cuttedCardAmount: cuttedCardAmount,
      cuttedAmountDescription: cuttedAmountDescription,
    );

    switch (result) {
      case Success():
        await loadPage();
      case Failure(:final message):
        if (current is KassaLoaded) {
          emit(current.copyWith(isActionLoading: false));
        }
        emit(KassaError(message));
        if (current is KassaLoaded) {
          emit(current.copyWith(isActionLoading: false));
        }
    }
  }

  /// Refresh both session and history.
  Future<void> refresh() => loadPage();

  Future<ApiResult<Kassa>> fetchKassaDetail(String id) => _repository.fetchKassaDetail(id);
}
