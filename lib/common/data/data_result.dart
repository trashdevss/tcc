// No seu arquivo data_result.dart
import 'exceptions.dart'; // Seu arquivo de exceptions

abstract class DataResult<S> {
  const DataResult();

  static DataResult<S> failure<S>(Failure failure) => _FailureResult(failure);
  static DataResult<S> success<S>(S data) => _SuccessResult(data);

  Failure? get error => fold<Failure?>(
        (error) => error,
        (data) => null,
      );

  S? get data => fold<S?>(
        (error) => null,
        (data) => data,
      );

  // --- MODIFICAÇÃO APLICADA AQUI ---
  bool get isSuccess => fold<bool>(
        (failure) => false, // Se é falha, isSuccess é false
        (data) => true,   // Se é sucesso, isSuccess é true
      );
  // --- FIM DA MODIFICAÇÃO ---

  T fold<T>(
    T Function(Failure error) fnFailure,
    T Function(S data) fnData,
  );
}

class _SuccessResult<S> extends DataResult<S> {
  const _SuccessResult(this._value);
  final S _value;

  @override
  T fold<T>(
    T Function(Failure error) fnFailure,
    T Function(S data) fnData,
  ) {
    return fnData(_value);
  }
}

class _FailureResult<S> extends DataResult<S> {
  const _FailureResult(this._value);
  final Failure _value;

  @override
  T fold<T>(
    T Function(Failure error) fnFailure,
    T Function(S data) fnData,
  ) {
    return fnFailure(_value);
  }
}