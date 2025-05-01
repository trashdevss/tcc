import 'dart:async';
import 'dart:developer'; // Import para usar a função log (opcional, print também funciona)

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

  // --- Métodos addTransaction, getLatestTransactions, getBalances, updateTransaction, deleteTransaction, updateBalance ---
  // Mantidos exatamente como estavam no seu código original, omitidos aqui por brevidade...

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
  Future<DataResult<List<TransactionModel>>> getLatestTransactions() async {
    try {
      final cachedTransactionsResponse = await databaseService.read(
        path: TransactionRepository.transactionsPath,
        params: {
          'limit': 5,
          'skip_status': SyncStatus.delete.name,
          'order_by': 'date desc',
        },
      );

      final parsedcachedTransactions =
          List.from(cachedTransactionsResponse['data']);

      final cachedTransactions = parsedcachedTransactions
          .map((e) => TransactionModel.fromMap(e))
          .toList();

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

     final data = balanceResponse['data'] as List;

     if (data.isEmpty) {
       return DataResult.failure(const CacheException(code: 'no_data'));
     }

     BalancesModel cachedBalances = BalancesModel.fromMap(data.first);

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
    // Lógica do updateBalance mantida como estava...
   try {
     final balanceMap =
         await databaseService.read(path: TransactionRepository.balancesPath);

     final current = BalancesModel.fromMap((balanceMap['data'] as List).first);

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
       return DataResult.failure(const CacheException(code: 'update'));
     }

     return DataResult.success(
       BalancesModel.fromMap(updatedBalance),
     );
   } on Failure catch (e) {
     return DataResult.failure(e);
   }
  }
  // --- Fim dos métodos mantidos ---


  // ***** MÉTODO COM LOGS ADICIONADOS *****
  @override
  Future<DataResult<List<TransactionModel>>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Log 1: Informa o início da busca e as datas
    print('>>> [REPOSITORY] Querying DB for $startDate to $endDate');
    try {
      final cachedTransactionsResponse = await databaseService.read(
        path: TransactionRepository.transactionsPath,
        params: {
          'skip_status': SyncStatus.delete.name,
          'order_by': 'date asc',
           'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      final parsedcachedTransactions =
          List.from(cachedTransactionsResponse['data']);

      // Log 2: Informa quantos itens brutos vieram do banco para essas datas
      print('>>> [REPOSITORY] DB returned ${parsedcachedTransactions.length} raw items for $startDate - $endDate.');

      // Log 3: (Opcional) Descomente para ver os dados brutos de cada item
      // parsedcachedTransactions.forEach((map) => print('  - Raw Map: $map'));

      // Mapeia para TransactionModel (assumindo que fromMap está corrigido)
      final cachedTransactions = parsedcachedTransactions
          .map((e) => TransactionModel.fromMap(e))
          .toList();

      // Log 4: Informa quantos itens foram parseados com sucesso
      print('>>> [REPOSITORY] Parsed ${cachedTransactions.length} transactions.');

      return DataResult.success(cachedTransactions);
    } on Failure catch (e) {
      // Log 5: Informa se ocorreu um erro na busca/parse
      print('>>> [REPOSITORY] DB query/parse FAILED for $startDate - $endDate: $e');
      return DataResult.failure(e);
    }
  }
  // ***** FIM DO MÉTODO COM LOGS *****
}