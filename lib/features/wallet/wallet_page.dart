import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Certifique-se de ter o pacote intl
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/features/balance_state.dart';
import 'package:tcc_3/common/models/transaction_model.dart';

// Adapte os imports para a estrutura real do seu projeto
import '../../common/constants/constants.dart'; // Exemplo: AppColors, AppTextStyles
import '../../common/extensions/extensions.dart'; // Exemplo: context.h, num.h
import '../../common/widgets/widgets.dart'; // Exemplo: AppHeader, BasePage, CustomModalSheetMixin, TransactionListView, CustomCircularProgressIndicator, etc.
import '../../locator.dart';
import '../home/home_controller.dart'; // Para navegação
import 'wallet_controller.dart';
import 'wallet_state.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with TickerProviderStateMixin, CustomModalSheetMixin {
  // --- Controllers ---
  final _balanceController = locator.get<BalanceController>();
  final _walletController = locator.get<WalletController>();
  final _homeController = locator.get<HomeController>(); // Para navegação

  // --- Tab Controllers ---
  late final TabController _optionsTabController;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _optionsTabController = TabController(
      length: 2, // "Transactions", "Upcoming Bills"
      vsync: this,
    );

    _walletController.getTransactionsByDateRange();
    _balanceController.getBalances();

    _walletController.addListener(_handleWalletStateChange);
    _optionsTabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _optionsTabController.removeListener(_handleTabChange);
    _optionsTabController.dispose();
    _walletController.removeListener(_handleWalletStateChange);
    super.dispose();
  }

  // --- State Handlers ---
  void _handleWalletStateChange() {
    final state = _walletController.state;
    switch (state.runtimeType) {
      case WalletStateError:
        if (!mounted) return;
        showCustomModalBottomSheet(
          context: context,
          content: (state as WalletStateError).message,
          buttonText: 'Go to login',
          isDismissible: false,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.initial,
            (route) => false,
          ),
        );
        break;
      case WalletStateLoading:
      case WalletStateSuccess:
        if (mounted) {
          // setState(() {}); // Geralmente não necessário
        }
        break;
    }
  }

   void _handleTabChange() {
     // Apenas para atualizar a aparência das abas via StatefulBuilder,
     // o AnimatedBuilder da lista já escuta o controller.
     // Se precisar forçar rebuild por causa da aba, descomente setState.
     // setState(() {});
   }

  // --- Navigation Methods ---
  void _goToPreviousMonth() {
    final selectedDate = _walletController.selectedDate;
    _walletController.changeSelectedDate(
        DateTime(selectedDate.year, selectedDate.month - 1));
    _walletController.getTransactionsByDateRange();
  }

  void _goToNextMonth() {
    final selectedDate = _walletController.selectedDate;
    _walletController.changeSelectedDate(
        DateTime(selectedDate.year, selectedDate.month + 1));
    _walletController.getTransactionsByDateRange();
  }

  Future<bool> _onWillPop() async {
    _homeController.pageController.navigateTo(BottomAppBarItem.home);
    return false;
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          // --- Header ---
          AppHeader(
            title: 'Wallet',
            onPressed: () =>
                _homeController.pageController.navigateTo(BottomAppBarItem.home),
          ),
          // --- Page Content ---
          Positioned(
            left: 0,
            right: 0,
            top: 120.h, // Ajuste conforme necessário
            bottom: 0,
            child: BasePage(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Seção do Saldo Total ---
                    Center(
                      child: Text(
                        'Total Balance',
                        style: AppTextStyles.inputLabelText.apply(color: AppColors.grey),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Center(
                      child: AnimatedBuilder(
                          animation: _balanceController,
                          builder: (context, _) {
                            if (_balanceController.state is BalanceStateLoading) {
                              return const SizedBox(
                                height: 36, // Mesmo tamanho do texto de saldo
                                child: Center(child: CustomCircularProgressIndicator())
                              );
                            }
                            if (_balanceController.state is BalanceStateError) {
                              return Text(
                                'Error',
                                style: AppTextStyles.mediumText30.apply(color: AppColors.outcome),
                              );
                            }
                            final formattedBalance = NumberFormat.currency(
                              locale: 'en_US', // Ou 'pt_BR'
                              symbol: '\$ ',   // Ou 'R\$ '
                            ).format(_balanceController.balances.totalBalance);
                            return Text(
                              formattedBalance,
                              style: AppTextStyles.mediumText30.apply(color: AppColors.blackGrey),
                            );
                          }),
                    ),
                    const SizedBox(height: 24.0),

                    // --- Abas de Opções (Transactions / Upcoming Bills) ---
                    StatefulBuilder(
                      builder: (context, setTabState) {
                        return TabBar(
                          controller: _optionsTabController,
                          labelPadding: EdgeInsets.zero,
                          indicator: const BoxDecoration(),
                          indicatorSize: TabBarIndicatorSize.tab,
                          onTap: (index) {
                            // Apenas redesenha as abas para mudar a aparência ativa/inativa
                            setTabState(() {});
                          },
                          tabs: [
                            _buildFilterTab(context, 'Transactions', 0),
                            _buildFilterTab(context, 'Upcoming Bills', 1),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32.0),

                    // --- Seção de Navegação de Mês ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: AppColors.green,
                          onPressed: _goToPreviousMonth,
                        ),
                        AnimatedBuilder(
                          animation: _walletController,
                          builder: (context, _) => Text(
                            DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
                                .format(_walletController.selectedDate),
                            style: AppTextStyles.mediumText16w600.apply(
                              color: AppColors.green,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_outlined),
                          color: AppColors.green,
                          onPressed: _goToNextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0), // Espaço antes da lista

                    // --- Lista de Transações (Ocupa o espaço restante) ---
                    Expanded(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _walletController, // Escuta mudanças de estado/dados/data
                          _optionsTabController, // Escuta mudanças na aba selecionada
                        ]),
                        builder: (context, _) {
                          // Determina o filtro com base na aba atual
                          final bool isUpcomingBills = _optionsTabController.index == 1;
                          final String filterType = isUpcomingBills ? 'upcomingBills' : 'transactions';

                          // --- Tratamento dos Estados do WalletController ---
                          final state = _walletController.state;

                          if (state is WalletStateLoading) {
                            return const Center(child: CustomCircularProgressIndicator());
                          }

                          if (state is WalletStateError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Error loading transactions: ${state.message}',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.mediumText16w500.apply(color: AppColors.outcome),
                                ),
                              ),
                            );
                          }

                          if (state is WalletStateSuccess) {
                            final List<TransactionModel> allTransactions = _walletController.transactions;

                            // ***** CORREÇÃO APLICADA AQUI *****
                            // Filtra a lista baseado na aba selecionada
                            final List<TransactionModel> transactionsToShow = isUpcomingBills
                                ? allTransactions.where((t) => !t.status).toList()  // Pendentes (status == false)
                                : allTransactions.where((t) => t.status).toList();   // Concluídas (status == true)
                            // *************************************

                            // --- Exibe a Lista ou Mensagem de Vazio ---
                            if (transactionsToShow.isEmpty) {
                              return Center(
                                child: Text(
                                  isUpcomingBills
                                      ? 'No upcoming bills found for this period.'
                                      : 'No transactions found for this period.',
                                  style: AppTextStyles.mediumText16w500.apply(color: AppColors.lightGrey),
                                ),
                              );
                            }

                            // Retorna a ListView de Transações
                            return TransactionListView(
                              key: ValueKey('${_walletController.selectedDate}-${filterType}-${transactionsToShow.length}'),
                              transactionList: transactionsToShow,
                              selectedDate: _walletController.selectedDate,
                              filterType: filterType,
                              onChange: () {
                                // Recarrega os dados após delete/update
                                _walletController.getTransactionsByDateRange();
                                _balanceController.getBalances();
                              },
                            );
                          }

                          // Estado inicial ou não tratado
                          return Center(
                            child: Text(
                              'Loading data...',
                              style: AppTextStyles.mediumText16w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget para criar as abas de filtro (evita repetição)
  Widget _buildFilterTab(BuildContext context, String text, int index) {
    // Usa o TabController para saber qual aba está ativa
    bool isActive = _optionsTabController.index == index;
    return Tab(
      height: 40,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isActive ? AppColors.iceWhite : AppColors.white,
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
            border: Border.all(
              color: isActive ? AppColors.lightGrey : Colors.transparent,
              width: 1,
            )),
        child: Text(
          text,
          style: AppTextStyles.mediumText16w500.apply(
            color: isActive ? AppColors.darkGrey : AppColors.lightGrey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}