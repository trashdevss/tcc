import 'package:flutter/foundation.dart';
import 'package:tcc_3/features/repositories/transaction_repository.dart';

import '../../../../common/models/balances_model.dart';
import 'balance_card_widget_state.dart';

class BalanceCardWidgetController extends ChangeNotifier {
  BalanceCardWidgetController({
    required this.transactionRepository,
  });

  final TransactionRepository transactionRepository;

  BalanceCardWidgetState _state = BalanceCardWidgetStateInitial();

  BalanceCardWidgetState get state => _state;

  BalancesModel _balances = BalancesModel(
    totalIncome: 0,
    totalOutcome: 0,
    totalBalance: 0,
  );
  BalancesModel get balances => _balances;

  void _changeState(BalanceCardWidgetState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> getBalances() async {
    _changeState(BalanceCardWidgetStateLoading());

    final result = await transactionRepository.getBalances();

    result.fold(
      (error) => _changeState(BalanceCardWidgetStateError()),
      (data) {
        _balances = data;

        _changeState(BalanceCardWidgetStateSuccess());
      },
    );
  }
}