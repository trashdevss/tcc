import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/features/balance_state.dart';
import 'package:tcc_3/common/models/transaction_model.dart';

import '../../common/constants/constants.dart';
import '../../common/extensions/extensions.dart';
import '../../common/widgets/widgets.dart';
import '../../locator.dart';
import '../home/home_controller.dart';
import 'wallet_controller.dart';
import 'wallet_state.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with TickerProviderStateMixin, CustomModalSheetMixin {
  final _balanceController = locator.get<BalanceController>();
  final _walletController = locator.get<WalletController>();
  final _homeController = locator.get<HomeController>();

  late final TabController _optionsTabController;

  @override
  void initState() {
    super.initState();
    _optionsTabController = TabController(length: 2, vsync: this);

    // Adiciona um listener para reconstruir a UI quando o controller notificar.
    // O AnimatedBuilder já faz isso para a lista, mas pode ser útil para outras partes.
    _walletController.addListener(_onWalletControllerUpdate);
    _optionsTabController.addListener(_onTabChange); // Para redesenhar as abas

    // Busca inicial
    _fetchData();
  }

  void _fetchData() {
    debugPrint("[WalletPage] _fetchData chamado");
    _walletController.getTransactionsByDateRange();
    _balanceController.getBalances();
  }

  @override
  void dispose() {
    _optionsTabController.removeListener(_onTabChange);
    _optionsTabController.dispose();
    _walletController.removeListener(_onWalletControllerUpdate);
    super.dispose();
  }

  void _onWalletControllerUpdate() {
    // Este listener é chamado sempre que _walletController.notifyListeners() é chamado.
    // O AnimatedBuilder já reage a isso para a lista.
    // Se outras partes da UI precisarem ser reconstruídas com base no estado do walletController,
    // você pode chamar setState aqui, mas geralmente é melhor usar AnimatedBuilder/Consumer.
    final state = _walletController.state;
    debugPrint("[WalletPage] _onWalletControllerUpdate: Novo estado: $state");
    if (state is WalletStateError) {
      if (!mounted) return;
      showCustomModalBottomSheet(
        context: context,
        content: state.message,
        buttonText: 'Ir para Login',
        isDismissible: false,
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.initial,
          (route) => false,
        ),
      );
    }
    // Se precisar forçar um rebuild geral da página com base na mudança de estado do wallet:
    // if (mounted) {
    //   setState(() {});
    // }
  }

  void _onTabChange() {
    // Força a reconstrução do StatefulBuilder que contém a TabBar
    // e também o AnimatedBuilder da lista (pois ele escuta _optionsTabController).
    if (mounted) {
      setState(() {
        debugPrint("[WalletPage] Aba alterada, forçando rebuild para UI da TabBar e lista.");
      });
    }
  }

  void _goToPreviousMonth() {
    final selectedDate = _walletController.selectedDate;
    _walletController.changeSelectedDate(
        DateTime(selectedDate.year, selectedDate.month - 1));
    // changeSelectedDate no controller já chama getTransactionsByDateRange
  }

  void _goToNextMonth() {
    final selectedDate = _walletController.selectedDate;
    _walletController.changeSelectedDate(
        DateTime(selectedDate.year, selectedDate.month + 1));
    // changeSelectedDate no controller já chama getTransactionsByDateRange
  }

  Future<bool> _onWillPop() async {
    _homeController.pageController.navigateTo(BottomAppBarItem.home);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[WalletPage] Build method. Estado do WalletController: ${_walletController.state}");
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          AppHeader(
            title: 'Minha Carteira',
            onPressed: () =>
                _homeController.pageController.navigateTo(BottomAppBarItem.home),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 120.h, // Ajuste conforme o tamanho do seu AppHeader
            bottom: 0,
            child: BasePage(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Seção do Saldo Total ---
                    Center(child: Text('Saldo Total', style: AppTextStyles.inputLabelText.apply(color: AppColors.grey))),
                    const SizedBox(height: 8.0),
                    Center(
                      child: AnimatedBuilder(
                          animation: _balanceController,
                          builder: (context, _) {
                            // ... (lógica do saldo como antes)
                            if (_balanceController.state is BalanceStateLoading) {
                              return const SizedBox(height: 36, child: Center(child: CustomCircularProgressIndicator()));
                            }
                            if (_balanceController.state is BalanceStateError) {
                              return Text('Erro Saldo', style: AppTextStyles.mediumText30.apply(color: AppColors.outcome));
                            }
                            final balanceValue = _balanceController.balances?.totalBalance ?? 0.0;
                            final formattedBalance = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(balanceValue);
                            return Text(formattedBalance,style: AppTextStyles.mediumText30.apply(color: AppColors.blackGrey));
                          }),
                    ),
                    const SizedBox(height: 24.0),

                    // --- Abas de Opções (Transactions / Upcoming Bills) ---
                    // Usar um Builder ou StatefulBuilder aqui pode não ser necessário se o _onTabChange com setState
                    // já estiver a forçar a reconstrução desta parte da árvore de widgets.
                    // O TabBar em si não precisa de um builder para mudar sua aparência com base no índice ativo,
                    // pois o TabController e o tema do TabBar cuidam disso.
                    // O StatefulBuilder original era para o onTap das abas redesenhar as abas em si.
                    TabBar(
                      controller: _optionsTabController,
                      labelPadding: EdgeInsets.zero,
                      indicator: const BoxDecoration(),
                      indicatorSize: TabBarIndicatorSize.tab,
                      // onTap não precisa de setTabState se _onTabChange com setState já faz o rebuild
                      onTap: (index) => _optionsTabController.animateTo(index), // Apenas muda a aba
                      tabs: [
                        _buildFilterTab(context, 'Transações', 0),
                        _buildFilterTab(context, 'Contas Futuras', 1),
                      ],
                    ),
                    const SizedBox(height: 32.0),

                    // --- Seção de Navegação de Mês ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), color: AppColors.green, onPressed: _goToPreviousMonth),
                        // Usar AnimatedBuilder para o texto do mês é bom se _selectedDate mudar e você quiser animação
                        // ou apenas para garantir que ele reconstrói quando _walletController notifica.
                        AnimatedBuilder(
                          animation: _walletController,
                          builder: (context, _) => Text(
                            DateFormat('MMMM yyyy', Localizations.localeOf(context).toString()).format(_walletController.selectedDate),
                            style: AppTextStyles.mediumText16w600.apply(color: AppColors.green),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.arrow_forward_ios_outlined), color: AppColors.green, onPressed: _goToNextMonth),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // --- Lista de Transações ---
                    Expanded(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_walletController, _optionsTabController]),
                        builder: (context, _) {
                          final walletState = _walletController.state;
                          final bool isUpcomingBills = _optionsTabController.index == 1;
                          
                          debugPrint("[WalletPage - ListBuilder] Estado: $walletState, Aba: ${isUpcomingBills ? 'Futuras' : 'Transações'}");

                          if (walletState is WalletStateLoading) {
                            return const Center(child: CustomCircularProgressIndicator());
                          }
                          if (walletState is WalletStateError) {
                            return Center(child: Text('Erro: ${walletState.message}'));
                          }
                          if (walletState is WalletStateSuccess) {
                            final List<TransactionModel> allTransactions = _walletController.transactions;
                            debugPrint("[WalletPage - ListBuilder] Controller transactions count: ${allTransactions.length}");
                            
                            // Aplicar filtro com base na aba selecionada
                            final List<TransactionModel> transactionsToShow;
                            if (isUpcomingBills) { // Aba "Contas Futuras"
                              transactionsToShow = allTransactions.where((t) => !t.status).toList(); // Pendentes (status == false)
                            } else { // Aba "Transações"
                              // DECIDA O FILTRO: Mostrar todas ou apenas as concluídas?
                              transactionsToShow = allTransactions; // Mostra todas por padrão
                              // transactionsToShow = allTransactions.where((t) => t.status).toList(); // Apenas concluídas (status == true)
                            }
                            debugPrint("[WalletPage - ListBuilder] transactionsToShow count: ${transactionsToShow.length}");

                            if (transactionsToShow.isEmpty) {
                              return Center(child: Text(isUpcomingBills ? 'Nenhuma conta futura.' : 'Nenhuma transação neste período.'));
                            }
                            return TransactionListView(
                              key: ValueKey('${_walletController.selectedDate.toString()}-${_optionsTabController.index}-${transactionsToShow.length}'),
                              transactionList: transactionsToShow,
                              selectedDate: _walletController.selectedDate, // Passa a data para o TransactionListView, se ele precisar
                              filterType: isUpcomingBills ? 'upcomingBills' : 'transactions', // Passa o tipo de filtro
                              onChange: () { // Callback para quando uma transação é alterada/deletada dentro da lista
                                _fetchData(); // Recarrega tudo
                              },
                            );
                          }
                          return const Center(child: Text("Carregando...")); // Estado inicial ou desconhecido
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

  Widget _buildFilterTab(BuildContext context, String text, int index) {
    // O AnimatedBuilder que envolve a lista também escuta _optionsTabController.
    // Se a aparência da aba precisar mudar com base no índice, o setState em _onTabChange cuidará disso.
    bool isActive = _optionsTabController.index == index;
    return Tab(
      height: 40,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isActive ? AppColors.iceWhite : AppColors.white, // Exemplo de mudança de cor
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
