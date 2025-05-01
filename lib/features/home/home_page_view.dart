import 'package:flutter/material.dart';
// Imports existentes (verifique os caminhos)
import 'package:tcc_3/common/extensions/page_controller_ext.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/features/ferramentas/tools_page.dart';
import 'package:tcc_3/features/metas/goals_screen.dart';
import '../../common/constants/constants.dart'; // Ex: AppColors, Keys, BottomAppBarItem
import '../../common/widgets/widgets.dart'; // Ex: CustomBottomAppBar, CustomBottomAppBarItem
import '../../locator.dart';
import '../profile/profile_page.dart'; // Ajustado para ProfilePage (verifique o nome)
import '../stats/stats_controller.dart';
import '../stats/stats_page.dart';     // Página para "Metas"?
import '../wallet/wallet_page.dart';   // Página para "Carteira"? Ajustado para WalletPage
import '../wallet/wallet_controller.dart';// Import WalletController
import 'home_controller.dart';
import 'home_page.dart';               // Página para "Início"

// --- Imports para as NOVAS páginas (CRIE ESTES ARQUIVOS/WIDGETS) ---

// Presumo que BottomAppBarItem venha daqui ou de outro lugar central
// import '../../common/constants/bottom_app_bar_item.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  // Controllers obtidos via locator
  final homeController = locator.get<HomeController>();
  final walletController = locator.get<WalletController>();
  final balanceController = locator.get<BalanceController>();
  final statsController = locator.get<StatsController>();
  // Adicione controllers para Graficos e Ferramentas se necessário
  // final graficosController = locator.get<GraficosController>();
  // final ferramentasController = locator.get<FerramentasController>();

  @override
  void initState() {
    super.initState();
    final pageController = PageController();
    homeController.setPageController = pageController;
    // Carregar dados iniciais aqui, se necessário
  }

  @override
  void dispose() {
    homeController.pageController.dispose();
    locator.resetLazySingleton<HomeController>();
    locator.resetLazySingleton<BalanceController>();
    locator.resetLazySingleton<WalletController>();
    locator.resetLazySingleton<StatsController>();
    // Resetar outros controllers se adicionados
    // locator.resetLazySingleton<GraficosController>();
    // locator.resetLazySingleton<FerramentasController>();
    // locator.resetLazySingleton<TransactionController>(); // Verifique a necessidade
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // --- PageView com 6 páginas ---
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: homeController.pageController,
        children: const [
           HomePage(),      // Índice 0: Início
        StatsPage(),     // Índice 1: Gráficos (Correto)
        GoalsScreen(),   // <<<--- Índice 2: ALTERADO para GoalsScreen (Metas)
        WalletPage(),    // Índice 3: Carteira
        ToolsPage(),     // Índice 4: Ferramentas
        ProfilePage(),     // Índice 5: Perfil
        ],
      ),
      // --- Botão Flutuante ---
      floatingActionButton: FloatingActionButton(
          heroTag: 'fab_main_transaction', // <<< TAG ÚNICA 1
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/transaction');
          if (result != null) {
            final currentPageIndex = homeController.pageController.page?.round() ?? 0;
            // Atualizar dados da página específica, se necessário
            switch (currentPageIndex) {
              case 0: // Início
                homeController.getLatestTransactions();
                break;
              case 1: // Gráficos
                // graficosController.reloadData(); // Exemplo
                break;
              case 2: // Metas (StatsPage?)
                statsController.getTrasactionsByPeriod(); // Exemplo
                break;
              case 3: // Carteira (WalletPage?)
                walletController.getTransactionsByDateRange(); // Exemplo
                break;
              case 4: // Ferramentas
                // ferramentasController.reloadData(); // Exemplo
                break;
              // Case 5 (Perfil) geralmente não precisa
            }
            // Atualizar saldos gerais
            balanceController.getBalances();
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // --- Barra de Navegação Inferior com 6 itens ---
      bottomNavigationBar: CustomBottomAppBar(
        controller: homeController.pageController,
        selectedItemColor: AppColors.green, // Certifique-se que AppColors está OK
        children: [
          // Item 1: Início (Índice 0)
          CustomBottomAppBarItem(
            // key: Keys.homePageBottomAppBarItem, // Use suas Keys
            label: "Início",
            primaryIcon: Icons.home,
            secondaryIcon: Icons.home_outlined,
            onPressed: () => homeController.pageController.navigateTo(
              BottomAppBarItem.home, // Precisa existir e mapear para índice 0
            ),
          ),
          // Item 2: Gráficos (Índice 1 - NOVO)
          CustomBottomAppBarItem(
            // key: Keys.graficosPageBottomAppBarItem, // Nova Key
            label: "Gráficos",
            primaryIcon: Icons.bar_chart,
            secondaryIcon: Icons.bar_chart_outlined,
            onPressed: () => homeController.pageController.navigateTo(
              BottomAppBarItem.graficos, // Precisa existir e mapear para índice 1
            ),
          ),
          // Item 3: Metas (Índice 2)
          CustomBottomAppBarItem(
            // key: Keys.statsPageBottomAppBarItem, // Key original de stats?
            label: "Metas",
            primaryIcon: Icons.savings, // Ícone de cofrinho
            secondaryIcon: Icons.savings_outlined,
            onPressed: () => homeController.pageController.navigateTo(
              BottomAppBarItem.metas, // Precisa existir (ou ser .stats renomeado) e mapear para índice 2
            ),
          ),
          // Item Vazio para o FAB
          CustomBottomAppBarItem.empty(),
          // Item 4: Carteira (Índice 3)
          CustomBottomAppBarItem(
            // key: Keys.walletPageBottomAppBarItem, // Key original de wallet?
            label: "Carteira", // Texto ajustado
            primaryIcon: Icons.account_balance_wallet, // Ícone de carteira
            secondaryIcon: Icons.account_balance_wallet_outlined,
            onPressed: () => homeController.pageController.navigateTo(
              BottomAppBarItem.wallet, // Precisa existir e mapear para índice 3
            ),
          ),
          // Item 5: Ferramentas (Índice 4 - NOVO)
          CustomBottomAppBarItem(
            // key: Keys.ferramentasPageBottomAppBarItem, // Nova Key
            label: "Ferramentas",
            primaryIcon: Icons.build, // Ícone de ferramentas
            secondaryIcon: Icons.build_outlined,
            onPressed: () => homeController.pageController.navigateTo(
              BottomAppBarItem.ferramentas, // Precisa existir e mapear para índice 4
            ),
          ),
          // Item 6: Perfil (Índice 5)
          CustomBottomAppBarItem(
            // key: Keys.profilePageBottomAppBarItem, // Key original de profile?
            label: "Perfil",
            primaryIcon: Icons.person,
            secondaryIcon: Icons.person_outline,
            onPressed: () => homeController.pageController.navigateTo(
              BottomAppBarItem.profile, // Precisa existir e mapear para índice 5
            ),
          ),
        ],
      ),
    );
  }
}

// === PLACEHOLDERS (CRIE OS ARQUIVOS REAIS) ===

// Exemplo: ../graficos/graficos_page.dart
class GraficosPage extends StatelessWidget {
  const GraficosPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Página de Gráficos'));
  }
}

// Exemplo: ../ferramentas/ferramentas_page.dart
class FerramentasPage extends StatelessWidget {
  const FerramentasPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Página de Ferramentas'));
  }
}

// === Notas Importantes ===
// 1. CRIE os arquivos `graficos_page.dart` e `ferramentas_page.dart` (ou com os nomes que preferir)
//    e importe-os corretamente no topo do `home_page_view.dart`.
// 2. DEFINA/AJUSTE seu enum/classe `BottomAppBarItem` para incluir `.graficos` e `.ferramentas`,
//    e garanta que os valores (`.home`, `.graficos`, `.metas`, `.wallet`, `.ferramentas`, `.profile`)
//    estejam corretamente mapeados para a ordem das páginas no `PageView` e usados nos `onPressed`.
// 3. VERIFIQUE se `StatsPage` deve mesmo ser usada para "Metas" e `WalletPage` para "Carteira",
//    e se os `BottomAppBarItem` correspondentes (`.metas`, `.wallet`) estão corretos.
// 4. CONFIRME os ícones (`Icons.bar_chart`, `Icons.savings`, `Icons.build`, etc.).
// 5. ADICIONE controllers e lógica de atualização no FAB para as novas páginas, se necessário.