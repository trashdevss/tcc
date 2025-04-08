import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/features/splash/splash_controller.dart';
import 'package:tcc_3/features/splash/splash_state.dart';

import '../../mock/mock_classes.dart';

void main() {
  late MockSecureStorage secureStorage;
  late SplashController splashController;
  late MockGraphQLService mockGraphQLService;
  late UserModel user;

  setUp(() {
    secureStorage = MockSecureStorage();
    mockGraphQLService = MockGraphQLService();
    splashController = SplashController(
      secureStorageService: secureStorage,

    );
    user = UserModel(
      name: 'User',
      email: 'user@email.com',
      id: '1a2b3c4d5e',
    );
  });

  group('Tests Splash Controller', () {
    test('Should update state to UnauthenticatedUser', () async {
      when(() => secureStorage.readOne(key: 'CURRENT_USER'))
          .thenAnswer((_) async => null);

      expect(splashController.state, isInstanceOf<SplashStateInitial>());

      await splashController.isUserLogged();

      expect(splashController.state, isInstanceOf<UnauthenticatedUser>());
    });
    test('Should update state to AuthenticatedUser', () async {
      when(() => secureStorage.readOne(key: 'CURRENT_USER'))
          .thenAnswer((_) async => user.toJson());

      when(() => mockGraphQLService.init())
          .thenAnswer((_) async => mockGraphQLService);

      expect(splashController.state, isInstanceOf<SplashStateInitial>());

      await splashController.isUserLogged();

      expect(splashController.state, isInstanceOf<AuthenticatedUser>());
    });
  });
}