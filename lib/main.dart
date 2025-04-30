import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart'; // Import para initHiveForFlutter
import 'package:intl/date_symbol_data_local.dart'; // <<<--- IMPORT ADICIONADO

import 'app.dart'; // Seu widget App principal
import 'firebase_options.dart'; // Suas opções Firebase
import 'locator.dart'; // Seu setup GetIt
// Importe seu GraphQLService se a inicialização dele estiver aqui
// import 'services/graphql_service.dart';

void main() async {
  // Garante que os bindings do Flutter estão prontos antes de chamadas async
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==================================================
  // <<<--- INICIALIZAÇÃO DA FORMATAÇÃO DE DATA --- >>>
  // ==================================================
  // Inicializa os dados de localidade para Português do Brasil
  // Necessário para usar DateFormat com 'pt_BR'
  await initializeDateFormatting('pt_BR', null);
  // ==================================================

  // Inicializa o cache do Hive para graphql_flutter (se estiver usando)
  // Se não usar Hive, pode remover esta linha
  await initHiveForFlutter();

  // Configura suas dependências (GetIt)
  // Garanta que o GraphQLService seja inicializado aqui se usar locator.get mais tarde
  setupDependencies(); // Ou await setupDependencies(); se for async

  // Espera que todas as dependências assíncronas no GetIt estejam prontas
  await locator.allReady();

  // --- Configuração do GraphQL Client (Exemplo se não estiver no setupDependencies) ---
  // Se você não inicializa e registra o GraphQLService/Client no setupDependencies,
  // você precisaria fazer isso aqui antes do runApp, como no exemplo anterior.
  // Exemplo:
  // final graphQLService = locator.get<GraphQLService>();
  // await graphQLService.init(); // Garante que o cliente está pronto
  // ValueNotifier<GraphQLClient> clientNotifier = ValueNotifier(graphQLService.client);
  // ----------------------------------------------------------------------------------

  // Executa o aplicativo principal
  // Se você configurou o clientNotifier acima, passe-o para o App:
  // runApp(App(client: clientNotifier));
  // Se o GraphQLProvider for configurado dentro do App, apenas chame:
  runApp(const App());
}

// Lembre-se de definir seu widget App, que provavelmente conterá o MaterialApp
// e o GraphQLProvider (se não for configurado aqui em main).
// Exemplo:
/*
class App extends StatelessWidget {
  // final ValueNotifier<GraphQLClient> client; // Se passar o clientNotifier
  const App({super.key /*, required this.client */});

  @override
  Widget build(BuildContext context) {
    // Obtenha o client do locator se não passou via construtor
    final graphQLService = locator.get<GraphQLService>();
    ValueNotifier<GraphQLClient> clientNotifier = ValueNotifier(graphQLService.client);

    return GraphQLProvider(
      client: clientNotifier,
      child: MaterialApp(
        title: 'Jovemony',
        // theme: ...,
        home: SplashScreen(), // Sua tela inicial
        // routes: ...,
      ),
    );
  }
}
*/
