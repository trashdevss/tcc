// lib/locator.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Features (Controllers) - Use caminhos completos
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/features/stats/stats_controller.dart';
import 'package:tcc_3/common/features/transaction/transaction_controller.dart';
import 'package:tcc_3/features/home/home_controller.dart';
import 'package:tcc_3/features/profile/profile_controller.dart';
import 'package:tcc_3/features/sign_in/sign_in_controller.dart';
import 'package:tcc_3/features/sign_up/sign_up_controller.dart';
import 'package:tcc_3/features/splash/splash_controller.dart';
import 'package:tcc_3/features/wallet/wallet_controller.dart';
// Importe o SyncController se ele já existia aqui
// import 'package:tcc_3/services/sync_services/sync_controller.dart';

// Repositories - Use caminhos completos
import 'package:tcc_3/repositories/transaction_repository.dart';
import 'package:tcc_3/repositories/transaction_repository_impl.dart';

// Services - Use caminhos completos e específicos
import 'package:tcc_3/services/auth_service/auth_service.dart';
import 'package:tcc_3/services/auth_service/firebase_auth_service.dart';
import 'package:tcc_3/services/connection_service.dart';
import 'package:tcc_3/services/data_service/database_service.dart';
import 'package:tcc_3/services/data_service/graphql_service.dart';
import 'package:tcc_3/services/secure_storage.dart';
import 'package:tcc_3/services/sync_services/sync_service.dart';
import 'package:tcc_3/services/user_data_service/user_data_service.dart';
import 'package:tcc_3/services/user_data_service/user_data_service_impl.dart';

final locator = GetIt.instance;

Future<void> setupDependencies() async { // Marcada como async

  // --- Serviços Essenciais ---
  locator.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  locator.registerLazySingleton<FirebaseFunctions>(() => FirebaseFunctions.instance);
  locator.registerFactory<SecureStorageService>(() => const SecureStorageService());
  locator.registerFactory<ConnectionService>(() => const ConnectionService());

  // --- Serviço de Autenticação ---
  locator.registerFactory<AuthService>(() => FirebaseAuthService());

  // --- Serviço GraphQL (Configuração e Registro) ---
  // COLOQUE SUA CONFIGURAÇÃO REAL AQUI (HttpLink, AuthLink, etc.)
  // ... (código da configuração do GraphQLClient 'client' omitido para brevidade) ...
  // Substitua pelo seu código real de configuração do client GraphQL
  final GraphQLClient client = GraphQLClient(cache: GraphQLCache(store: InMemoryStore()), link: HttpLink('SUA_URL_HASURA_AQUI')); // EXEMPLO SIMPLES
  locator.registerLazySingleton<GraphQLClient>(() => client);
  locator.registerSingletonAsync<GraphQLService>( () async => GraphQLService( authService: locator.get<AuthService>(), /* client: client? */ ).init(), );

  // --- Outros Serviços (Database, Sync) ---
  locator.registerSingletonAsync<DatabaseService>( () async => DatabaseService().init(), );
  locator.registerFactory<SyncService>( () => SyncService( connectionService: locator.get<ConnectionService>(), databaseService: locator.get<DatabaseService>(), graphQLService: locator.get<GraphQLService>(), secureStorageService: locator.get<SecureStorageService>(), ), );

  // ========== UserDataService ==========
  locator.registerFactory<UserDataService>(() => UserDataServiceImpl(
        firebaseAuth: locator.get<FirebaseAuth>(),
        firebaseFunctions: locator.get<FirebaseFunctions>(),
        graphQLService: locator.get<GraphQLService>(),
      ));
  // =====================================

  // --- Repositórios ---
  locator.registerFactory<TransactionRepository>( () => TransactionRepositoryImpl( databaseService: locator.get<DatabaseService>(), syncService: locator.get<SyncService>(), ), );

  // --- Controllers ---
  locator.registerFactory<SplashController>(() => SplashController(secureStorageService: locator.get<SecureStorageService>()));
  locator.registerFactory<SignInController>(() => SignInController(authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>()));
  locator.registerFactory<SignUpController>(() => SignUpController(authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>()));
  locator.registerLazySingleton<HomeController>(() => HomeController(transactionRepository: locator.get<TransactionRepository>(), userDataService: locator.get<UserDataService>()));
  locator.registerLazySingleton<WalletController>(() => WalletController(transactionRepository: locator.get<TransactionRepository>()));
  locator.registerLazySingleton<BalanceController>(() => BalanceController(transactionRepository: locator.get<TransactionRepository>()));
  locator.registerLazySingleton<TransactionController>(() => TransactionController(transactionRepository: locator.get<TransactionRepository>(), secureStorageService: locator.get<SecureStorageService>()));
  locator.registerFactory<SyncController>(() => SyncController(syncService: locator.get<SyncService>()));

  // Registro do ProfileController (sem AuthService inicialmente)
  // Dentro da função setupDependencies() em locator.dart

// Encontre onde você registra ProfileController:
locator.registerFactory<ProfileController>(() => ProfileController(
      userDataService: locator.get<UserDataService>(),
      // >>> GARANTA QUE ESTA LINHA ESTÁ PRESENTE E SEM O '//' NO COMEÇO <<<
      authService: locator.get<AuthService>(),
    ));
  locator.registerLazySingleton<StatsController>(() => StatsController(transactionRepository: locator.get<TransactionRepository>()));

  print("DEBUG: Dependências configuradas no locator (versão original).");
}