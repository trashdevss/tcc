import 'package:flutter/material.dart';
import 'package:tcc_3/profile/profile_page.dart';
import 'package:tcc_3/wallet/wallet_controller.dart';
import 'package:tcc_3/wallet/wallet_page.dart';
import '../../common/constants/app_colors.dart';
import '../../common/widgets/custom_bottom_app_bar.dart';
import '../../locator.dart';
import '../stats/stats_page.dart';
import 'home_controller.dart';
import 'home_page.dart';
import 'widgets/balance_card/balance_card_widget_controller.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  late final HomeController homeController;
  late final BalanceCardWidgetController balanceCardWidgetController;
  late final WalletController walletController;

  @override
  void initState() {
    super.initState();
    homeController = locator.get<HomeController>();
    balanceCardWidgetController = locator.get<BalanceCardWidgetController>();
    walletController = locator.get<WalletController>();

    homeController.setPageController = PageController();
  }

  @override
  void dispose() {
    homeController.pageController.dispose();
    // ❌ REMOVIDO: Não resetar os singletons
    super.dispose();
  }

  Future<void> _navigateToTransactionPage() async {
    final result = await Navigator.pushNamed(context, '/transaction');
    if (result == true) {
      await homeController.getLatestTransactions();
      await balanceCardWidgetController.getBalances();
      await walletController.getAllTransactions();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: homeController.pageController,
        children: const [
          HomePage(),
          StatsPage(),
          WalletPage(),
          ProfilePage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTransactionPage,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomAppBar(
        controller: homeController.pageController,
        selectedItemColor: AppColors.green,
        children: [
          CustomBottomAppBarItem(
            label: 'home',
            primaryIcon: Icons.home,
            secondaryIcon: Icons.home_outlined,
            onPressed: () => homeController.pageController.jumpToPage(0),
          ),
          CustomBottomAppBarItem(
            label: 'stats',
            primaryIcon: Icons.analytics,
            secondaryIcon: Icons.analytics_outlined,
            onPressed: () => homeController.pageController.jumpToPage(1),
          ),
          CustomBottomAppBarItem.empty(),
          CustomBottomAppBarItem(
            label: 'wallet',
            primaryIcon: Icons.account_balance_wallet,
            secondaryIcon: Icons.account_balance_wallet_outlined,
            onPressed: () => homeController.pageController.jumpToPage(2),
          ),
          CustomBottomAppBarItem(
            label: 'profile',
            primaryIcon: Icons.person,
            secondaryIcon: Icons.person_outline,
            onPressed: () => homeController.pageController.jumpToPage(3),
          ),
        ],
      ),
    );
  }
}
