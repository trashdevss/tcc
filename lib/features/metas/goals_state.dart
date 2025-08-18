// lib/features/metas/goals_state.dart

import 'package:tcc_3/features/metas/goal_model.dart';

// Estado base abstrato
abstract class GoalsState {}

// Estado inicial
class GoalsStateInitial extends GoalsState {}

// Estado enquanto carrega a lista de metas
class GoalsStateLoading extends GoalsState {}

// Estado de sucesso ao carregar as metas
class GoalsStateSuccess extends GoalsState {
  final List<GoalModel> goals;
  GoalsStateSuccess({required this.goals});
}

// Estado em caso de erro ao carregar as metas
class GoalsStateError extends GoalsState {
  final String message;
  GoalsStateError({required this.message});
}

// Você pode adicionar outros estados depois, por exemplo:
// class GoalSaving extends GoalsState {}
// class GoalSavedSuccess extends GoalsState {}
// class GoalDeleteError extends GoalsState { ... }