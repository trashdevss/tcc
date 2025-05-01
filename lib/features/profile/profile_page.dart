// lib/features/profile/profile_page.dart
import 'package:flutter/material.dart';
// Seus imports (VERIFIQUE)
// import 'package:tcc_3/common/extensions/extensions.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // <<< Não usado nesta versão
import '../../common/constants/constants.dart'; // VERIFIQUE
import '../../common/widgets/widgets.dart'; // VERIFIQUE (AppHeader, etc.)
import '../../locator.dart'; // VERIFIQUE
import '../../services/services.dart'; // VERIFIQUE (SyncController)
// Importe seus mixins se já usava
// import '../../common/mixins/custom_modal_sheet_mixin.dart';
// import '../../common/mixins/custom_snackbar_mixin.dart';

import 'profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// Adapte os mixins se já usava
class _ProfilePageState extends State<ProfilePage> /* with CustomModalSheetMixin, CustomSnackBar */ {
  final _profileController = locator.get<ProfileController>();
  final _syncController = locator.get<SyncController>(); // Se já usava

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) => Sizes.init(context)); // Se usava
    _profileController.getUserData(); // Pedia para buscar dados
    // Adicionava listeners se já usava
    // _profileController.addListener(_handleProfileStateChange);
    // _syncController.addListener(_handleSyncStateChange);
  }

  @override
  void dispose() {
    // Removia listeners se adicionados
    // _profileController.removeListener(_handleProfileStateChange);
    // _syncController.removeListener(_handleSyncStateChange);
    // _profileController.dispose(); // Chamava dispose? Era Factory
    // _syncController.dispose(); // Chamava dispose? Era Factory
    super.dispose();
  }

  // Handlers vazios ou como estavam antes
  // void _handleProfileStateChange() { /* ... seu código antigo ... */ }
  // void _handleSyncStateChange() async { /* ... seu código antigo ... */ }

  // Função de placeholder para foto
  void _changeProfilePicture() {
    print("DEBUG: Botão Alterar Foto clicado! (Funcionalidade não implementada)");
    // Mostrava um Snackbar talvez?
    // ScaffoldMessenger.of(context).showSnackBar(
    //    const SnackBar(content: Text('Funcionalidade indisponível.'))
    // );
  }

  @override
  Widget build(BuildContext context) {
    // Sem ListenableBuilder envolvendo tudo
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Usava AppHeader? Adapte o child/ausência dele conforme o original
          const AppHeader( title: 'Profile', /* child: ...? */ ),

          Positioned.fill(
            // Usava este valor de top?
            top: 130, // Sem .h se ScreenUtil não estava inicializado/usado aqui
            child: SingleChildScrollView(
              // Usava este padding?
              padding: EdgeInsets.only(bottom: 100), // Sem .h
              child: Column(
                children: [
                  // --- SEÇÃO DO AVATAR ORIGINAL ---
                   SizedBox( // Usava SizedBox?
                     width: 125, height: 125, // Sem .h
                     child: Stack(
                       alignment: Alignment.center,
                       children: [
                         // Avatar Simples (sem CachedNetworkImage?)
                         CircleAvatar(
                           radius: 60, // Sem .h
                           backgroundColor: AppColors.grey.withOpacity(0.2),
                           // backgroundImage: NetworkImage(_profileController.userData.profilePictureUrl ?? ''), // Tentativa simples?
                           child: _profileController.userData.profilePictureUrl == null
                               ? Icon( Icons.person_outline, size: 60, color: AppColors.grey,) // Sem .h
                               : null, // Ou mostrava a imagem de outra forma
                         ),
                         // Botão de Edição Sobreposto
                         Positioned(
                           bottom: 0, right: 0,
                           child: CircleAvatar(
                             radius: 20, // Sem .h
                             backgroundColor: Theme.of(context).primaryColor,
                             child: IconButton(
                               icon: Icon(Icons.camera_alt, color: Colors.white, size: 20), // Sem .h
                               onPressed: _changeProfilePicture, // Chamava a função placeholder
                               tooltip: 'Alterar Foto',
                             ),
                           ),
                         )
                       ],
                     ),
                   ),
                  // --- FIM AVATAR ORIGINAL ---

                  SizedBox(height: 20), // Sem .h

                  // Nome e Email (usava AnimatedBuilder?)
                  AnimatedBuilder(
                    animation: _profileController, // Assumindo que usava isso
                    builder: (context, child) {
                      // Lógica de loading original
                      // if (_profileController.state is ProfileStateLoading) {
                      //   return const CustomCircularProgressIndicator(color: AppColors.green);
                      // }
                      return Column(
                        children: [
                          Text(
                            (_profileController.userData.name ?? 'Carregando...'), // .capitalize() se tinha a extensão
                            style: AppTextStyles.mediumText20, // Estilo original
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4), // Sem .h
                          Text(
                            _profileController.userData.email ?? 'Carregando...',
                            style: AppTextStyles.smallText.apply(color: AppColors.green), // Estilo original
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 40), // Sem .h

                  // Opções (TextButton.icon originais)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: ListenableBuilder( // Ou AnimatedBuilder que usava
                      listenable: _profileController,
                      builder: (context, child) {
                        // Usava AnimatedSwitcher?
                        // return AnimatedSwitcher( ... child: ... );
                        // Ou mostrava direto a Column?
                        // Coloque aqui a estrutura exata que você tinha ANTES de introduzir ListTile
                        // Se era o AnimatedSwitcher, ele precisa das condições originais
                        // if (_profileController.showChangeName) ... else if (_profileController.showChangePassword) ... else Column(...)
                        return Column( // Exemplo SIMPLES - Adapte à sua estrutura original
                          key: const ValueKey('profile-options'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             TextButton.icon(
                               onPressed: () { _profileController.onChangeNameTapped(); }, // Chamava o método antigo
                               icon: const Icon( Icons.person, color: AppColors.green, ),
                               label: Align( alignment: Alignment.centerLeft, child: Text( 'Change name', style: AppTextStyles.mediumText16w500.apply(color: AppColors.green), textAlign: TextAlign.start, ), ),
                             ),
                             TextButton.icon(
                               onPressed: () { _profileController.onChangePasswordTapped(); }, // Chamava o método antigo
                               icon: const Icon( Icons.lock_person_rounded, color: AppColors.green, ),
                               label: Align( alignment: Alignment.centerLeft, child: Text( 'Change password', style: AppTextStyles.mediumText16w500.apply(color: AppColors.green), textAlign: TextAlign.start, ), ),
                             ),
                             TextButton.icon(
                               onPressed: () { _syncController.syncFromServer(); }, // Chamava sync direto?
                               icon: const Icon( Icons.logout_outlined, color: AppColors.green, ),
                               label: Align( alignment: Alignment.centerLeft, child: Text( 'Logout', style: AppTextStyles.mediumText16w500.apply(color: AppColors.green), textAlign: TextAlign.start, ), ),
                             ),
                          ],
                        );
                      }
                    ),
                  ),
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }
}