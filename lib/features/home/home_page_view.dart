// lib/features/home/view/home_page_view.dart

import 'package:flutter/material.dart';
// Verifique e ajuste seus imports originais
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/features/goals/views/goals_screen.dart';
import 'package:tcc_3/features/profile/profile_page.dart';
import 'package:tcc_3/features/stats/stats_controller.dart';
import 'package:tcc_3/features/stats/stats_page.dart';
import 'package:tcc_3/features/wallet/wallet_controller.dart';
import 'package:tcc_3/features/wallet/wallet_page.dart';
import 'package:tcc_3/features/tools/view/tools_page.dart';

import '../../../common/constants/constants.dart';
import '../../../common/widgets/custom_bottom_app_bar.dart';
import '../../../locator.dart';
import 'home_controller.dart';
import 'home_page.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  late final PageController _pageController;
  final homeController = locator.get<HomeController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Lógica original de initState (pode ou não ter o sync aqui)
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
          // A chamada de sync pode ter sido adicionada depois, verifique sua versão original
          // locator.get<SyncController>().syncFromServer().catchError((error) { ... });
       }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Código original de reset dos singletons
    locator.resetLazySingleton<HomeController>();
    locator.resetLazySingleton<BalanceController>();
    locator.resetLazySingleton<WalletController>();
    locator.resetLazySingleton<StatsController>();
    super.dispose();
  }

  void _onBottomAppBarItemTap(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final balanceController = locator.get<BalanceController>();
    final statsController = locator.get<StatsController>();
    final walletController = locator.get<WalletController>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // ESTA VERSÃO NÃO TINHA O SAFEAREA AQUI
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: const [
          HomePage(),      // Índice 0
          StatsPage(),     // Índice 1
          GoalsScreen(),   // Índice 2
          ToolsPage(),     // Índice 3
          WalletPage(),    // Índice 4
          ProfilePage(),   // Índice 5
        ],
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_main_view',
        onPressed: () async {
           final result = await Navigator.pushNamed(context, NamedRoute.transaction);
           if (result != null && mounted) {
             print("Atualizando dados após transação..."); // Lógica original de update
             balanceController.getBalances();
             int currentPageIndex = _pageController.page?.round() ?? 0;
             switch (currentPageIndex) {
                case 0: homeController.getLatestTransactions(); break;
                case 1: statsController.getTrasactionsByPeriod(); break;
                case 4: walletController.getTransactionsByDateRange(); break;
             }
           }
         },
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        tooltip: 'Adicionar Transação',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BottomAppBar com os 6 filhos (como estava na Resposta #97 / #89)
      bottomNavigationBar: CustomBottomAppBar(
        controller: _pageController,
        selectedItemColor: AppColors.green,
        children: [
          // Item 1 (Home)
          CustomBottomAppBarItem( key: Keys.homePageBottomAppBarItem, label: 'Início', primaryIcon: Icons.home, secondaryIcon: Icons.home_outlined, onPressed: () => _onBottomAppBarItemTap(0), ),
          // Item 2 (Stats)
          CustomBottomAppBarItem( key: Keys.statsPageBottomAppBarItem, label: 'Gráficos', primaryIcon: Icons.analytics, secondaryIcon: Icons.analytics_outlined, onPressed: () => _onBottomAppBarItemTap(1), ),
          // Item 3 (Goals)
          CustomBottomAppBarItem( label: 'Metas', primaryIcon: Icons.savings, secondaryIcon: Icons.savings_outlined, onPressed: () => _onBottomAppBarItemTap(2), ),
          // Item 4 (Tools)
          CustomBottomAppBarItem( label: 'Ferramentas', primaryIcon: Icons.construction, secondaryIcon: Icons.construction_outlined, onPressed: () => _onBottomAppBarItemTap(3), ),
          // Item 5 (Wallet)
          CustomBottomAppBarItem( key: Keys.walletPageBottomAppBarItem, label: 'Carteira', primaryIcon: Icons.account_balance_wallet, secondaryIcon: Icons.account_balance_wallet_outlined, onPressed: () => _onBottomAppBarItemTap(4), ),
          // Item 6 (Profile)
          CustomBottomAppBarItem( key: Keys.profilePageBottomAppBarItem, label: 'Perfil', primaryIcon: Icons.person, secondaryIcon: Icons.person_outline, onPressed: () => _onBottomAppBarItemTap(5), ),
        ],
      ),
    );
  }
}