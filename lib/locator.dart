// lib/locator.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
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

// Import do JoveNotificationService
import 'package:tcc_3/services/data_service/jove_notification_service.dart'; 

// --- NOVO: Import do serviço de conquistas ---
import 'package:tcc_3/services/achievement_service.dart';


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
  locator.registerLazySingleton<JoveNotificationService>(() => JoveNotificationService());
  
  // --- NOVO: Registro do serviço de conquistas ---
  locator.registerLazySingleton<AchievementService>(() => AchievementService());


  // --- Register Repositories ---
  locator.registerFactory<TransactionRepository>(
    () => TransactionRepositoryImpl( 
      databaseService: locator.get<DatabaseService>(),
      syncService: locator.get<SyncService>(),
    ),
  );

  locator.registerLazySingleton<GoalsRepository>(() { 
    final graphQLService = locator<GraphQLService>();
    final graphQLClient = graphQLService.client;
    return GoalsRepositoryImpl(client: graphQLClient);
  });
  

  // --- Register Controllers ---
  locator.registerFactory<SplashController>( () => SplashController( secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<SignInController>( () => SignInController( authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerFactory<SignUpController>( () => SignUpController( authService: locator.get<AuthService>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  
  locator.registerLazySingleton<HomeController>( () => HomeController( transactionRepository: locator.get<TransactionRepository>(), userDataService: locator.get<UserDataService>(), ), );
  
  locator.registerLazySingleton<WalletController>( 
    () => WalletController( 
      transactionRepository: locator.get<TransactionRepository>(), 
      joveNotificationService: locator.get<JoveNotificationService>(),
    ), 
  );

  locator.registerLazySingleton<BalanceController>( () => BalanceController( transactionRepository: locator.get<TransactionRepository>(), ), );
  locator.registerLazySingleton<TransactionController>( () => TransactionController( transactionRepository: locator.get<TransactionRepository>(), secureStorageService: locator.get<SecureStorageService>(), ), );
  locator.registerLazySingleton<StatsController>(() => StatsController( transactionRepository: locator.get<TransactionRepository>()));
  
  locator.registerFactory<SyncController>( () => SyncController( syncService: locator.get<SyncService>(), ), );
  locator.registerFactory<ProfileController>( () => ProfileController(userDataService: locator.get<UserDataService>()));

  locator.registerLazySingleton<GoalsController>(() => GoalsController(repository: locator<GoalsRepository>()));
}