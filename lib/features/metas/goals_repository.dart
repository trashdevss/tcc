// lib/features/metas/repositories/goals_repository.dart

import 'package:tcc_3/features/metas/goal_model.dart';

abstract class GoalsRepository {
  Future<List<GoalModel>> fetchGoals();

  // --- CORRIGIDO para retornar Future<GoalModel> ---
  Future<GoalModel> addGoal(GoalModel goal);

  // --- CORRIGIDO para retornar Future<GoalModel> ---
  Future<GoalModel> updateGoal(GoalModel goal);

  Future<void> deleteGoal(String goalId); // Este pode continuar void
}