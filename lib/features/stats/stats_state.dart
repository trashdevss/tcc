// lib/features/stats/stats_state.dart

// Classe abstrata base para todos os estados
abstract class StatsState {}

// Estado inicial, antes de qualquer carregamento
class StatsStateInitial extends StatsState {}

// Estado indicando que os dados estão sendo carregados
class StatsStateLoading extends StatsState {}

// Estado indicando que os dados foram carregados com sucesso
class StatsStateSuccess extends StatsState {}

// Estado indicando que ocorreu um erro ao carregar os dados
class StatsStateError extends StatsState {
  final String message; // Mensagem de erro para exibir na UI

  StatsStateError(this.message);

  // Sobrescreve == e hashCode para permitir comparações e evitar rebuilds
  // desnecessários se a mensagem de erro for a mesma.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsStateError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}