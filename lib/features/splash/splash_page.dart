// lib/features/splash/splash_page.dart

import 'package:flutter/material.dart';
// Seus imports originais (VERIFIQUE OS CAMINHOS)
import 'package:tcc_3/services/sync_services/sync_controller.dart';
import 'package:tcc_3/services/sync_services/sync_state.dart';
import '../../common/constants/constants.dart'; // Para NamedRoute, AppColors, AppTextStyles, Sizes?
// Para .h/.w ?
import '../../common/widgets/widgets.dart'; // Para CustomCircularProgressIndicator, CustomModalSheetMixin?
import '../../locator.dart';
import 'splash_controller.dart';
import 'splash_state.dart';
// Importe o mixin CustomSnackBar se já usava aqui
// import '../../common/mixins/custom_snackbar_mixin.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

// Verifique se os mixins corretos estavam aqui
class _SplashPageState extends State<SplashPage> with CustomModalSheetMixin /*, CustomSnackBar? */ {
  // Controllers obtidos via locator
  final _splashController = locator.get<SplashController>();
  final _syncController = locator.get<SyncController>();

  @override
  void initState() {
    super.initState();

    // Inicialização de Sizes (pode causar erro se context for inválido depois)
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Verificava se estava montado aqui?
       // if(mounted) { Sizes.init(context); }
       // Ou talvez a chamada original fosse diferente
    });

    // Lógica original de verificação e adição de listeners
    _splashController.isUserLogged();
    _splashController.addListener(_handleSplashStateChange);
    _syncController.addListener(_handleSyncStateChange);
  }

  @override
  void dispose() {
    // Dispose original dos controllers obtidos via locator (pode ser problemático)
    // E remoção dos listeners
    _splashController.removeListener(_handleSplashStateChange);
    _syncController.removeListener(_handleSyncStateChange);
    _splashController.dispose(); // Chamava dispose? Era Factory.
    _syncController.dispose();   // Chamava dispose? Era Factory.
    super.dispose();
  }

  // Lógica original de navegação baseada no estado do Splash
  void _handleSplashStateChange() {
    // Certifique-se de verificar se está montado antes de usar context/navigator
    if (!mounted) return;

    if (_splashController.state is AuthenticatedUser) {
      // Se autenticado, iniciava o sync
      _syncController.syncFromServer();
    } else {
      // Se não autenticado, ia para Onboarding/Login
      Navigator.pushReplacementNamed(
        context,
        NamedRoute.initial, // Rota de Onboarding ou Login
      );
    }
  }

  // Lógica original de navegação baseada no estado do Sync
  void _handleSyncStateChange() {
     // Certifique-se de verificar se está montado antes de usar context/navigator
    if (!mounted) return;

    final state = _syncController.state;

    switch (state.runtimeType) {
      case DownloadedDataFromServer:
        _syncController.syncToServer(); // Inicia upload após download
        break;
      case UploadedDataToServer:
        // Navega para Home APÓS sync completo
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.home,
          (route) => false,
        );
        break;
      case SyncStateError: // Estado de erro genérico (se você tiver)
      case UploadDataToServerError:
      case DownloadDataFromServerError:
        // Mostra modal em caso de erro de sync
        // Use o nome correto do seu estado de erro se for diferente
        final errorMessage = state is SyncStateError ? state.message : "Erro de sincronização";
        showCustomModalBottomSheet(
          context: context,
          content: errorMessage,
          buttonText: 'Go to login', // Ou 'Tentar Novamente'?
          isDismissible: false, // Não deixava fechar sem clicar no botão
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.initial, // Ia para Onboarding/Login em caso de erro
            (route) => false,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI original da Splash Page
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.greenGradient, // Suas cores
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'financy', // Seu texto
              style: AppTextStyles.bigText50.copyWith(color: AppColors.white), // Seu estilo
            ),
            Text(
              'Syncing data...', // Seu texto
              style: AppTextStyles.smallText13.copyWith(color: AppColors.white), // Seu estilo
            ),
            const SizedBox(height: 16.0),
            // Seu indicador de progresso (verifique o nome e parâmetros originais)
            const CustomCircularProgressIndicator(color: AppColors.white),
          ],
        ),
      ),
    );
  }
}