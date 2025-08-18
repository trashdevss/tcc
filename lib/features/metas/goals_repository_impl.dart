import 'package:graphql_flutter/graphql_flutter.dart'; // Ou seu cliente GraphQL
import 'package:tcc_3/features/metas/goal_model.dart';
import 'package:tcc_3/features/metas/goals_repository.dart';
import 'package:tcc_3/locator.dart'; // Se você usa get_it para o client

// !!! IMPORTANTE: Adapte este arquivo !!!
// 1. Substitua as strings GraphQL (_fetchGoalsQuery, _addGoalMutation, etc.) pelas suas.
// 2. Verifique se os NOMES DOS CAMPOS ('id', 'name', 'target_amount', etc.) batem com seu schema Hasura.
// 3. Ajuste a forma como o _client é obtido e usado, se não for graphql_flutter.

class GoalsRepositoryImpl implements GoalsRepository {
  // Assumindo que você tem um GraphQLClient injetado via get_it ou similar
  // Se não, instancie ou obtenha seu cliente GraphQL aqui.
  final GraphQLClient _client; // = locator.get<GraphQLClient>(); <-- Exemplo com get_it

  GoalsRepositoryImpl({required GraphQLClient client}) : _client = client;


  // --- ADAPTE ESTA QUERY ---
  final String _fetchGoalsQuery = """
    query FetchGoals {
      goals(order_by: {created_at: desc}) {
        id
        name
        target_amount
        current_amount
        created_at
      }
    }
  """;

  @override
  Future<List<GoalModel>> fetchGoals() async {
    try {
      final options = QueryOptions(document: gql(_fetchGoalsQuery));
      final result = await _client.query(options);

      if (result.hasException) {
        print("GraphQL Exception (fetchGoals): ${result.exception.toString()}");
        throw Exception('Erro ao buscar metas: ${result.exception}');
      }

      // Adapte 'goals' se o nome da sua query/tabela for diferente
      final List<dynamic>? goalsData = result.data?['goals'];

      if (goalsData == null) {
        print("WARN: Nenhum dado retornado para 'goals' em fetchGoals.");
        return []; // Retorna lista vazia se não houver dados
      }

      // Converte a lista de Map (JSON) para lista de GoalModel
      return goalsData
          .map((json) => GoalModel.fromJson(json as Map<String, dynamic>))
          .toList();

    } catch (e) {
      print("REPO ERROR (fetchGoals): $e");
      throw Exception('Erro inesperado ao buscar metas: $e');
    }
  }

  // --- ADAPTE ESTA MUTAÇÃO ---
  // Assume que Hasura gera o ID. Retorna o objeto criado.
  final String _addGoalMutation = """
    mutation AddGoal(\$name: String!, \$target_amount: numeric!, \$current_amount: numeric!) {
      insert_goals_one(object: {name: \$name, target_amount: \$target_amount, current_amount: \$current_amount}) {
        id
        name
        target_amount
        current_amount
        created_at
      }
    }
  """;

  @override
  Future<GoalModel> addGoal(GoalModel goalToAdd) async {
    try {
       final options = MutationOptions(
        document: gql(_addGoalMutation),
        variables: {
          'name': goalToAdd.name,
          'target_amount': goalToAdd.targetAmount,
          'current_amount': goalToAdd.currentAmount,
          // Não envia 'id' aqui, assume que Hasura gera
          // Não envia 'created_at' aqui, assume que Hasura gera
        },
      );

      final result = await _client.mutate(options);

      if (result.hasException) {
        print("GraphQL Exception (addGoal): ${result.exception.toString()}");
        // Log específico para erro de ID nulo, se aplicável
        if (result.exception.toString().contains("Null value resolved for non-null field 'id'")) {
           print("ALERTA HASURA: A mutação AddGoal não está retornando o campo 'id'. Verifique a definição da mutação e as permissões no Hasura!");
        }
        throw Exception('Erro ao adicionar meta: ${result.exception}');
      }

      // Adapte 'insert_goals_one' se o nome da sua mutação for diferente
      final Map<String, dynamic>? goalData = result.data?['insert_goals_one'];

      if (goalData == null) {
        print("ERRO: Nenhum dado retornado por 'insert_goals_one' em addGoal.");
        // Isso pode acontecer se a mutação não retornar dados ou se o nome estiver errado.
        // O log I/flutter anterior ("WARN GraphQL addGoal: Mutação completou, mas não retornou ID.")
        // sugere que este era o problema. Verifique sua mutação no Hasura!
         throw Exception('Falha ao adicionar meta: Resposta do servidor vazia ou inválida.');
      }

       print("REPO: Meta '${goalData['name']}' adicionada via Hasura com ID ${goalData['id']}."); // Log de sucesso
      // Converte o Map (JSON) retornado para GoalModel
      return GoalModel.fromJson(goalData);

    } catch (e) {
       print("REPO ERROR (addGoal): $e");
      // Relança a exceção para o Controller tratar
      throw Exception('Erro inesperado ao adicionar meta: $e');
    }
  }

 // --- ADAPTE ESTA MUTAÇÃO ---
  // Atualiza por ID (pk), retorna o objeto atualizado.
  final String _updateGoalMutation = """
    mutation UpdateGoal(\$id: uuid!, \$_set: goals_set_input!) {
      update_goals_by_pk(pk_columns: {id: \$id}, _set: \$_set) {
        id
        name
        target_amount
        current_amount
        created_at
      }
    }
  """;
  // NOTA: O tipo do ID (\$id: uuid!) e o input (_set: goals_set_input!)
  // dependem EXATAMENTE do seu schema Hasura. Ajuste conforme necessário.

  @override
  Future<GoalModel> updateGoal(GoalModel goalToUpdate) async {
     try {
      final options = MutationOptions(
        document: gql(_updateGoalMutation),
        variables: {
          'id': goalToUpdate.id, // ID da meta a atualizar
          '_set': { // Objeto com os campos a serem atualizados
            'name': goalToUpdate.name,
            'target_amount': goalToUpdate.targetAmount,
            'current_amount': goalToUpdate.currentAmount,
            // Não atualiza created_at geralmente
          }
        },
      );

      final result = await _client.mutate(options);

       if (result.hasException) {
        print("GraphQL Exception (updateGoal): ${result.exception.toString()}");
        throw Exception('Erro ao atualizar meta: ${result.exception}');
      }

      // Adapte 'update_goals_by_pk' se o nome da sua mutação for diferente
      final Map<String, dynamic>? goalData = result.data?['update_goals_by_pk'];

       if (goalData == null) {
         print("ERRO: Nenhum dado retornado por 'update_goals_by_pk' em updateGoal.");
         throw Exception('Falha ao atualizar meta: Resposta do servidor vazia ou inválida.');
      }

      print("REPO: Meta ID ${goalData['id']} atualizada via Hasura.");
      return GoalModel.fromJson(goalData);

    } catch (e) {
      print("REPO ERROR (updateGoal): $e");
      throw Exception('Erro inesperado ao atualizar meta: $e');
    }
  }

  // --- ADAPTE ESTA MUTAÇÃO ---
  final String _deleteGoalMutation = """
    mutation DeleteGoal(\$id: uuid!) {
      delete_goals_by_pk(id: \$id) {
        id # Retorna o ID do item deletado para confirmação
      }
    }
  """;

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      final options = MutationOptions(
        document: gql(_deleteGoalMutation),
        variables: {'id': goalId},
      );

      final result = await _client.mutate(options);

      if (result.hasException) {
        print("GraphQL Exception (deleteGoal): ${result.exception.toString()}");
        throw Exception('Erro ao deletar meta: ${result.exception}');
      }

      // Verifica se a resposta contém o esperado (opcional, mas bom)
      final deletedId = result.data?['delete_goals_by_pk']?['id'];
      if (deletedId == null || deletedId != goalId) {
         print("WARN: A deleção da meta ID $goalId pode não ter sido confirmada pela resposta.");
      } else {
        print("REPO: Meta ID $goalId deletada via Hasura.");
      }
      // Não retorna nada em caso de sucesso

    } catch (e) {
       print("REPO ERROR (deleteGoal): $e");
      throw Exception('Erro inesperado ao deletar meta: $e');
    }
  }
}