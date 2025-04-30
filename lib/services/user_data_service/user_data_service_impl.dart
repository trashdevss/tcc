// lib/services/user_data_service/user_data_service_impl.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Ajuste os imports conforme sua estrutura
import 'package:tcc_3/common/data/data_result.dart';     // <<< VERIFIQUE ESTE CAMINHO
import 'package:tcc_3/common/data/exceptions.dart';    // <<< VERIFIQUE ESTE CAMINHO
import 'package:tcc_3/common/models/models.dart';        // <<< VERIFIQUE ESTE CAMINHO (para UserModel)
import 'package:tcc_3/services/data_service/graphql_service.dart';
import 'user_data_service.dart'; // Import da Interface

// === QUERIES E MUTATIONS GraphQL (Verifique nomes!) ===
const String getUserDataQuery = r'''
  query GetUserData($userId: String!) {
    user_by_pk(id: $userId) { id name email profile_picture_url }
  }
''';
// Sem a mutation de update aqui nesta versão

class UserDataServiceImpl implements UserDataService {
  UserDataServiceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFunctions firebaseFunctions,
    required GraphQLService graphQLService,
  })  : _auth = firebaseAuth,
        _functions = firebaseFunctions,
        _graphQLService = graphQLService;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final GraphQLService _graphQLService;

  UserModel _userData = UserModel();
  @override UserModel get userData => _userData;

  @override
  Future<DataResult<UserModel>> getUserData() async {
    print("DEBUG Service: Iniciando getUserData...");
    try {
      final user = _auth.currentUser;
      if (user == null) { throw const AuthException(code: 'user-not-found'); }
      final userId = user.uid;
      print("DEBUG Service: userId = $userId");

      print("DEBUG Service: Executando query via GraphQLService.read...");
      final Map<String, dynamic> resultData = await _graphQLService.read(
        path: getUserDataQuery,
        params: {'userId': userId},
      );

      final Map<String, dynamic>? userDataFromDb = resultData['user_by_pk'];

      if (userDataFromDb == null) {
        print("DEBUG Service: Dados do usuário não encontrados no DB via Hasura. Usando fallback.");
         _userData = UserModel(
           id: userId,
           email: user.email,
           name: user.displayName,
           profilePictureUrl: null // Sem foto
         );
        return DataResult.success(_userData);
      }
      _userData = UserModel.fromMap(userDataFromDb);
      print("DEBUG Service: Dados carregados do Hasura: ${_userData.toMap()}");
      return DataResult.success(_userData);

    } on FirebaseAuthException catch (e) { print("DEBUG Service: FirebaseAuthException em getUserData: ${e.code}"); return DataResult.failure(AuthException(code: e.code)); }
      on Exception catch (e) { print("DEBUG Service: Exception geral em getUserData: ${e.toString()}"); return DataResult.failure(const GeneralException()); }
  }

  @override
  Future<DataResult<bool>> updatePassword(String password) async {
     try { /* ... Sua lógica original ... */ return DataResult.success(true); }
     on FirebaseAuthException catch (e) { return DataResult.failure(AuthException(code: e.code)); }
     catch (e) { print("DEBUG Service: Exception em updatePassword: ${e.toString()}"); return DataResult.failure(const GeneralException()); }
  }

  @override
  Future<DataResult<UserModel>> updateUserName(String name) async {
      try { /* ... Sua lógica original ... */ return DataResult.success(_userData); }
      on FirebaseAuthException catch (e) { return DataResult.failure(AuthException(code: e.code)); }
      on FirebaseFunctionsException catch (e) { print("DEBUG Service: FirebaseFunctionsException em updateUserName: ${e.code}"); return DataResult.failure(const GeneralException()); }
      catch (e) { print("DEBUG Service: Exception geral em updateUserName: ${e.toString()}"); return DataResult.failure(const GeneralException()); }
  }

  // MÉTODO updateProfilePictureUrl NÃO EXISTE NESTA VERSÃO
}


// --- Interface UserDataService (Como estava no final do arquivo) ---
// Se esta definição estiver em user_data_service.dart, remova daqui
// abstract class UserDataService {
//   Future<DataResult<UserModel>> getUserData();
//   Future<DataResult<UserModel>> updateUserName(String newUserName);
//   Future<DataResult<bool>> updatePassword(String newPassword);
//   // Sem updateProfilePictureUrl aqui
//   UserModel get userData;
// }