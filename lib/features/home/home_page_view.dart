import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para MethodChannel
import 'dart:async'; // Para Future.delayed (se necessário)

// Imports existentes (verifique os caminhos)
import 'package:tcc_3/common/extensions/page_controller_ext.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/features/ferramentas/tools_page.dart';
import 'package:tcc_3/features/metas/goals_screen.dart';
import '../../common/constants/constants.dart';
import '../../common/widgets/widgets.dart';
import '../../locator.dart';
import '../profile/profile_page.dart';
import '../stats/stats_controller.dart';
import '../stats/stats_page.dart';
import '../wallet/wallet_page.dart';
import '../wallet/wallet_controller.dart';
import 'home_controller.dart'; // Seu HomeController
import 'home_page.dart' as AppHomePage; // Renomeado para evitar conflito de nome com a classe

// +++ IMPORT DO SERVIÇO DE NOTIFICAÇÃO +++
import 'package:tcc_3/services/data_service/jove_notification_service.dart'; // Ajuste o caminho

// +++ CLASSE NotificationUtils (COPIADA AQUI PARA EXEMPLO) +++
// No seu projeto, esta classe deve estar em um arquivo utilitário e importada.
class NotificationUtils {
  static const MethodChannel _methodChannel =
      MethodChannel('dev.gab.tcc/notifications_utils');

  static Future<bool> isNotificationServiceEnabled() async {
    try {
      final bool? isEnabled =
          await _methodChannel.invokeMethod('isNotificationServiceEnabled');
      debugPrint("[NotificationUtils] isNotificationServiceEnabled retornou $isEnabled");
      return isEnabled ?? false;
    } on PlatformException catch (e) {
      debugPrint("[NotificationUtils] Erro ao verificar serviço: ${e.message}");
      return false;
    }
  }

  static Future<void> requestNotificationPermissionScreen() async {
    try {
      debugPrint("[NotificationUtils] Enviando chamada requestNotificationPermissionScreen para o nativo...");
      await _methodChannel
          .invokeMethod('requestNotificationPermissionScreen');
      debugPrint("[NotificationUtils] Chamada para requestNotificationPermissionScreen enviada.");
    } on PlatformException catch (e) {
      debugPrint("[NotificationUtils] Erro ao solicitar tela de permissão: ${e.message}");
    }
  }
}
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> with WidgetsBindingObserver {
  final homeController = locator.get<HomeController>();
  final walletController = locator.get<WalletController>();
  final balanceController = locator.get<BalanceController>();
  final statsController = locator.get<StatsController>();
  
  final JoveNotificationService _joveNotificationService = JoveNotificationService();
  
  bool _isLoadingNotificationPermission = true;
  bool _hasNotificationPermission = false;
  // bool _userDeclinedPermissionPreviously = false; // Opcional: para não mostrar o diálogo toda vez

  @override
  void initState() {
    super.initState();
    debugPrint("[HomePageView] initState");
    WidgetsBinding.instance.addObserver(this);

    final pageController = PageController();
    homeController.setPageController = pageController;

    // Adia a verificação de permissão para após o primeiro frame ser construído
    // para permitir que a UI mostre um estado de carregamento, se desejado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestInitialNotificationPermission();
    });
  }

  @override
  void dispose() {
    debugPrint("[HomePageView] dispose");
    WidgetsBinding.instance.removeObserver(this);
    homeController.pageController.dispose();
    locator.resetLazySingleton<HomeController>();
    locator.resetLazySingleton<BalanceController>();
    locator.resetLazySingleton<WalletController>();
    locator.resetLazySingleton<StatsController>();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint("[HomePageView] didChangeAppLifecycleState: $state");
    if (state == AppLifecycleState.resumed) {
      debugPrint("[HomePageView] App resumido. Re-verificando permissão de notificação.");
      // Re-verifica a permissão, pois o usuário pode tê-la alterado
      // Não mostra o diálogo automaticamente ao resumir, apenas atualiza o status.
      // O usuário pode clicar no botão se quiser tentar novamente.
      _updatePermissionStatus();
    }
  }

  // Novo método para apenas atualizar o status da permissão sem solicitar automaticamente
  Future<void> _updatePermissionStatus() async {
    if (!mounted) return;
    bool isEnabled = await NotificationUtils.isNotificationServiceEnabled();
    if (!mounted) return;
    setState(() {
      _hasNotificationPermission = isEnabled;
      _isLoadingNotificationPermission = false; // Assume que a verificação terminou
    });
    if (isEnabled) {
      await _joveNotificationService.startService();
    }
  }


  Future<void> _showPermissionRationaleDialog() async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Usuário deve interagir com o diálogo
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Acesso às Notificações'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Para que possamos capturar suas transações financeiras automaticamente de aplicativos como PicPay, precisamos de acesso às suas notificações.'),
                SizedBox(height: 8),
                Text('Seus dados de notificação são processados localmente no seu dispositivo para sua privacidade e segurança.'),
                SizedBox(height: 8),
                Text('Você pode revogar essa permissão a qualquer momento nas configurações do seu celular.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Agora não'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Opcional: setState(() { _userDeclinedPermissionPreviously = true; });
              },
            ),
            TextButton(
              child: const Text('Entendi, permitir'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo de explicação
                NotificationUtils.requestNotificationPermissionScreen(); // Abre as configurações do sistema
                // O status será re-verificado em didChangeAppLifecycleState quando o usuário voltar
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndRequestInitialNotificationPermission({bool isResuming = false}) async {
    if (!mounted) return;

    if (!isResuming && !_hasNotificationPermission) {
      setState(() {
        _isLoadingNotificationPermission = true;
      });
    }

    bool isEnabled = await NotificationUtils.isNotificationServiceEnabled();
    debugPrint("[HomePageView] Permissão de notificação habilitada (via MethodChannel): $isEnabled");

    if (!mounted) return;

    if (isEnabled) {
      setState(() {
        _hasNotificationPermission = true;
        _isLoadingNotificationPermission = false;
      });
      debugPrint("[HomePageView] Permissão de notificação concedida. Iniciando JoveNotificationService...");
      await _joveNotificationService.startService();
    } else {
      setState(() {
        _hasNotificationPermission = false;
        _isLoadingNotificationPermission = false;
      });
      // Se não estiver apenas resumindo (primeira vez ou clique explícito) E o usuário ainda não recusou
      // if (!isResuming && !_userDeclinedPermissionPreviously) { // Lógica opcional para não mostrar sempre
      if (!isResuming) { // Mostra o diálogo de explicação
        debugPrint("[HomePageView] Permissão de notificação NÃO concedida. Mostrando diálogo de explicação...");
        await _showPermissionRationaleDialog();
      } else {
        debugPrint("[HomePageView] Permissão de notificação ainda não concedida (ao resumir ou após diálogo).");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[HomePageView] build. Permissão carregada: ${!_isLoadingNotificationPermission}, Concedida: $_hasNotificationPermission");
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack( // Usar Stack para poder sobrepor o diálogo de carregamento inicial
        children: [
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: homeController.pageController,
            children: const [
              AppHomePage.HomePage(), 
              StatsPage(),      
              GoalsScreen(),    
              WalletPage(),     
              ToolsPage(),      
              ProfilePage(),    
            ],
          ),
          // Mostrar um overlay de carregamento se _isLoadingNotificationPermission for true
          // e a permissão ainda não foi concedida (para evitar mostrar sobre a UI principal desnecessariamente)
          if (_isLoadingNotificationPermission && !_hasNotificationPermission)
            Container(
              color: Colors.black.withOpacity(0.1), // Fundo semi-transparente
              child: const Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Verificando permissões..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          heroTag: 'fab_main_transaction',
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/transaction');
            if (result != null) {
              final currentPageIndex = homeController.pageController.page?.round() ?? 0;
              switch (currentPageIndex) {
                case 0: homeController.getLatestTransactions(); break;
                case 2: statsController.getTrasactionsByPeriod(); break;
                case 3: walletController.getTransactionsByDateRange(); break;
              }
              balanceController.getBalances();
            }
          },
          child: const Icon(Icons.add),
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomAppBar(
        controller: homeController.pageController,
        selectedItemColor: AppColors.green,
        children: [
          CustomBottomAppBarItem(
            label: "Início", primaryIcon: Icons.home, secondaryIcon: Icons.home_outlined,
            onPressed: () => homeController.pageController.navigateTo(BottomAppBarItem.home),
          ),
          CustomBottomAppBarItem(
            label: "Gráficos", primaryIcon: Icons.bar_chart, secondaryIcon: Icons.bar_chart_outlined,
            onPressed: () => homeController.pageController.navigateTo(BottomAppBarItem.graficos),
          ),
          CustomBottomAppBarItem(
            label: "Metas", primaryIcon: Icons.savings, secondaryIcon: Icons.savings_outlined,
            onPressed: () => homeController.pageController.navigateTo(BottomAppBarItem.metas),
          ),
          CustomBottomAppBarItem.empty(),
          CustomBottomAppBarItem(
            label: "Carteira", primaryIcon: Icons.account_balance_wallet, secondaryIcon: Icons.account_balance_wallet_outlined,
            onPressed: () => homeController.pageController.navigateTo(BottomAppBarItem.wallet),
          ),
          CustomBottomAppBarItem(
            label: "Ferramentas", primaryIcon: Icons.build, secondaryIcon: Icons.build_outlined,
            onPressed: () => homeController.pageController.navigateTo(BottomAppBarItem.ferramentas),
          ),
          CustomBottomAppBarItem(
            label: "Perfil", primaryIcon: Icons.person, secondaryIcon: Icons.person_outline,
            onPressed: () => homeController.pageController.navigateTo(BottomAppBarItem.profile),
          ),
        ],
      ),
    );
  }
}
