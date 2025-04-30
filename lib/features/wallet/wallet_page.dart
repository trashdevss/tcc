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
  // Não precisamos mais de um TabController dedicado apenas para exibir o mês
  // late final TabController _monthsTabController; // Removido

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _optionsTabController = TabController(
      length: 2, // "Transactions", "Upcoming Bills"
      vsync: this,
    );

    // Carrega dados iniciais
    // Adiciona um pequeno delay para garantir que a UI esteja pronta se necessário
    // WidgetsBinding.instance.addPostFrameCallback((_) {
       _walletController.getTransactionsByDateRange();
       _balanceController.getBalances();
    // });


    // Adiciona listener para tratar erros ou recarregar UI em mudanças de estado
    _walletController.addListener(_handleWalletStateChange);
    _optionsTabController.addListener(_handleTabChange); // Opcional: se precisar fazer algo extra na troca de aba
  }

  @override
  void dispose() {
    _optionsTabController.removeListener(_handleTabChange);
    _optionsTabController.dispose();
    _walletController.removeListener(_handleWalletStateChange);
    // Limpa o controller se ele for um LazySingleton e não for mais necessário globalmente
    // locator.resetLazySingleton<WalletController>();
    // locator.resetLazySingleton<BalanceController>();
    super.dispose();
  }

  // --- State Handlers ---
  void _handleWalletStateChange() {
    final state = _walletController.state;
    switch (state.runtimeType) {
      case WalletStateError:
        if (!mounted) return;
        // Mostra um modal em caso de erro crítico (ex: token inválido)
        showCustomModalBottomSheet(
          context: context,
          content: (state as WalletStateError).message,
          buttonText: 'Go to login', // Ou texto apropriado
          isDismissible: false,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.initial, // Rota de login
            (route) => false,
          ),
        );
        break;
      case WalletStateLoading:
      case WalletStateSuccess:
        // Se precisar forçar um rebuild da UI quando o estado mudar (além do AnimatedBuilder)
        if (mounted) {
         // setState(() {}); // Geralmente não necessário devido aos AnimatedBuilders
        }
        break;
    }
  }

   void _handleTabChange() {
     // O AnimatedBuilder já escuta o _optionsTabController, então setState aqui
     // geralmente não é necessário SÓ para atualizar a lista.
     // Mas pode ser útil se outra parte da UI precisar mudar com a aba.
     // setState(() {
     //   print("Tab changed to: ${_optionsTabController.index}");
     // });
   }

  // --- Navigation Methods ---
  void _goToPreviousMonth() {
    final selectedDate = _walletController.selectedDate;
    _walletController.changeSelectedDate(
        DateTime(selectedDate.year, selectedDate.month - 1));
    _walletController.getTransactionsByDateRange();
    // Não precisa setState, o AnimatedBuilder cuidará da atualização do texto do mês
  }

  void _goToNextMonth() {
    final selectedDate = _walletController.selectedDate;
    _walletController.changeSelectedDate(
        DateTime(selectedDate.year, selectedDate.month + 1));
    _walletController.getTransactionsByDateRange();
    // Não precisa setState, o AnimatedBuilder cuidará da atualização do texto do mês
  }

  Future<bool> _onWillPop() async {
    _homeController.pageController.navigateTo(BottomAppBarItem.home);
    return false; // Impede o pop padrão
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
            // Ajuste 'top' para garantir espaço suficiente para o AppHeader
            // O valor '165.h' depende da altura do seu AppHeader e do contexto de '.h'
            top: 120.h, // Exemplo: Pode precisar ajustar este valor
            bottom: 0,
            child: BasePage( // Seu widget de layout base
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                // Coluna principal que organiza o conteúdo da página
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Estica filhos horizontalmente
                  children: [
                    // --- Seção do Saldo Total ---
                    Center( // Centraliza o texto do saldo
                      child: Text(
                        'Total Balance',
                        style: AppTextStyles.inputLabelText.apply(color: AppColors.grey),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Center( // Centraliza o valor do saldo
                      child: AnimatedBuilder(
                          animation: _balanceController,
                          builder: (context, _) {
                            if (_balanceController.state is BalanceStateLoading) {
                              // ***** CORREÇÃO APLICADA AQUI *****
                              // Removido o parâmetro 'radius: 15' pois ele não existe
                              // no CustomCircularProgressIndicator. O tamanho agora
                              // é controlado pelo SizedBox pai.
                              return const SizedBox( // Dá um tamanho fixo para o indicador
                                height: 36, // Ajuste conforme seu AppTextStyles.mediumText30
                                child: Center(child: CustomCircularProgressIndicator())
                              );
                              // *************************************
                            }
                            if (_balanceController.state is BalanceStateError) {
                              return Text(
                                'Error', // Mensagem simples de erro
                                style: AppTextStyles.mediumText30.apply(color: AppColors.outcome),
                              );
                            }
                            // Exibe o saldo formatado
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
                    // StatefulBuilder apenas para atualizar a APARÊNCIA das abas (cores/bordas)
                    StatefulBuilder(
                      builder: (context, setTabState) {
                        return TabBar(
                          controller: _optionsTabController,
                          labelPadding: EdgeInsets.zero, // Remove padding padrão
                          indicator: const BoxDecoration(), // Sem indicador sublinhado
                          indicatorSize: TabBarIndicatorSize.tab,
                          onTap: (index) {
                            // Atualiza apenas a aparência das abas
                            setTabState(() {});
                            // A mudança no _optionsTabController.index notificará o AnimatedBuilder da lista
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
                          color: AppColors.green, // Use suas cores
                          onPressed: _goToPreviousMonth,
                        ),
                        // Mostra o mês/ano e atualiza via AnimatedBuilder
                        AnimatedBuilder(
                          animation: _walletController,
                          builder: (context, _) => Text(
                            // Usar 'MMMM yyyy' para incluir o ano
                            // Corrigido para usar yyyy para o ano completo
                            DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
                                .format(_walletController.selectedDate),
                            style: AppTextStyles.mediumText16w600.apply(
                              color: AppColors.green, // Use suas cores
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_outlined),
                          color: AppColors.green, // Use suas cores
                          onPressed: _goToNextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0), // Espaço antes da lista

                    // --- Lista de Transações (Ocupa o espaço restante) ---
                    Expanded(
                      // Reconstrói quando os dados das transações OU a aba selecionada mudam
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
                            // Usar o indicador padrão aqui também, se desejar
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

                            // Aplica o filtro
                            final List<TransactionModel> transactionsToShow = isUpcomingBills
                                ? allTransactions.where((t) => !t.status).toList() // Apenas pendentes
                                : allTransactions; // Todas as transações

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
                              // Chave para ajudar o Flutter a identificar mudanças
                              key: ValueKey('${_walletController.selectedDate}-$filterType-${transactionsToShow.length}'),
                              transactionList: transactionsToShow,
                              selectedDate: _walletController.selectedDate,
                              filterType: filterType, // Passa o filtro atual
                              onChange: () {
                                // Callback chamado após delete/update na TransactionListView
                                // Recarrega os dados
                                _walletController.getTransactionsByDateRange();
                                _balanceController.getBalances();
                              },
                            );
                          }

                          // Estado inicial ou não tratado (deve ser evitado)
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
    bool isActive = _optionsTabController.index == index;
    return Tab(
      height: 40, // Altura consistente da aba
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isActive ? AppColors.iceWhite : AppColors.white, // Use suas cores
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
            border: Border.all(
              color: isActive ? AppColors.lightGrey : Colors.transparent, // Use suas cores
              width: 1,
            )),
        child: Text(
          text,
          style: AppTextStyles.mediumText16w500.apply(
            color: isActive ? AppColors.darkGrey : AppColors.lightGrey, // Use suas cores
          ),
          overflow: TextOverflow.ellipsis, // Evita overflow de texto
        ),
      ),
    );
  }
}

// --- Certifique-se de ter as dependências e arquivos referenciados ---
// Exemplo de dependências no pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   intl: ^0.18.0 # Ou versão mais recente (ex: ^0.19.0)
//   provider: ^6.0.0 # Ou outro gerenciador de estado se usar
//   get_it: ^7.2.0 # Para locator (ex: ^7.6.7)
//   # ... outras dependências

// --- Lembre-se de definir as classes/widgets referenciados ---
// como AppHeader, BasePage, CustomModalSheetMixin, CustomCircularProgressIndicator,
// TransactionListView, NamedRoute, AppColors, AppTextStyles, TransactionModel, etc.
// e configurar seu locator (get_it).
// Certifique-se que CustomCircularProgressIndicator NÃO requer um parâmetro 'radius'.