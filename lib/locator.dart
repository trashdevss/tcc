// lib/locator.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/features/metas/goals_repository.dart';
import 'package:tcc_3/features/metas/goals_repository_impl.dart'; // Usando Hasura Impl
import 'package:tcc_3/features/stats/stats_controller.dart';
import 'common/features/transaction/transaction.dart'; // Para TransactionController
import 'features/home/home_controller.dart';
import 'features/profile/profile_controller.dart';
import 'features/sign_in/sign_in_controller.dart';
import 'features/sign_up/sign_up_controller.dart';
import 'features/splash/splash_controller.dart';
import 'features/wallet/wallet_controller.dart';
import 'repositories/repositories.dart'; // Import geral de repositórios (deve incluir TransactionRepository e Impl)
import 'services/services.dart'; // Import geral de serviços

// Imports para Metas
import 'package:tcc_3/features/metas/goals_controller.dart';

final locator = GetIt.instance;

void setupDependencies() {
  // --- Register Services ---
  locator.registerFactory<AuthService>( () => FirebaseAuthService(), );
  locator.registerFactory<SecureStorageService>( () => const SecureStorageService());
  locator.registerFactory<ConnectionService>(() => const ConnectionService());
  // Registra GraphQLService como Singleton Assíncrono
  locator.registerSingletonAsync<GraphQLService>( () async => GraphQLService( authService: locator.get<AuthService>(), ).init(), );
  locator.registerSingletonAsync<DatabaseService>( () async => DatabaseService().init(), );
  locator.registerFactory<SyncService>( () => SyncService( connectionService: locator.get<ConnectionService>(), databaseService: locator.get<DatabaseService>(), graphQLService: locator.get<GraphQLService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<UserDataService>(() => UserDataServiceImpl( firebaseAuth: FirebaseAuth.instance, firebaseFunctions: FirebaseFunctions.instance, ));

  // --- Register Repositories ---

  // Repositório de Transações
  locator.registerFactory<TransactionRepository>(
    () => TransactionRepositoryImpl( // Garanta que TransactionRepositoryImpl está exportado em repositories.dart ou importe diretamente
      databaseService: locator.get<DatabaseService>(),
      syncService: locator.get<SyncService>(),
    ),
  );

  // --- Registro do Repositório de Metas (CORRIGIDO) ---
  locator.registerLazySingleton<GoalsRepository>(() { // Usa a função com {} para permitir múltiplos passos
      // 1. Obtenha a instância do GraphQLService (que já deve estar registrada e inicializada)
      //    O GetIt cuidará de esperar o registerSingletonAsync se necessário aqui.
      final graphQLService = locator<GraphQLService>();

      // 2. Acesse a instância do GraphQLClient DENTRO do GraphQLService.
      //    !!!! IMPORTANTE: '.client' é uma suposição !!!!
      //    Verifique na sua classe GraphQLService qual o nome do campo ou getter
      //    que te dá acesso à instância configurada do GraphQLClient.
      //    Pode ser '.client', '.getClient()', etc. AJUSTE CONFORME NECESSÁRIO.
      final graphQLClient = graphQLService.client; // <<< AJUSTE AQUI SE NECESSÁRIO

      // 3. Passe a instância CORRETA do GraphQLClient para o seu repositório.
      return GoalsRepositoryImpl(client: graphQLClient);
  });
  // --- Fim da Correção ---

  // --- Register Controllers ---
  locator.registerFactory<SplashController>( () => SplashController( secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<SignInController>( () => SignInController( authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<SignUpController>( () => SignUpController( authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  // Controllers que dependem de TransactionRepository
  locator.registerLazySingleton<HomeController>( () => HomeController( transactionRepository: locator.get<TransactionRepository>(), userDataService: locator.get<UserDataService>(), ), );
  locator.registerLazySingleton<WalletController>( () => WalletController( transactionRepository: locator.get<TransactionRepository>(), ), );
  locator.registerLazySingleton<BalanceController>( () => BalanceController( transactionRepository: locator.get<TransactionRepository>(), ), );
  locator.registerLazySingleton<TransactionController>( () => TransactionController( transactionRepository: locator.get<TransactionRepository>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerLazySingleton<StatsController>(() => StatsController( transactionRepository: locator.get<TransactionRepository>()));
  // Outros Controllers
  locator.registerFactory<SyncController>( () => SyncController( syncService: locator.get<SyncService>(), ), );
  locator.registerFactory<ProfileController>( () => ProfileController(userDataService: locator.get<UserDataService>()));

  // Registro do Controller de Metas
  locator.registerLazySingleton<GoalsController>(() => GoalsController(repository: locator<GoalsRepository>()));

}