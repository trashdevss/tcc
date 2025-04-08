import 'package:graphql_flutter/graphql_flutter.dart';
import 'auth_service.dart';

class GraphQLService {
  final AuthService authService;

  GraphQLService({
    required this.authService,
  });

  late GraphQLClient client;

  Future<void> init() async {
    final token = await authService.userToken;

    final HttpLink httpLink = HttpLink(
      'https://tight-monarch-58.hasura.app/v1/graphql',
    );

    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final Link link = authLink.concat(httpLink);

    client = GraphQLClient(
      link: link,
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.networkOnly),
        mutate: Policies(fetch: FetchPolicy.networkOnly),




      ),
      cache: GraphQLCache(store: InMemoryStore()),
    );


}
}



































































