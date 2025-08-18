
abstract class StatsState {}

class StatsStateInitial extends StatsState {}

class StatsStateLoading extends StatsState {}

class StatsStateSuccess extends StatsState {}

class StatsStateError extends StatsState {
  final String message; // <-- Adicionar esta linha
  StatsStateError({required this.message}); // <-- Adicionar construtor

  // Se usar Equatable ou similar, adicione 'message' às props
  // @override List<Object?> get props => [message];
}
