import 'package:flutter/foundation.dart';
import 'package:tcc_3/features/metas/goal_model.dart';
import 'package:tcc_3/features/metas/goals_repository.dart';
import 'package:tcc_3/features/metas/goals_state.dart';

class GoalsController extends ChangeNotifier {
  final GoalsRepository _repository;

  GoalsController({required GoalsRepository repository}) : _repository = repository;

  GoalsState _state = GoalsStateInitial();
  GoalsState get state => _state;

  List<GoalModel> _goals = [];
  // Boa prática: Expor uma cópia imutável da lista.
  List<GoalModel> get goals => List.unmodifiable(_goals);

  /// Busca inicial ou para recarregar TUDO manualmente (ex: pull-to-refresh).
  Future<void> fetchGoals() async {
    _state = GoalsStateLoading();
    notifyListeners(); // Notifica a UI que está carregando
    try {
      final fetchedGoals = await _repository.fetchGoals();
      _goals = fetchedGoals;
      _state = GoalsStateSuccess(goals: _goals);
      notifyListeners(); // Notifica a UI com os dados ou lista vazia
    } catch (e) {
      print("CONTROLLER ERROR (fetchGoals): $e");
      _state = GoalsStateError(message: "Erro ao buscar metas: ${e.toString()}");
      notifyListeners(); // Notifica a UI sobre o erro
    }
  }

  /// Adiciona uma meta, atualizando o estado localmente SEM refazer o fetch.
  Future<void> addGoal(GoalModel goalDataFromPage) async {
    // Opcional: estado de Saving para feedback na UI
    // _state = GoalsStateSaving();
    // notifyListeners();

    try {
      // Chama o repositório, que DEVE retornar a meta com ID do backend.
      final GoalModel newGoalFromBackend = await _repository.addGoal(goalDataFromPage);

      // Adiciona à lista local.
      _goals.add(newGoalFromBackend);
       // Opcional: Ordenar a lista se necessário (ex: por data de criação)
       // _goals.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(0)) ?? 0);

      // Atualiza o estado e notifica a UI.
      _state = GoalsStateSuccess(goals: _goals);
      notifyListeners();

    } catch (e) {
      print("CONTROLLER ERROR (addGoal): $e");
      // Define estado de erro E notifica a UI.
      _state = GoalsStateError(message: "Erro ao adicionar meta: ${e.toString()}");
      notifyListeners();
      // Re-lança para a Page poder mostrar SnackBar, etc.
      throw Exception("Erro ao adicionar meta: ${e.toString()}");
    }
  }

  /// Atualiza uma meta, atualizando o estado localmente SEM refazer o fetch.
  Future<void> updateGoal(GoalModel updatedGoal) async {
    // Opcional: estado de Saving
    // _state = GoalsStateSaving();
    // notifyListeners();
    try {
      // Chama o repositório, que DEVE retornar a meta atualizada.
      final GoalModel confirmedUpdate = await _repository.updateGoal(updatedGoal);

      // Encontra o índice na lista local.
      final index = _goals.indexWhere((goal) => goal.id == confirmedUpdate.id);

      if (index != -1) {
        // Substitui na lista local.
        _goals[index] = confirmedUpdate;
        // Opcional: Reordenar a lista se a atualização puder afetar a ordem.
        // _goals.sort(...);

        // Atualiza o estado e notifica a UI.
        _state = GoalsStateSuccess(goals: _goals);
        notifyListeners();
      } else {
        // Se não encontrou, algo está estranho. Loga e faz fallback (fetch all).
        print("CONTROLLER WARN (updateGoal): Meta atualizada (ID: ${confirmedUpdate.id}) não encontrada na lista local. Recarregando tudo como fallback.");
        // Retorna ao comportamento antigo SÓ NESTE CASO DE ERRO.
        await fetchGoals();
      }
    } catch (e) {
      print("CONTROLLER ERROR (updateGoal): $e");
      _state = GoalsStateError(message: "Erro ao atualizar meta: ${e.toString()}");
      notifyListeners();
      throw Exception("Erro ao atualizar meta: ${e.toString()}");
    }
  }

  /// Deleta uma meta, atualizando o estado localmente SEM refazer o fetch.
 // lib/features/metas/goals_controller.dart

  // --- MÉTODO deleteGoal CORRIGIDO ---
  Future<void> deleteGoal(String goalId) async {
     // Opcional: estado de Deleting
    // _state = GoalsStateDeleting();
    // notifyListeners();
    try {
      // PASSO 1: Chamar o repositório para deletar no backend.
      //          Não precisamos do resultado aqui, pois ele retorna void.
      await _repository.deleteGoal(goalId);

      // PASSO 2: Obter o tamanho da lista ANTES de remover (opcional, para log)
      // final int countBefore = _goals.length;

      // PASSO 3: Remover da lista local.
      _goals.removeWhere((goal) => goal.id == goalId);

      // PASSO 4: Obter o tamanho da lista DEPOIS de remover (opcional, para log)
      // final int countAfter = _goals.length;

      // PASSO 5: Atualizar estado e notificar UI.
      //         Só atualizamos se a lista realmente mudou (opcional)
      // if (countAfter < countBefore) {
          _state = GoalsStateSuccess(goals: _goals);
          notifyListeners();
          print("CONTROLLER: Meta ID $goalId removida localmente.");
      // } else {
      //    print("CONTROLLER WARN (deleteGoal): Meta com ID $goalId não encontrada na lista local para remoção.");
      // }

    } catch (e) {
      print("CONTROLLER ERROR (deleteGoal): $e");
      _state = GoalsStateError(message: "Erro ao deletar meta: ${e.toString()}");
      notifyListeners();
      throw Exception("Erro ao deletar meta: ${e.toString()}");
    }
  }
}