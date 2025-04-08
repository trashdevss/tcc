import 'package:mocktail/mocktail.dart';
import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/services/auth_service.dart';
import 'package:tcc_3/services/graphql_service.dart';
import 'package:tcc_3/services/secure_storage.dart';

class MockFirebaseAuthService extends Mock implements AuthService {}

class MockSecureStorage extends Mock implements SecureStorageService {}

class MockGraphQLService extends Mock implements GraphQLService {}

class MockUser extends Mock implements UserModel {}