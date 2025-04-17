import 'package:flutter/foundation.dart';
import 'package:tcc_3/repositories/transaction_repository.dart';

import '../../../common/models/transaction_model.dart';
import 'wallet_state.dart';

class WalletController extends ChangeNotifier {
  WalletController({
    required this.transactionRepository,
  });

  final TransactionRepository transactionRepository;

  WalletState _state = WalletStateInitial();

  WalletState get state => _state;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;










  void _changeState(WalletState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> getAllTransactions() async {
    _changeState(WalletStateLoading());

    final result = await transactionRepository.getTransactions();






    result.fold(
      (error) => _changeState(WalletStateError(message: error.message)),
      (data) {
        _transactions = data;

        _transactions.removeWhere((t) => t.syncStatus == SyncStatus.delete);

        _changeState(WalletStateSuccess());
      },
    );


























  }
}