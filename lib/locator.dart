// lib/locator.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/features/metas/goals_repository.dart';
import 'package:tcc_3/features/metas/goals_repository_impl.dart'; 
import 'package:tcc_3/features/stats/stats_controller.dart';
import 'common/features/transaction/transaction.dart'; 
import 'features/home/home_controller.dart';
import 'features/profile/profile_controller.dart';
import 'features/sign_in/sign_in_controller.dart';
import 'features/sign_up/sign_up_controller.dart';
import 'features/splash/splash_controller.dart';
import 'features/wallet/wallet_controller.dart';
import 'repositories/repositories.dart'; 
import 'services/services.dart'; 

// Imports para Metas
import 'package:tcc_3/features/metas/goals_controller.dart';

// <<--- ADICIONE O IMPORT PARA JOVENOTIFICATIONSERVICE ---
import 'package:tcc_3/services/data_service/jove_notification_service.dart'; 


final locator = GetIt.instance;

void setupDependencies() {
  // --- Register Services ---
  locator.registerFactory<AuthService>( () => FirebaseAuthService(), );
  locator.registerFactory<SecureStorageService>( () => const SecureStorageService());
  locator.registerFactory<ConnectionService>(() => const ConnectionService());
  locator.registerSingletonAsync<GraphQLService>( () async => GraphQLService( authService: locator.get<AuthService>(), ).init(), );
  locator.registerSingletonAsync<DatabaseService>( () async => DatabaseService().init(), );
  locator.registerFactory<SyncService>( () => SyncService( connectionService: locator.get<ConnectionService>(), databaseService: locator.get<DatabaseService>(), graphQLService: locator.get<GraphQLService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<UserDataService>(() => UserDataServiceImpl( firebaseAuth: FirebaseAuth.instance, firebaseFunctions: FirebaseFunctions.instance, ));

  // <<--- REGISTRAR JOVENOTIFICATIONSERVICE ---
  // Geralmente como LazySingleton para que seja criado apenas quando necessário
  // e apenas uma instância seja usada em todo o app.
  locator.registerLazySingleton<JoveNotificationService>(() => JoveNotificationService());


  // --- Register Repositories ---

  locator.registerFactory<TransactionRepository>(
    () => TransactionRepositoryImpl( 
      databaseService: locator.get<DatabaseService>(),
      syncService: locator.get<SyncService>(),
    ),
  );

  locator.registerLazySingleton<GoalsRepository>(() { 
    final graphQLService = locator<GraphQLService>();
    // !!! IMPORTANTE: Verifique se 'graphQLService.client' é a forma correta de obter o GraphQLClient !!!
    // Pode ser um getter diferente ou um método.
    final graphQLClient = graphQLService.client; // <<< AJUSTE AQUI SE 'client' não for o nome correto
    return GoalsRepositoryImpl(client: graphQLClient);
  });
  

  // --- Register Controllers ---
  locator.registerFactory<SplashController>( () => SplashController( secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<SignInController>( () => SignInController( authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<SignUpController>( () => SignUpController( authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  
  locator.registerLazySingleton<HomeController>( () => HomeController( transactionRepository: locator.get<TransactionRepository>(), userDataService: locator.get<UserDataService>(), ), );
  
  // <<--- ATUALIZAR REGISTRO DO WALLETCONTROLLER ---
  locator.registerLazySingleton<WalletController>( 
    () => WalletController( 
      transactionRepository: locator.get<TransactionRepository>(), 
      joveNotificationService: locator.get<JoveNotificationService>(), // Passa a instância do JoveNotificationService
    ), 
  );
  // <<--- FIM DA ATUALIZAÇÃO DO WALLETCONTROLLER ---

  locator.registerLazySingleton<BalanceController>( () => BalanceController( transactionRepository: locator.get<TransactionRepository>(), ), );
  locator.registerLazySingleton<TransactionController>( () => TransactionController( transactionRepository: locator.get<TransactionRepository>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerLazySingleton<StatsController>(() => StatsController( transactionRepository: locator.get<TransactionRepository>()));
  
  locator.registerFactory<SyncController>( () => SyncController( syncService: locator.get<SyncService>(), ), );
  locator.registerFactory<ProfileController>( () => ProfileController(userDataService: locator.get<UserDataService>()));

  locator.registerLazySingleton<GoalsController>(() => GoalsController(repository: locator<GoalsRepository>()));

}