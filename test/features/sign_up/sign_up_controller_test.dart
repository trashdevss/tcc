
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/common/data/data_result.dart';
import 'package:tcc_3/features/sign_up/sign_up_controller.dart';
import 'package:tcc_3/features/sign_up/sign_up_state.dart';

import '../../mock/mock_classes.dart';

void main() {
  late SignUpController signUpController;
  late MockSecureStorage mockSecureStorage;
  late MockFirebaseAuthService mockFirebaseAuthService;
  late MockGraphQLService mockGraphQLService;
  late UserModel user;
  setUp(() {
    mockFirebaseAuthService = MockFirebaseAuthService();
    mockSecureStorage = MockSecureStorage();
    mockGraphQLService = MockGraphQLService();

    signUpController = SignUpController(
      authService: mockFirebaseAuthService,
      secureStorageService: mockSecureStorage,
    );

    user = UserModel(
      name: 'User',
      email: 'user@email.com',
      id: '1a2b3c4d5e',
    );
  });

  group('Tests Sign Up Controller State', () {
    test('Should update state to SignUpStateSuccess', () async {
      expect(signUpController.state, isInstanceOf<SignUpStateInitial>());

      when(() => mockGraphQLService.init())
          .thenAnswer((_) async => mockGraphQLService);

      when(() => mockSecureStorage.write(
            key: "CURRENT_USER",
            value: user.toJson(),
          )).thenAnswer((_) async {});

      when(
        () => mockFirebaseAuthService.signUp(
          name: 'User',
          email: 'user@email.com',
          password: 'user@123',
        ),
      ).thenAnswer(
        (_) async => DataResult.success(user),
      );

      await signUpController.signUp(
        name: 'User',
        email: 'user@email.com',
        password: 'user@123',
      );
      expect(signUpController.state, isInstanceOf<SignUpStateSuccess>());
    });

    test('Should update state to SignUpStateError', () async {
      expect(signUpController.state, isInstanceOf<SignUpStateInitial>());

      when(
        () => mockSecureStorage.write(
          key: "CURRENT_USER",
          value: user.toJson(),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockFirebaseAuthService.signUp(
          name: 'User',
          email: 'user@email.com',
          password: 'user@123',
        ),
      ).thenThrow(
        Exception(),
      );

      await signUpController.signUp(
        name: 'User',
        email: 'user@email.com',
        password: 'user@123',
      );
      expect(signUpController.state, isInstanceOf<SignUpStateError>());
    });
  });
}