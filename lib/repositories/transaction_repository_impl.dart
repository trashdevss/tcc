import 'dart:async';
import 'dart:developer';

// Ajuste os caminhos de import para corresponder à sua estrutura de projeto
import 'package:tcc_3/common/data/exceptions.dart';
import 'package:tcc_3/services/data_service/data_service.dart';

import '../../common/data/data_result.dart';
import '../../common/models/transaction_model.dart';
import '../../common/models/balances_model.dart';
import '../../services/sync_services/sync_service.dart';
import 'transaction_repository.dart';

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
    log('[TransactionRepo] addTransaction: Iniciando para userId: $userId, Desc: ${transaction.description}', name: 'REPO_START');
    try {
      final newTransaction = transaction
          .copyWith(userId: userId, syncStatus: SyncStatus.create)
          .toDatabase();

      // A chamada para saveLocalChanges é assíncrona.
      // Se um erro ocorrer aqui e não for uma 'Failure', o catch genérico abaixo deve lidar com ele.
      await syncService.saveLocalChanges(
        path: TransactionRepository.transactionsPath,
        params: newTransaction,
      );

      log('[TransactionRepo] addTransaction: Sucesso APÓS saveLocalChanges para userId: $userId, Desc: ${transaction.description}', name: 'REPO_SUCCESS');
      return DataResult.success(true);
    } on Failure catch (e) {
      // Captura Falhas customizadas (CacheException, SyncException, etc.) que podem ser lançadas
      // diretamente pelo syncService.saveLocalChanges se ele as tratar e relançar como Failure.
      log('[TransactionRepo] addTransaction: Falha (Failure) capturada: $e', name: 'REPO_FAILURE');
      return DataResult.failure(e);
    } catch (e, stackTrace) {
      // Este bloco deve capturar QUALQUER outra exceção, incluindo TypeError,
      // que possa ter sido re-lançada pelo syncService.saveLocalChanges.
      log('[TransactionRepo] addTransaction: Exceção genérica capturada: $e', error: e, stackTrace: stackTrace, name: 'REPO_GENERIC_ERROR_DETAIL');
      // Envolve a exceção genérica em um objeto Failure.
      // Use CacheException se for o mais apropriado ou crie uma GenericFailure.
      return DataResult.failure(CacheException( // Certifique-se que CacheException aceita 'code'
        code: 'repo_add_generic_error',
        // message: 'Erro inesperado ao adicionar transação: ${e.toString()}', // Removido se CacheException não tiver 'message'
      ));
    }
  }

  // ... outros métodos (getLatestTransactions, getBalances, etc.) devem ter tratamento similar ...
  // O código completo para os outros métodos está no artefato anterior com o mesmo ID.
  // Certifique-se que todos eles têm o 'catch (e, stackTrace)' genérico.

  @override
  Future<DataResult<List<TransactionModel>>> getLatestTransactions() async {
    log('[TransactionRepo] getLatestTransactions: Iniciando', name: 'REPO');
    try {
      final cachedTransactionsResponse = await databaseService.read(
        path: TransactionRepository.transactionsPath,
        params: {
          'limit': 5,
          'skip_status': SyncStatus.delete.name,
          'order_by': 'date desc',
        },
      );

      final dynamic data = cachedTransactionsResponse['data'];
      if (data == null || data is! List) {
        log('[TransactionRepo] getLatestTransactions: Nenhum dado ou formato inesperado retornado pelo databaseService.', name: 'REPO_WARNING');
        return DataResult.success([]);
      }

      final parsedCachedTransactions = List<Map<String, dynamic>>.from(data.map((e) => Map<String,dynamic>.from(e as Map)));
      
      final cachedTransactions = parsedCachedTransactions
          .map((e) => TransactionModel.fromMap(e))
          .toList();
      
      log('[TransactionRepo] getLatestTransactions: Sucesso, ${cachedTransactions.length} transações encontradas.', name: 'REPO');
      return DataResult.success(cachedTransactions);
    } on Failure catch (e) {
      log('[TransactionRepo] getLatestTransactions: Falha (Failure) capturada: $e', name: 'REPO_ERROR');
      return DataResult.failure(e);
    } catch (e, stackTrace) {
      log('[TransactionRepo] getLatestTransactions: Exceção genérica capturada: $e', error:e, stackTrace: stackTrace, name: 'REPO_ERROR');
      return DataResult.failure(const CacheException( 
        code: 'repo_get_latest_generic_error',
      ));
    }
  }

  @override
  Future<DataResult<BalancesModel>> getBalances() async {
    log('[TransactionRepo] getBalances: Iniciando', name: 'REPO');
    try {
      final balanceResponse =
          await databaseService.read(path: TransactionRepository.balancesPath);

      final dynamic data = balanceResponse['data'];
      if (data == null || data is! List || data.isEmpty) {
        log('[TransactionRepo] getBalances: Nenhum dado de balanço ou formato inesperado.', name: 'REPO_WARNING');
        return DataResult.failure(const CacheException(code: 'no_balance_data'));
      }

      BalancesModel cachedBalances = BalancesModel.fromMap(Map<String, dynamic>.from(data.first as Map));
      
      log('[TransactionRepo] getBalances: Sucesso.', name: 'REPO');
      return DataResult.success(cachedBalances);
    } on Failure catch (e) {
      log('[TransactionRepo] getBalances: Falha (Failure) capturada: $e', name: 'REPO_ERROR');
      return DataResult.failure(e);
    } catch (e, stackTrace) {
      log('[TransactionRepo] getBalances: Exceção genérica capturada: $e', error:e, stackTrace: stackTrace, name: 'REPO_ERROR');
      return DataResult.failure(const CacheException( 
        code: 'repo_get_balances_generic_error',
      ));
    }
  }


  @override
  Future<DataResult<bool>> updateTransaction(
    TransactionModel transaction,
  ) async {
    log('[TransactionRepo] updateTransaction: Iniciando para ID: ${transaction.id}', name: 'REPO');
    try {
      await syncService.saveLocalChanges(
        path: TransactionRepository.transactionsPath,
        params:
            transaction.copyWith(syncStatus: SyncStatus.update).toDatabase(),
      );
      log('[TransactionRepo] updateTransaction: Sucesso para ID: ${transaction.id}', name: 'REPO');
      return DataResult.success(true);
    } on Failure catch (e) {
      log('[TransactionRepo] updateTransaction: Falha (Failure) capturada: $e', name: 'REPO_ERROR');
      return DataResult.failure(e);
    } catch (e, stackTrace) {
      log('[TransactionRepo] updateTransaction: Exceção genérica capturada: $e', error:e, stackTrace: stackTrace, name: 'REPO_ERROR');
      return DataResult.failure(const CacheException( 
        code: 'repo_update_generic_error',
      ));
    }
  }

  @override
  Future<DataResult<bool>> deleteTransaction(
      TransactionModel transaction) async {
    log('[TransactionRepo] deleteTransaction: Iniciando para ID: ${transaction.id}', name: 'REPO');
    try {
      await syncService.saveLocalChanges(
        path: TransactionRepository.transactionsPath,
        params:
            transaction.copyWith(syncStatus: SyncStatus.delete).toDatabase(),
      );
      log('[TransactionRepo] deleteTransaction: Marcado para deleção ID: ${transaction.id}', name: 'REPO');
      return DataResult.success(true); 
    } on Failure catch (e) {
      log('[TransactionRepo] deleteTransaction: Falha (Failure) capturada: $e', name: 'REPO_ERROR');
      return DataResult.failure(e);
    } catch (e, stackTrace) {
      log('[TransactionRepo] deleteTransaction: Exceção genérica capturada: $e', error:e, stackTrace: stackTrace, name: 'REPO_ERROR');
      return DataResult.failure(const CacheException( 
        code: 'repo_delete_generic_error',
      ));
    }
  }

  @override
  Future<DataResult<BalancesModel>> updateBalance({
    TransactionModel? oldTransaction,
    required TransactionModel newTransaction,
  }) async {
    log('[TransactionRepo] updateBalance: Iniciando', name: 'REPO');
    try {
      final balanceMap =
          await databaseService.read(path: TransactionRepository.balancesPath);

      final dynamic data = balanceMap['data'];
      if (data == null || data is! List || data.isEmpty) {
        log('[TransactionRepo] updateBalance: Nenhum dado de balanço ou formato inesperado.', name: 'REPO_WARNING');
        return DataResult.failure(const CacheException(code: 'no_balance_data_for_update'));
      }
      
      final current = BalancesModel.fromMap(Map<String, dynamic>.from(data.first as Map));

      double newTotalBalance = current.totalBalance;
      double newTotalIncome = current.totalIncome;
      double newTotalOutcome = current.totalOutcome;

      if (oldTransaction == null) { 
        if (newTransaction.value >= 0) { 
          newTotalIncome += newTransaction.value;
        } else { 
          newTotalOutcome += newTransaction.value.abs(); 
        }
      } else { 
        if (oldTransaction.value >= 0) {
          newTotalIncome -= oldTransaction.value;
        } else {
          newTotalOutcome -= oldTransaction.value.abs();
        }
        if (newTransaction.value >= 0) {
          newTotalIncome += newTransaction.value;
        } else {
          newTotalOutcome += newTransaction.value.abs();
        }
      }
      newTotalBalance = newTotalIncome - newTotalOutcome;

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

      final dynamic updateDataValue = updateBalanceResponse['data'];
      if (updateDataValue is! bool || !updateDataValue) {
        log('[TransactionRepo] updateBalance: Falha ao atualizar balanço no banco de dados.', name: 'REPO_ERROR');
        return DataResult.failure(const CacheException(code: 'balance_update_failed_db'));
      }
      
      log('[TransactionRepo] updateBalance: Sucesso.', name: 'REPO');
      return DataResult.success(
        BalancesModel.fromMap(updatedBalance),
      );
    } on Failure catch (e) {
      log('[TransactionRepo] updateBalance: Falha (Failure) capturada: $e', name: 'REPO_ERROR');
      return DataResult.failure(e);
    } catch (e, stackTrace) {
      log('[TransactionRepo] updateBalance: Exceção genérica capturada: $e', error:e, stackTrace: stackTrace, name: 'REPO_ERROR');
      return DataResult.failure(const CacheException( 
        code: 'repo_update_balance_generic_error',
      ));
    }
  }

  @override
  Future<DataResult<List<TransactionModel>>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    log('>>> [REPOSITORY] Querying DB for $startDate to $endDate', name: 'REPO');
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

      final dynamic data = cachedTransactionsResponse['data'];
       if (data == null || data is! List) {
        log('>>> [REPOSITORY] DB returned no data or unexpected format for $startDate - $endDate.', name: 'REPO_WARNING');
        return DataResult.success([]);
      }

      final parsedcachedTransactions = List<Map<String, dynamic>>.from(data.map((e) => Map<String,dynamic>.from(e as Map)));
      log('>>> [REPOSITORY] DB returned ${parsedcachedTransactions.length} raw items for $startDate - $endDate.', name: 'REPO_DEBUG');

      final cachedTransactions = parsedcachedTransactions
          .map((e) => TransactionModel.fromMap(e))
          .toList();

      log('>>> [REPOSITORY] Parsed ${cachedTransactions.length} transactions.', name: 'REPO_INFO');
      return DataResult.success(cachedTransactions);
    } on Failure catch (e) {
      log('>>> [REPOSITORY] DB query/parse FAILED (Failure) for $startDate - $endDate: $e', name: 'REPO_ERROR');
      return DataResult.failure(e);
    } catch (e, stackTrace) {
      log('>>> [REPOSITORY] DB query/parse FAILED (Generic Exception) for $startDate - $endDate: $e', error: e, stackTrace: stackTrace, name: 'REPO_ERROR');
      return DataResult.failure(const CacheException( 
        code: 'repo_get_range_generic_error',
      ));
    }
  }
}
