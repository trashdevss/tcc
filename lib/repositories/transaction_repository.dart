import 'dart:async';

import '../common/data/data_result.dart';
import '../common/models/models.dart';

/// {@template transaction_repository}
/// Communicates Transactions CRUD operations between Controllers and Data Sources
/// {@endtemplate}
abstract class TransactionRepository {
  static const transactionsPath = 'transactions';
  static const balancesPath = 'balances';
  static const localChanges = 'local_changes';

  Future<DataResult<bool>> addTransaction({
    required TransactionModel transaction,
    required String userId,
  });

  Future<DataResult<bool>> updateTransaction(TransactionModel transaction);

  Future<DataResult<List<TransactionModel>>> getTransactions({
    int? limit,
    int? offset,
    bool latest = false,
  });

  Future<DataResult<bool>> deleteTransaction(TransactionModel transaction);

  Future<DataResult<BalancesModel>> getBalances();

  Future<DataResult<BalancesModel>> updateBalance({
    TransactionModel? oldTransaction,
    required TransactionModel newTransaction,
  });
}