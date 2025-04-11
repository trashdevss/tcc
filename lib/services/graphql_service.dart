import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:tcc_3/services/api_services.dart';
import 'auth_service.dart';

class GraphQLService implements ApiService<GraphQLClient, QueryResult> {
  GraphQLService({
    required this.authService,
  });

  final AuthService authService;

  late GraphQLClient _client;
  GraphQLClient get client => _client;

  Future<GraphQLService> init() async {
    await initHiveForFlutter();

    final HttpLink httpLink = HttpLink(
      'https://tight-monarch-58.hasura.app/v1/graphql',
    );

    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer ${await authService.userToken}',
    );

    final Link link = authLink.concat(httpLink);

    _client = GraphQLClient(
      link: link,
      defaultPolicies: DefaultPolicies(
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
        query: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
      ),
      cache: GraphQLCache(store: HiveStore()),
    );

    return this;
  }

  @override
  Future<QueryResult> create({
    required String path,
    Map<String, dynamic>? params,
  }) async {
    try {
      final options = MutationOptions(
        variables: params ?? {},
        document: gql(path),
      );

      final result = await client.mutate(options);
      if (result.hasException) {
        throw result.exception as Object;
      }
      return result;

    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QueryResult> read({
    required String path,
    Map<String, dynamic>? params,
  }) async {
    try {
      final options = QueryOptions(
        variables: params ?? {},
        document: gql(path),
      );
      final cacheResult = client.readQuery(
        options.asRequest,
      );
      final result = await client.query(options);

      if (result.data != null && !result.hasException) {
        return result;
      } else {
        return QueryResult(
          options: options,
          source: QueryResultSource.cache,
          data: cacheResult,
        );
      }

    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QueryResult> update({
    required String path,
    Map<String, dynamic>? params,
  }) async {
    try {
      final options = MutationOptions(
        variables: params ?? {},
        document: gql(path),
      );

      final result = await client.mutate(options);

      if (result.hasException) {
        throw result.exception as Object;
      }

      return result;


    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QueryResult> delete({
    required String path,
    Map<String, dynamic>? params,
  }) async {
    try {
      final options = MutationOptions(
        document: gql(path),
        variables: params ?? {},


      );

      final result = await client.mutate(options);

      if (result.hasException) {
        throw result.exception as Object;
      }

      return result;
    } on OperationException catch (e) {
      if (e.graphqlErrors.isNotEmpty) {
        throw e.graphqlErrors.first;
      }
      if (e.linkException != null) {
        throw e.linkException!;
      }

      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}