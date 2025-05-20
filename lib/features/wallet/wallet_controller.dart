import 'dart:async'; // Adicionado para StreamSubscription
import 'package:flutter/foundation.dart';

// Seus imports
import '../../common/models/balances_model.dart'; // Importar BalancesModel
import '../../common/models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../services/data_service/jove_notification_service.dart'; // Importar JoveNotificationService
import 'wallet_state.dart'; 

class WalletController extends ChangeNotifier {
  WalletController({
    required this.transactionRepository,
    required this.joveNotificationService, // <<--- 1. INJETAR JoveNotificationService
  }) {
    // Carrega os dados iniciais (transações do mês atual e saldos)
    _loadInitialData();

    // <<--- 2. INSCREVER-SE NO STREAM DE NOVAS TRANSAÇÕES ---
    _transactionSubscription = joveNotificationService.transactionStream.listen(
      (novaTransacaoParseada) {
        debugPrint("[WalletController] Nova transação recebida do JoveNotificationService: ${novaTransacaoParseada.description}");
        // Lida com a nova transação (atualiza saldos e, se necessário, a lista de transações)
        _handleNewTransaction(novaTransacaoParseada);
      },
      onError: (error) {
        debugPrint("[WalletController] Erro no transactionStream do JoveNotificationService: $error");
        // Você pode querer tratar erros do stream aqui, se aplicável
      }
    );
  }

  final TransactionRepository transactionRepository;
  final JoveNotificationService joveNotificationService; // <<--- Campo para o serviço
  StreamSubscription<ParsedFinancialTransaction>? _transactionSubscription; // <<--- Para cancelar a inscrição

  WalletState _state = WalletStateInitial();
  WalletState get state => _state;

  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get selectedDate => _selectedDate;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions); // Retorna cópia imutável

  // <<--- NOVO: Campo para armazenar os saldos atuais ---
  BalancesModel? _currentBalances;
  BalancesModel? get currentBalances => _currentBalances;

  void _changeState(WalletState newState) {
    // Evita reconstruções desnecessárias se o estado não mudou,
    // mas permite re-setar para Loading se uma nova carga for iniciada.
    if (_state.runtimeType == newState.runtimeType && _state is! WalletStateLoading) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> _loadInitialData() async {
    debugPrint("[WalletController] _loadInitialData chamado");
    await getTransactionsByDateRange(); // Já busca transações e depois saldos
  }

  // <<--- NOVO: Método para buscar/atualizar os saldos ---
  Future<void> _fetchBalances() async {
    debugPrint("[WalletController] Buscando saldos (_fetchBalances)...");
    final balanceResult = await transactionRepository.getBalances();
    balanceResult.fold(
      (error) {
        debugPrint("[WalletController] Erro ao buscar saldos: ${error.message}");
        _currentBalances = null; // Ou BalancesModel.zero() ou algum estado de erro
        // Não necessariamente muda o WalletState principal, a menos que seja um erro crítico
      },
      (balancesData) {
        debugPrint("[WalletController] Saldos buscados com sucesso: Income=${balancesData.totalIncome}, Outcome=${balancesData.totalOutcome}, Balance=${balancesData.totalBalance}");
        _currentBalances = balancesData;
      }
    );
    // Notifica os listeners para que a UI (Balance Card) atualize
    // Se _changeState for chamado depois (ex: em getTransactionsByDateRange), isso pode ser redundante
    // Mas se _fetchBalances for chamado isoladamente, isso é importante.
    notifyListeners();
  }

  // <<--- NOVO: Método para lidar com uma nova transação do stream ---
  Future<void> _handleNewTransaction(ParsedFinancialTransaction parsedTransaction) async {
    debugPrint("[WalletController] _handleNewTransaction para: ${parsedTransaction.description}, Data da Notificação: ${parsedTransaction.date}");

    // O JoveNotificationService já salvou a transação no banco de dados.
    // Agora, precisamos instruir o TransactionRepository a recalcular e ATUALIZAR os saldos na tabela 'balances'.
    // Vamos usar o método `updateBalance` do seu repositório.
    // Precisamos criar um TransactionModel a partir do ParsedFinancialTransaction.

    final transactionValueForBalance = parsedTransaction.type == TransactionType.income
        ? parsedTransaction.amount
        : -parsedTransaction.amount;

    // O método updateBalance espera um TransactionModel.
    // O ID e outros campos podem não ser estritamente necessários para o cálculo do saldo
    // se updateBalance apenas usa 'value' e 'date' para determinar o impacto.
    // Se ele precisar do TransactionModel completo e persistido, seria melhor JoveNotificationService emitir o TransactionModel.
    final newTransactionForBalanceUpdate = TransactionModel(
      id: "temp-${DateTime.now().millisecondsSinceEpoch}", // ID não persistido, apenas para a lógica de updateBalance
      description: parsedTransaction.description,
      value: transactionValueForBalance,
      category: parsedTransaction.category,
      date: parsedTransaction.originalNotificationTimestamp, // Usando o timestamp original
      createdAt: DateTime.now().millisecondsSinceEpoch, // Não relevante para o cálculo do saldo em si
      status: true,
      userId: "temp_user", // Se seu updateBalance não usa UserID para calcular, isso é OK.
    );

    debugPrint("[WalletController] Chamando transactionRepository.updateBalance...");
    final balanceUpdateResult = await transactionRepository.updateBalance(
        newTransaction: newTransactionForBalanceUpdate,
        // oldTransaction é null porque é uma transação completamente nova
    );

    balanceUpdateResult.fold(
      (error) {
        debugPrint("[WalletController] Erro ao ATUALIZAR saldos via repositório após nova notificação: ${error.message}");
      },
      (updatedBalances) {
        debugPrint("[WalletController] Saldos ATUALIZADOS com sucesso via repositório: Income=${updatedBalances.totalIncome}, Outcome=${updatedBalances.totalOutcome}, Balance=${updatedBalances.totalBalance}");
        _currentBalances = updatedBalances; // Atualiza os saldos no controller
      }
    );
    
    // Após atualizar os saldos, também precisamos recarregar as transações do mês
    // se a nova transação pertencer ao mês atualmente selecionado, para atualizar a lista de histórico.
    DateTime newTransactionDate = parsedTransaction.date; // Vem do ParsedFinancialTransaction
    if (newTransactionDate.year == _selectedDate.year && newTransactionDate.month == _selectedDate.month) {
      debugPrint("[WalletController] Nova transação pertence ao mês selecionado. Recarregando transações do mês.");
      // getTransactionsByDateRange já busca transações e depois chama _fetchBalances, e notifica listeners.
      await getTransactionsByDateRange(); 
    } else {
      // Se a transação não for do mês atual, os saldos gerais foram atualizados,
      // mas a lista de transações do mês atual não muda.
      // Apenas notificamos para garantir que o BalanceCard (que usa _currentBalances) atualize.
      debugPrint("[WalletController] Nova transação NÃO pertence ao mês selecionado. Apenas notificando para atualização do BalanceCard.");
      notifyListeners(); 
    }
  }

  // Método para a UI solicitar uma atualização (ex: pull-to-refresh)
  Future<void> refreshTransactionsForCurrentMonth() async {
    debugPrint("[WalletController] refreshTransactionsForCurrentMonth chamado para o mês de $_selectedDate");
    // _loadInitialData ou getTransactionsByDateRange fará o necessário
    await getTransactionsByDateRange();
  }

  void changeSelectedDate(DateTime newDate) {
    DateTime normalizedNewDate = DateTime(newDate.year, newDate.month, 1);
    if (_selectedDate.year != normalizedNewDate.year || _selectedDate.month != normalizedNewDate.month) {
      _selectedDate = normalizedNewDate;
      debugPrint('[WalletController] Selected date changed to: $_selectedDate. Buscando transações e saldos...');
      getTransactionsByDateRange(); // Este método já busca transações e depois saldos
    } else {
      debugPrint('[WalletController] Selected date (month/year) é a mesma.');
    }
  }

  Future<void> getTransactionsByDateRange() async {
    debugPrint('[WalletController] Starting getTransactionsByDateRange for month of $_selectedDate');
    _changeState(WalletStateLoading());

    final DateTime firstDayOfMonthUtc = DateTime.utc(_selectedDate.year, _selectedDate.month, 1);
    final DateTime firstDayOfNextMonthUtc = DateTime.utc(_selectedDate.year, _selectedDate.month + 1, 1);
    final DateTime endOfMonthUtc = firstDayOfNextMonthUtc.subtract(const Duration(milliseconds: 1));

    debugPrint('[WalletController] Fetching transactions from: $firstDayOfMonthUtc (UTC) to $endOfMonthUtc (UTC)');

    final result = await transactionRepository.getTransactionsByDateRange(
      startDate: firstDayOfMonthUtc,
      endDate: endOfMonthUtc,
    );

    bool transactionsFetchedSuccessfully = false;
    result.fold(
      (error) {
        debugPrint('[WalletController] ERROR fetching transactions for month of $_selectedDate: ${error.message}');
        _transactions = []; 
        _changeState(WalletStateError(message: error.message));
      },
      (data) {
        debugPrint('[WalletController] SUCCESS fetching transactions for month of $_selectedDate. Count: ${data.length}');
        _transactions = data;
        transactionsFetchedSuccessfully = true;
        // Não mudamos o estado aqui ainda, pois _fetchBalances fará isso ou confirmará o WalletStateSuccess
      },
    );
    
    // Sempre buscar/atualizar os saldos após buscar as transações
    await _fetchBalances(); 
    
    // Mudar o estado para sucesso apenas se a busca de transações foi bem sucedida e não houve erro nos saldos
    // A _fetchBalances já chama notifyListeners, então a UI deve atualizar o balance card.
    // O _changeState aqui é para o estado geral da lista de transações.
    if (transactionsFetchedSuccessfully && _state is WalletStateLoading) {
      _changeState(WalletStateSuccess());
    } else if (!transactionsFetchedSuccessfully && _state is WalletStateLoading) {
        // Se a busca de transações falhou, mas _fetchBalances não mudou o estado de erro
        // _changeState(WalletStateError(message: "Falha ao buscar transações, mas saldos podem estar ok"));
        // Ou manter o estado de erro já definido pelo fold das transações.
    }
    
    debugPrint('[WalletController] Finished getTransactionsByDateRange for month of $_selectedDate');
  }


  // Este método pode ser removido ou adaptado se não for mais usado.
  Future<void> getAllTransactions_DEPRECATED_OR_FOR_OTHER_USE() async {
    // ... (lógica original)
  }

  @override
  void dispose() {
    debugPrint("[WalletController] Dispose chamado. Cancelando inscrição do stream.");
    _transactionSubscription?.cancel(); // <<--- 4. CANCELAR A INSCRIÇÃO
    super.dispose();
  }
}