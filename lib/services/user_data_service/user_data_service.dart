import 'package:tcc_3/common/data/data_result.dart';
import 'package:tcc_3/common/models/user_model.dart';

abstract class UserDataService {
  Future<DataResult<UserModel>> getUserData();
}