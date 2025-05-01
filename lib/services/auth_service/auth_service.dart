// lib/services/auth_service.dart (ou o caminho correto no seu projeto)

import '../../common/data/data.dart'; // Para DataResult
import '../../common/models/models.dart'; // Para UserModel

abstract class AuthService {
  Future<DataResult<UserModel>> signUp({
    String? name,
    required String email,
    required String password,
  });

  Future<DataResult<UserModel>> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<DataResult<String>> userToken();

  // +++ GETTER ADICIONADO +++
  // Retorna o ID do usuário logado atualmente, ou null se não houver usuário.
  String? get currentUserId;
  // ++++++++++++++++++++++++
}