

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/repositories/transaction_repository.dart';
import 'package:tcc_3/services/auth_service/auth_service.dart';
import 'package:tcc_3/services/data_service/database_service.dart';
import 'package:tcc_3/services/data_service/graphql_service.dart';
import 'package:tcc_3/services/secure_storage.dart';
import 'package:tcc_3/services/sync_services/sync_service.dart';
import 'package:tcc_3/services/user_data_service/user_data_service.dart';

// Mock Models

class MockUser extends Mock implements UserModel {}

// Mock Services
class MockFirebaseAuthService extends Mock implements AuthService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockGraphQLService extends Mock implements GraphQLService {}

class MockSyncService extends Mock implements SyncService {}

class MockUserDataService extends Mock implements UserDataService {}

// Mock Repositories

class MockTransactionRepository extends Mock implements TransactionRepository {}

// Mock FirebaseAuth

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class FakeUser extends Fake implements User {
  @override
  String get uid => '123456abc';

  @override
  String get displayName => 'User';

  @override
  String get email => 'user@email.com';
}