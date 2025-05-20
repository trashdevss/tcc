import 'exceptions.dart'; // Presumo que este arquivo define sua classe 'Failure'

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

  // --- MODIFICAÇÃO AQUI ---
  // Agora 'isSuccess' retorna true se for um _SuccessResult, e false se for um _FailureResult.
  bool get isSuccess => fold<bool>(
        (error) => false, // Se for falha, isSuccess é false
        (data) => true,   // Se for sucesso, isSuccess é true
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

  // Não é mais necessário sobrescrever 'isSuccess' aqui se a classe base já o define corretamente.

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

  // Não é mais necessário sobrescrever 'isSuccess' aqui.

  @override
  T fold<T>(
    T Function(Failure error) fnFailure,
    T Function(S data) fnData,
  ) {
    return fnFailure(_value);
  }
}