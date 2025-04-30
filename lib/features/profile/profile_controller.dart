import 'package:flutter/foundation.dart';
// Removidos: import 'dart:io';
// Removidos: import 'package:image_picker/image_picker.dart';
// Removidos: import 'package:firebase_storage/firebase_storage.dart';
// Removidos: import 'package:firebase_core/firebase_core.dart'; // Removido se não for usado em outro lugar

// Seus imports existentes (VERIFIQUE OS CAMINHOS):
import '../../common/models/models.dart';
import '../../services/services.dart'; // Inclui UserDataService e AuthService (VERIFIQUE!)
// Para DataResult (VERIFIQUE CAMINHO)
import 'package:tcc_3/common/data/exceptions.dart'; // Para AuthException (VERIFIQUE CAMINHO)
import 'profile_state.dart';


class ProfileController extends ChangeNotifier {
  // Construtor que recebe os dois serviços
  ProfileController({
    required UserDataService userDataService,
    required AuthService authService,
  })  : _userDataService = userDataService,
        _authService = authService;

  final UserDataService _userDataService;
  final AuthService _authService;

  ProfileState _state = ProfileStateInitial();
  ProfileState get state => _state;

  UserModel get userData => _userDataService.userData;

  // --- Variável _isUploadingPhoto REMOVIDA ---
  // bool _isUploadingPhoto = false;
  // bool get isUploadingPhoto => _isUploadingPhoto;
  // --------------------------------------------

  // Flag para habilitar/desabilitar botão Salvar
  bool _enabledButton = false;
  bool get enabledButton => _enabledButton;

  // Getter 'canSave' simplificado (sem _isUploadingPhoto)
  bool get canSave => enabledButton && state is! ProfileStateLoading;

  void _changeState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }

  // Flags e Getters para controle da UI (mantidos)
  bool _reauthRequired = false;
  bool get reauthRequired => _reauthRequired;
  bool _showUpdatedNameMessage = false;
  bool get showNameUpdateMessage => _showUpdatedNameMessage && state is ProfileStateSuccess;
  bool _showUpdatedPasswordMessage = false;
  bool get showPasswordUpdateMessage => _showUpdatedPasswordMessage && state is ProfileStateSuccess;
  bool _showChangeName = false;
  bool get showChangeName => _showChangeName;
  bool _showChangePassword = false;
  bool get showChangePassword => _showChangePassword;
  // --- Fim Flags e Getters ---

  // Método toggleButtonTap (mantido)
  void toggleButtonTap(bool value) {
    _enabledButton = value;
    notifyListeners();
  }

  // Lógica CORRIGIDA para alternar a visualização dos forms (mantida)
  void onChangeNameTapped() {
    if (_showChangeName) { _showChangeName = false; }
    else { _showChangeName = true; _showChangePassword = false; }
    _changeState(ProfileStateInitial());
    toggleButtonTap(false);
  }

  void onChangePasswordTapped() {
    if (_showChangePassword) { _showChangePassword = false; }
    else { _showChangePassword = true; _showChangeName = false; }
    _changeState(ProfileStateInitial());
    toggleButtonTap(false);
  }

  // Métodos de busca e atualização de dados (mantidos)
  Future<void> getUserData() async {
    if (_state is ProfileStateLoading) return;
    _changeState(ProfileStateLoading());
    final result = await _userDataService.getUserData();
    if (_state is ProfileStateLoading) {
      result.fold(
        (error) => _changeState(ProfileStateError(message: error.message)),
        (data) => _changeState(ProfileStateSuccess(user: data)),
      );
    }
  }

  Future<void> updateUserName(String newUserName) async {
     _changeState(ProfileStateLoading());
     final result = await _userDataService.updateUserName(newUserName);
     result.fold(
       (error) => _changeState(ProfileStateError(message: error.message)),
       (_) {
         _showUpdatedNameMessage = true;
         _showUpdatedPasswordMessage = false;
         onChangeNameTapped();
         toggleButtonTap(false);
         _changeState(ProfileStateSuccess(user: _userDataService.userData));
       },
     );
  }

  Future<void> updateUserPassword(String newPassword) async {
      _changeState(ProfileStateLoading());
      final result = await _userDataService.updatePassword(newPassword);
      result.fold(
        (error) {
          _reauthRequired = false;
          if (error is AuthException && error.code == 'requires-recent-login') {
            _reauthRequired = true;
          }
          _changeState(ProfileStateError(message: error.message));
        },
        (_) {
          _reauthRequired = false;
          _showUpdatedPasswordMessage = true;
          _showUpdatedNameMessage = false;
          onChangePasswordTapped();
          toggleButtonTap(false);
          _changeState(ProfileStateSuccess(user: _userDataService.userData));
        },
      );
  }

  // --- MÉTODO changeProfilePicture REMOVIDO ---
  // Future<void> changeProfilePicture() async { ... }
  // -------------------------------------------

  // Método de Logout (mantido)
  Future<void> logout() async {
      print("--- MÉTODO LOGOUT CHAMADO ---");
      _changeState(ProfileStateLoading());
      try {
        await _authService.signOut();
        print("--- AuthService.signOut() CHAMADO (SEM ERRO) ---");
      } catch (e, s) {
         print("--- ERRO AO CHAMAR AuthService.signOut(): $e ---");
         print(s);
         _changeState(ProfileStateError(message: "Erro ao tentar sair. Tente novamente."));
      }
   }
}