import 'dart:async';

import '../common/data/data.dart';
import '../common/models/models.dart';
import '../services/services.dart';
import 'transaction_repository.dart';

/// {@macro transaction_repository}
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl({
    required this.databaseService,
    required this.syncService,
  });

  final DataService<Map<String, dynamic>> databaseService;
  final SyncService syncService;

  @override
  Future<DataResult<bool>> addTransaction({
    required TransactionModel transaction,
    required String userId,
  }) async {
    try {
      final newTransaction = transaction
          .copyWith(userId: userId, syncStatus: SyncStatus.create)
          .toDatabase();

      await syncService.saveLocalChanges(
        path: TransactionRepository.transactionsPath,
        params: newTransaction,
      );

      return DataResult.success(true);
    } on Failure catch (e) {
      return DataResult.failure(e);
    }
  }

  @override
  Future<DataResult<List<TransactionModel>>> getTransactions({
    int? limit,
    int? offset,
    bool latest = false,
  }) async {
    final params = {
      'limit': limit,
      'offset': offset,
      'skip_status': SyncStatus.delete.name,
    };

    try {
      final cachedTransactionsResponse = await databaseService.read(
        path: TransactionRepository.transactionsPath,
        params: latest
            ? {
                ...params,
                'order_by': 'date desc',
              }
            : {
                ...params,
                'order_by': 'date asc',
              },
      );

      final parsedcachedTransactions =
          List.from(cachedTransactionsResponse['data']);

      final cachedTransactions = parsedcachedTransactions
          .map((e) => TransactionModel.fromMap(e))
          .toList();

      // return DataResult.failure(const GeneralException());

      return DataResult.success(cachedTransactions);
    } on Failure catch (e) {
      return DataResult.failure(e);
    }
  }

  @override
  Future<DataResult<BalancesModel>> getBalances() async {
    try {
      final balanceResponse =
          await databaseService.read(path: TransactionRepository.balancesPath);
      BalancesModel cachedBalances =
          BalancesModel.fromMap((balanceResponse['data'] as List).first);

      return DataResult.success(cachedBalances);
    } on Failure catch (e) {
      return DataResult.failure(e);
    }
  }

  @override
  Future<DataResult<bool>> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      await syncService.saveLocalChanges(
        path: TransactionRepository.transactionsPath,
        params:
            transaction.copyWith(syncStatus: SyncStatus.update).toDatabase(),
      );

      return DataResult.success(true);
    } on Failure catch (e) {
      return DataResult.failure(e);
    }
  }

  @override
  Future<DataResult<bool>> deleteTransaction(
      TransactionModel transaction) async {
    try {
      final deleteTransactionResponse = await databaseService.delete(
        path: TransactionRepository.transactionsPath,
        params: {'id': transaction.id},
      );

      await syncService.saveLocalChanges(
        path: TransactionRepository.transactionsPath,
        params:
            transaction.copyWith(syncStatus: SyncStatus.delete).toDatabase(),
      );

      return DataResult.success(deleteTransactionResponse.isNotEmpty);
    } on Failure catch (e) {
      return DataResult.failure(e);
    }
  }

  @override
  Future<DataResult<BalancesModel>> updateBalance({
    TransactionModel? oldTransaction,
    required TransactionModel newTransaction,
  }) async {
    try {
      final balanceMap =
          await databaseService.read(path: TransactionRepository.balancesPath);
            final balanceList = balanceMap['data'] as List;
if (balanceList.isEmpty) {
  return DataResult.failure(
    const CacheException(code: 'empty_balance',),
  );
}

final current = BalancesModel.fromMap(balanceList.first);


      double newTotalBalance = current.totalBalance;
      double newTotalIncome = current.totalIncome;
      double newTotalOutcome = current.totalOutcome;

      if (oldTransaction == null) {
        newTotalBalance += newTransaction.value;
      } else {
        newTotalBalance -= oldTransaction.value;
        newTotalBalance += newTransaction.value;

        if (oldTransaction.value >= 0) {
          newTotalIncome -= oldTransaction.value;
        } else {
          newTotalOutcome -= oldTransaction.value;
        }
      }

      if (newTransaction.value >= 0) {
        newTotalIncome += newTransaction.value;
      } else {
        newTotalOutcome += newTransaction.value;
      }

      final updatedBalance = current
          .copyWith(
            totalBalance: newTotalBalance,
            totalIncome: newTotalIncome,
            totalOutcome: newTotalOutcome,
          )
          .toMap();

      final updateBalanceResponse = await databaseService.update(
        path: TransactionRepository.balancesPath,
        params: updatedBalance,
      );

      if (!(updateBalanceResponse['data'] as bool)) {
        return DataResult.failure(const CacheException(code: 'update',));
      }

      return DataResult.success(
        BalancesModel.fromMap(updatedBalance),
      );
    } on Failure catch (e) {
      return DataResult.failure(e);
    }
  }
}