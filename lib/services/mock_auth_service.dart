import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/services/auth_service.dart';

class MockAuthService implements AuthService {
  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      if (password.startsWith('123')) {
        throw Exception('Senha insegura');
      }
      return UserModel(
        id: email.hashCode.toString(),
        email: email,
      );
    } catch (e) {
      if (e is Exception && e.toString().contains('Senha insegura')) {
        throw Exception("Erro ao logar, tente novamente");
      }
      throw Exception("Não foi possível realizar login");
    }
  }

  @override
  Future<UserModel> signUp({
    String? name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      if (password.startsWith('123')) {
        throw Exception('Senha insegura');
      }
      return UserModel(
        id: email.hashCode.toString(),
        name: name ?? '',
        email: email,
      );
    } catch (e) {
      if (e is Exception && e.toString().contains('Senha insegura')) {
        throw Exception("Senha insegura, digite uma senha forte");
      }
      throw Exception("Não foi possível criar sua conta");
    }
  }
  
  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
  
  @override
  // TODO: implement userToken
  Future<String> get userToken => throw UnimplementedError();
}
