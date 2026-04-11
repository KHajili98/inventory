import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/kassa/data/repositories/kassa_repository.dart';

// ── States ─────────────────────────────────────────────────────────────────────

sealed class KassaStatusState {
  const KassaStatusState();
}

final class KassaStatusInitial extends KassaStatusState {
  const KassaStatusInitial();
}

final class KassaStatusLoading extends KassaStatusState {
  const KassaStatusLoading();
}

final class KassaStatusOpen extends KassaStatusState {
  const KassaStatusOpen();
}

final class KassaStatusClosed extends KassaStatusState {
  const KassaStatusClosed();
}

final class KassaStatusError extends KassaStatusState {
  final String message;
  const KassaStatusError(this.message);
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class KassaStatusCubit extends Cubit<KassaStatusState> {
  KassaStatusCubit({KassaRepository? repository}) : _repository = repository ?? KassaRepository.instance, super(const KassaStatusInitial());

  final KassaRepository _repository;

  Future<void> checkStatus() async {
    emit(const KassaStatusLoading());

    final result = await _repository.fetchKassaStatus();

    switch (result) {
      case Success(:final data):
        if (data == 'opened') {
          emit(const KassaStatusOpen());
        } else {
          emit(const KassaStatusClosed());
        }
      case Failure(:final message):
        // Treat fetch failure as closed so the user is prompted to open kassa
        emit(KassaStatusError(message));
    }
  }
}
