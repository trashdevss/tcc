// lib/services/graphql_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:tcc_3/services/auth_service/auth_service.dart';
import 'package:tcc_3/services/data_service/data_service.dart';

// Ajuste os caminhos de importação conforme sua estrutura
import '../../common/data/exceptions.dart'; // Suas Exceptions personalizadas

class GraphQLService implements DataService<Map<String, dynamic>> {
  GraphQLService({
    required this.authService,
  });

  final AuthService authService;

  late GraphQLClient _client;
  GraphQLClient get client => _client;

  Future<GraphQLService> init() async {
    print('[GraphQLService] Initializing...');
    final HttpLink httpLink = HttpLink(
      'https://tight-monarch-58.hasura.app/v1/graphql',
    );

    // ==================================================
    // <<<--- AuthLink COM LOGS DETALHADOS --- >>>
    // ==================================================
    final AuthLink authLink = AuthLink(
      // Função que busca o token ANTES de cada requisição HTTP
      getToken: () async {
        print('[AuthLink] getToken() chamado para requisição HTTP...'); // Log: Quando é chamado
        try {
           // Chama seu serviço que busca o token atual do usuário
           final result = await authService.userToken();
           // Adapte 'result.data' se a estrutura do seu resultado for diferente
           final token = result.data;

           // Verifica se o token veio nulo ou vazio
           if (token == null || token.isEmpty) {
             print('[AuthLink] ERRO: Token retornado pelo authService é NULO ou VAZIO!');
             return null; // Retorna null -> Nenhum header 'Authorization' será enviado
           }

           // Log de segurança: mostra o tamanho e SÓ O COMEÇO do token
           final String partialToken = token.length > 20 ? token.substring(0, 20) : token;
           print('[AuthLink] Token obtido com sucesso (length: ${token.length}, startsWith: $partialToken...)');

           // Retorna o cabeçalho completo no formato esperado "Bearer SEU_TOKEN"
           return 'Bearer $token';

        } catch (e) {
           // Loga qualquer erro que ocorrer ao TENTAR buscar o token
           print('[AuthLink] EXCEÇÃO ao buscar token: $e');
           return null; // Retorna null em caso de erro -> Nenhum header será enviado
        }
      },
    );
    // ==================================================

     // Link WebSocket para Subscriptions
     final WebSocketLink webSocketLink = WebSocketLink(
       'wss://tight-monarch-58.hasura.app/v1/graphql', // URL WSS
       config: SocketClientConfig(
         autoReconnect: true,
         inactivityTimeout: const Duration(seconds: 30),
         initialPayload: () async {
            // Lógica para enviar token na conexão inicial do WebSocket
            try {
               final result = await authService.userToken();
               final token = result.data; // Adapte se necessário
                print('[WebSocketLink] Payload token obtained (length: ${token?.length ?? 0}).');
               return token == null ? {} : {
                 'headers': {'Authorization': 'Bearer $token'},
               };
            } catch (e) {
              print('[WebSocketLink] Error getting token for payload: $e');
              return {};
            }
         },
       ),
     );

    // Divide o link: WebSocket para subscriptions, HTTP+Auth para o resto
    final Link link = Link.split(
      (request) => request.isSubscription,
      webSocketLink,
      authLink.concat(httpLink), // Concatena AuthLink com HttpLink para queries/mutations
    );

    // Cria o cliente GraphQL
    _client = GraphQLClient(
      link: link,
      // Policies padrão corrigidas
      defaultPolicies: DefaultPolicies(
        watchQuery: Policies(fetch: FetchPolicy.cacheAndNetwork, error: ErrorPolicy.all),
        query: Policies(fetch: FetchPolicy.cacheFirst, error: ErrorPolicy.all),
        mutate: Policies(fetch: FetchPolicy.networkOnly, error: ErrorPolicy.all),
        subscribe: Policies(fetch: FetchPolicy.networkOnly, error: ErrorPolicy.all),
      ),
      cache: GraphQLCache(store: InMemoryStore()),
    );

    print('[GraphQLService] Initialized successfully.');
    return this;
  }

  // Método para Subscriptions
   Stream<Map<String, dynamic>> subscribe({ required String document, Map<String, dynamic> variables = const {}, String? operationName,}) {
     print("[GraphQLService] Attempting: SUBSCRIBE ${operationName ?? ''}");
     final options = SubscriptionOptions(document: gql(document), variables: variables, operationName: operationName);
     Stream<QueryResult> streamResult = _client.subscribe(options);
     return streamResult.map((result) {
       if (result.hasException) {
         print('[GraphQLService Subscribe Error] ${result.exception.toString()}');
         throw result.exception!;
       }
       if (kDebugMode) { print("[GraphQLService] Subscription data received for ${operationName ?? 'subscription'}: ${result.data}"); }
       return result.data ?? {};
     });
   }


  // Métodos CRUD com logs
  @override Future<Map<String, dynamic>> create({ required String path, Map<String, dynamic> params = const {}, }) async {
    print("[GraphQLService] Attempting: CREATE (Mutation)");
    try { final options = MutationOptions(variables: params, document: gql(path)); final result = await client.mutate(options); _checkResultForErrors(result); return result.data ?? {}; } catch (e) { print("[GraphQLService] FAILED: CREATE"); _handleException(e); rethrow; }
  }
  @override Future<Map<String, dynamic>> read({ required String path, Map<String, dynamic> params = const {}, }) async {
    print("[GraphQLService] Attempting: READ (Query)");
    try { final options = QueryOptions(variables: params, document: gql(path)); final result = await client.query(options); _checkResultForErrors(result); return result.data ?? {}; } catch (e) { print("[GraphQLService] FAILED: READ"); _handleException(e); rethrow; }
  }
  @override Future<Map<String, dynamic>> update({ required String path, Map<String, dynamic> params = const {}, }) async {
     print("[GraphQLService] Attempting: UPDATE (Mutation)");
    try { final options = MutationOptions(variables: params, document: gql(path)); final result = await client.mutate(options); _checkResultForErrors(result); return result.data ?? {}; } catch (e) { print("[GraphQLService] FAILED: UPDATE"); _handleException(e); rethrow; }
  }
  @override Future<Map<String, dynamic>> delete({ required String path, Map<String, dynamic> params = const {}, }) async {
    print("[GraphQLService] Attempting: DELETE (Mutation)");
    try { final options = MutationOptions(document: gql(path), variables: params); final result = await client.mutate(options); _checkResultForErrors(result); return result.data ?? {}; } catch (e) { print("[GraphQLService] FAILED: DELETE"); _handleException(e); rethrow; }
  }


  // --- Helpers de Tratamento de Erro (com refinamento opcional no _containsInvalidAuthResult) ---

  void _checkResultForErrors(QueryResult result) {
     if (result.hasException) {
        print("[GraphQLService] Result has exception: ${result.exception.toString()}");
        // Usa a função refinada (opcionalmente) ou a sua original
        if (_containsInvalidAuthResult(result)) {
           print("[GraphQLService] Interpreted as AuthException.");
           throw const AuthException(code: 'session-expired');
        }
        throw result.exception!;
     }
   }

  // Função refinada para checar APENAS erros prováveis de autenticação
  bool _containsInvalidAuthResult(QueryResult result) {
     if(result.exception == null) return false;
     final List<GraphQLError> graphqlErrors = result.exception!.graphqlErrors;
     if (graphqlErrors.isNotEmpty) {
       final Map<String, dynamic> errorExtensions = graphqlErrors.first.extensions ?? {};
       final errorCode = errorExtensions['code']?.toString().toLowerCase();
       print("[GraphQLService] Checking Error Code: $errorCode");
       // Lista mais restrita
       return ['invalid-jwt', 'invalid-headers', 'token-expired']
          .any((code) => errorCode == code);
     }
     return false;
  }

   // Função _handleException (com logs detalhados adicionados)
   void _handleException(dynamic e) {
       print('[GraphQLService Raw Exception Caught] Type: ${e.runtimeType}, Error: ${e.toString()}');
       if (e is OperationException && e.graphqlErrors.isNotEmpty) {
         print('[GraphQLService GraphQL Errors Details]: ${e.graphqlErrors}');
          if (e.graphqlErrors.first.extensions != null) {
             print('[GraphQLService First Error Extensions]: ${e.graphqlErrors.first.extensions}');
          }
       }
       if (e is OperationException && e.linkException != null) { throw const ConnectionException(code: 'connection-error'); }
       // Relança as exceções específicas ou OperationException
       if (e is AuthException || e is CacheException || e is ConnectionException || e is APIException || e is OperationException) { throw e; }
       // Fallback para exceção genérica
       throw const GeneralException();
    }
}

// --- Suas Classes de Exceção ---
/* Se não estiverem definidas em outro lugar, defina-as:
class AuthException implements Exception { final String code; const AuthException({required this.code}); /* ... */ }
class ConnectionException implements Exception { final String code; const ConnectionException({required this.code}); /* ... */ }
class CacheException implements Exception { /* ... */ }
class APIException implements Exception { /* ... */ }
class GeneralException implements Exception { const GeneralException(); /* ... */ }
*/