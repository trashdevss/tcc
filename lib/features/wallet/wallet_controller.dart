import 'package:flutter/foundation.dart';
import 'dart:developer'; // Para logs (opcional)

import '../../common/models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import 'wallet_state.dart';

class WalletController extends ChangeNotifier {
  WalletController({
    required this.transactionRepository,
  });

  final TransactionRepository transactionRepository;

  WalletState _state = WalletStateInitial();
  WalletState get state => _state;

  // Mantém a data selecionada pelo usuário (mês/ano)
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Lista interna de transações para o mês selecionado
  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  // Helper para mudar o estado e notificar listeners
  void _changeState(WalletState newState) {
    _state = newState;
    notifyListeners();
  }

  // Método para buscar TODAS as transações (não usado na lógica mensal da WalletPage)
  // Poderia ser útil para outras partes do app, se necessário.
  Future<void> getAllTransactions() async {
    print('>>> [CONTROLLER] Starting getAllTransactions');
    _changeState(WalletStateLoading());
    final result = await transactionRepository.getLatestTransactions(); // Nota: este método busca apenas as ÚLTIMAS 5
    result.fold(
      (error) {
         print('>>> [CONTROLLER] ERROR getAllTransactions: ${error.message}');
        _changeState(WalletStateError(message: error.message));
      },
      (data) {
         print('>>> [CONTROLLER] SUCCESS getAllTransactions. Count: ${data.length}');
        _transactions = data; // Cuidado: sobrescreve a lista com apenas as últimas 5
        _changeState(WalletStateSuccess());
      },
    );
     print('>>> [CONTROLLER] Finished getAllTransactions');
  }

  // Método para mudar a data selecionada (chamado pelos botões de mês)
  void changeSelectedDate(DateTime newDate) {
    // Evita buscas desnecessárias se o mês/ano não mudou
    if (_selectedDate.year != newDate.year || _selectedDate.month != newDate.month) {
      _selectedDate = DateTime(newDate.year, newDate.month, 1); // Garante que é sempre o dia 1
      print('>>> [CONTROLLER] Selected date changed to: $_selectedDate');
      // A busca será chamada separadamente em _goToPrevious/NextMonth
      // notifyListeners(); // Notificar aqui pode ser útil se a UI mostrar a data antes da busca terminar
    }
  }

  // Método principal para buscar transações pelo intervalo do mês selecionado
  Future<void> getTransactionsByDateRange() async {
    print('>>> [CONTROLLER] Starting getTransactionsByDateRange for $_selectedDate'); // Log 1
    _changeState(WalletStateLoading());

    // --- CORREÇÃO NO CÁLCULO DAS DATAS ---
    // Calcula o início do PRIMEIRO dia do mês selecionado (00:00:00)
    final DateTime startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);

    // Calcula o início do PRIMEIRO dia do PRÓXIMO mês (00:00:00)
    final DateTime firstDayOfNextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    // Calcula o endDate como o ÚLTIMO milissegundo do mês selecionado
    final DateTime endDate = firstDayOfNextMonth.subtract(const Duration(milliseconds: 1));
    // Exemplo: Se _selectedDate é Abril, endDate será 30/04/YYYY 23:59:59.999
    // --- FIM DA CORREÇÃO ---

    // Chama o repositório com as datas CORRIGIDAS
    final result = await transactionRepository.getTransactionsByDateRange(
      startDate: startDate, // Passa a data inicial correta
      endDate: endDate,     // Passa a data final correta
    );

    // Processa o resultado da busca
    result.fold(
       (error) {
          print('>>> [CONTROLLER] ERROR fetching for $_selectedDate: ${error.message}'); // Log 2a
         _changeState(WalletStateError(message: error.message));
       },
       (data) {
          print('>>> [CONTROLLER] SUCCESS fetching for $_selectedDate. Count: ${data.length}'); // Log 2b
         _transactions = data; // Atualiza a lista interna APENAS com os dados do mês buscado
         _changeState(WalletStateSuccess()); // Notifica a UI que a busca terminou com sucesso
       },
     );
     print('>>> [CONTROLLER] Finished getTransactionsByDateRange for $_selectedDate'); // Log 3
  }
}