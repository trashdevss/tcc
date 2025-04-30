// lib/services/goal_service.dart

import 'package:firebase_auth/firebase_auth.dart'; // <<<--- GARANTA QUE ESTE IMPORT ESTÁ AQUI
import 'package:tcc_3/common/models/goal.dart';
import 'package:tcc_3/services/data_service/graphql_service.dart';

// Helper class interna para guardar as strings GraphQL
class _GoalGraphQL {
  // Campos que queremos buscar para uma meta
  static const String _goalFields = '''
    id
    user_id
    name
    target_amount
    current_amount
    created_at
  ''';

  // Subscription para ouvir as metas do usuário em tempo real
  static const String getGoalsSubscription = '''
    subscription GetUserGoals(\$userId: String!) {
      goals(where: {user_id: {_eq: \$userId}}, order_by: {created_at: desc}) {
        $_goalFields
      }
    }
  ''';

  // Mutation para adicionar uma nova meta (SEM declarar $userId na assinatura e SEM user_id no object)
  static const String addGoalMutation = '''
  mutation AddGoal(\$name: String!, \$targetAmount: numeric!) {
    insert_goals_one(object: {
        name: \$name,
        target_amount: \$targetAmount
        # current_amount: 0 // <<<--- REMOVER OU COMENTAR ESTA LINHA
        # user_id é definido pela permissão de linha (X-Hasura-User-Id)
        # createdAt será definido pelo default do banco
      }) {
      id # Retorna o ID da meta criada
    }
  }
''';


  // Mutation para adicionar progresso (usando _inc)
  static const String addProgressMutation = '''
    mutation AddProgress(\$goalId: uuid!, \$amountToAdd: numeric!) {
      update_goals_by_pk(pk_columns: {id: \$goalId}, _inc: {current_amount: \$amountToAdd}) {
        id
        current_amount
      }
    }
  ''';

   // Mutation para atualizar nome e valor alvo
   static const String updateGoalMutation = '''
     mutation UpdateGoal(\$goalId: uuid!, \$name: String!, \$targetAmount: numeric!) {
       update_goals_by_pk(pk_columns: {id: \$goalId}, _set: {name: \$name, target_amount: \$targetAmount}) {
         id
       }
     }
   ''';

  // Mutation para deletar uma meta
  static const String deleteGoalMutation = '''
    mutation DeleteGoal(\$goalId: uuid!) {
      delete_goals_by_pk(id: \$goalId) {
        id
      }
    }
  ''';
}


class GoalService {
  final GraphQLService _graphQLService; // Recebe a instância do serviço GraphQL

  // <<< --- IMPORTANTE: Lógica para obter o User ID --- >>>
  // Esta linha (agora ~linha 33/34 depois dos imports e _GoalGraphQL)
  // PRECISA que o import do FirebaseAuth esteja presente.
  // Substitua pela sua lógica real se for diferente.
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  // <<< --- FIM DA PARTE A SUBSTITUIR --- >>>

  // Construtor que recebe o GraphQLService
  GoalService({required GraphQLService graphQLService})
      : _graphQLService = graphQLService;

  // Retorna o Stream de Metas usando a Subscription do GraphQLService
  Stream<List<Goal>> getGoalsStream() {
    if (_userId == null) {
      print("GoalService: Usuário não logado, retornando stream vazio.");
      return Stream.value([]);
    }

    return _graphQLService.subscribe(
      document: _GoalGraphQL.getGoalsSubscription,
      variables: {'userId': _userId}, // Passa o userId como variável GraphQL
    ).map((data) {
      final List<dynamic>? goalsData = data['goals'] as List<dynamic>?;
      if (goalsData == null) return <Goal>[];
      return goalsData
          .map((goalJson) => Goal.fromJson(goalJson as Map<String, dynamic>))
          .toList();
    }).handleError((error) {
       print("Erro no Stream de Metas: $error");
       return <Goal>[];
    });
  }

  // Adiciona uma nova meta usando a Mutation corrigida
  Future<void> addGoal(String name, double targetAmount) async {
    // Usa _userId aqui APENAS para a checagem, não envia mais como variável para a mutation
    if (_userId == null) throw Exception("Usuário não logado para adicionar meta.");
    if (name.trim().isEmpty || targetAmount <= 0) throw Exception("Nome ou valor alvo inválido.");

    await _graphQLService.create(
      path: _GoalGraphQL.addGoalMutation,
      params: {
        // NÃO HÁ 'userId' aqui
        'name': name.trim(),
        'targetAmount': targetAmount,
      },
    );
  }

  // Adiciona progresso
  Future<void> addProgress(String goalId, double amountToAdd) async {
     if (_userId == null) throw Exception("Usuário não logado.");
     if (goalId.isEmpty || amountToAdd <= 0) throw Exception("ID da meta ou valor inválido.");

     await _graphQLService.update(
       path: _GoalGraphQL.addProgressMutation,
       params: {
         'goalId': goalId,
         'amountToAdd': amountToAdd,
       },
     );
  }

  // Deleta uma meta
  Future<void> deleteGoal(String goalId) async {
    if (_userId == null) throw Exception("Usuário não logado.");
    if (goalId.isEmpty) throw Exception("ID da meta inválido.");

    await _graphQLService.delete(
      path: _GoalGraphQL.deleteGoalMutation,
      params: {'goalId': goalId},
    );
  }

   // Atualiza uma meta
   Future<void> updateGoal(String goalId, String newName, double newTargetAmount) async {
     if (_userId == null) throw Exception("Usuário não logado.");
     if (goalId.isEmpty || newName.trim().isEmpty || newTargetAmount <= 0) {
        throw Exception("Dados inválidos para atualização.");
     }

     await _graphQLService.update(
       path: _GoalGraphQL.updateGoalMutation,
       params: {
         'goalId': goalId,
         'name': newName.trim(),
         'targetAmount': newTargetAmount,
       },
     );
   }
}