// Possivelmente em lib/services/user_data_service/user_data_service.dart

// Imports necessários para DataResult e UserModel (VERIFIQUE OS CAMINHOS)
import '../../common/data/data_result.dart';
import '../../common/models/models.dart';

abstract class UserDataService {
  Future<DataResult<UserModel>> getUserData();

  Future<DataResult<UserModel>> updateUserName(String newUserName);

  Future<DataResult<bool>> updatePassword(String newPassword);

  // O método updateProfilePictureUrl NÃO estava definido nesta versão "original"

  UserModel get userData;
}