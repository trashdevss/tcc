import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/services/auth_service.dart';

class MockFirebaseAuthService extends Mock implements AuthService {}

void main() {
  late MockFirebaseAuthService mockFirebaseAuthService;

  setUp(() {
    mockFirebaseAuthService = MockFirebaseAuthService();
  });

  test('Test sign up success', () async {  // <-- Adicionei async aqui
    final user = UserModel(
      name: 'user',
      email: 'user@email.com',
      password: 'user@1234',
    );

    when(() => mockFirebaseAuthService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => user);

    final result = await mockFirebaseAuthService.signUp(
      name: 'user',
      email: 'user@email.com',
      password: 'user@1234',
    );

    expect(result, user);
  });
}
