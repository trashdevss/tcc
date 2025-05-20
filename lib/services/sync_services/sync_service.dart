import 'dart:developer';

import '../../common/constants/constants.dart';
import '../../common/data/data.dart';
import '../../common/extensions/types_ext.dart';
import '../../common/models/models.dart';
import '../../repositories/repositories.dart';
import '../services.dart'; // Assume que GraphQLService, DatabaseService, etc., estão aqui

// As exportações podem ser mantidas se você as usa em outros lugares
export 'sync_controller.dart';
export 'sync_state.dart';

class SyncService {
  const SyncService({
    required this.connectionService,
    required this.databaseService,
    required this.graphQLService,
    required this.secureStorageService,
  });

  final ConnectionService connectionService;
  final DatabaseService databaseService; // Seu DatabaseService
  final GraphQLService graphQLService;   // Seu GraphQLService
  final SecureStorageService secureStorageService;

  Future<DataResult<void>> syncFromServer() async {
    log('syncFromServer called', name: 'INFO');
    await connectionService.checkConnection();
    if (!connectionService.isConnected) return DataResult.success(null);
    final needSync = await secureStorageService.readOne(key: 'NEED_SYNC');
    if (needSync == null || (needSync.toBool() == false)) {
        log('syncFromServer: No need to sync from server.', name: 'INFO');
        return DataResult.success(null);
    }

    try {
      await _syncBalanceFromServer();
      await _syncTransactionsFromServer();
      await secureStorageService.write(
        key: 'NEED_SYNC',
        value: false.toString(),
      );

      return DataResult.success(null);
    } catch (e) {
      log('syncFromServer exception $e', name: 'ERROR');
      // CORRIGIDO: Removido o parâmetro 'message' se SyncException não o define.
      return DataResult.failure(const SyncException(code: 'error_sync_from_server'));
    }
  }

  Future<void> _syncTransactionsFromServer() async {
    final clock = Stopwatch();
    log('_syncTransactionsFromServer called', name: 'INFO');

    final localUnsyncedTransactions = await _getLocalTransactions(onlyUnsynced: true);
    if (localUnsyncedTransactions.isNotEmpty) {
        log('_syncTransactionsFromServer: Found ${localUnsyncedTransactions.length} unsynced local transactions. Skipping server download for now.', name: 'INFO');
        return;
    }

    final transactionsFromServerResponse = await graphQLService.read(
      path: Queries.qGetTrasactions,
    );

    final dynamic transactionData = transactionsFromServerResponse['transaction'];
    if (transactionData == null || transactionData is! List) {
        log('_syncTransactionsFromServer: No transaction data or unexpected format from server.', name: 'WARNING');
        return;
    }

    final parsedTransactionsFromServer = List.from(transactionData);
    final transactionsFromServer = parsedTransactionsFromServer
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (transactionsFromServer.isEmpty) {
        log('_syncTransactionsFromServer: No transactions to sync from server.', name: 'INFO');
        return;
    }

    clock.start();
    for (var t in transactionsFromServer) {
      await saveLocalChanges(
        path: TransactionRepository.transactionsPath,
        params: t.copyWith(syncStatus: SyncStatus.synced).toDatabase(),
      );
    }
    clock.stop();
    log('Total time to sync ${transactionsFromServer.length} transactions from server: ${clock.elapsed.inMilliseconds}ms',
        name: 'INFO');
  }

  Future<void> _syncBalanceFromServer() async {
    log('_syncBalanceFromServer called', name: 'INFO');
    final localBalanceResponse =
        (await databaseService.read(path: TransactionRepository.balancesPath));

    if ((localBalanceResponse['data'] as List).isNotEmpty) {
        log('_syncBalanceFromServer: Local balance already exists. Skipping server download.', name: 'INFO');
        return;
    }

    final remoteBalanceResponse =
        await graphQLService.read(path: Queries.qGetBalances);

    if (remoteBalanceResponse.isEmpty || remoteBalanceResponse['data'] == null ) {
        log('_syncBalanceFromServer: No balance data from server or unexpected format.', name: 'WARNING');
        return;
    }
    
    final dynamic balanceData = remoteBalanceResponse['balances'];
    if (balanceData == null || (balanceData is List && balanceData.isEmpty)) {
        log('_syncBalanceFromServer: No balance data in server response.', name: 'WARNING');
        return;
    }

    BalancesModel balances;
    if (balanceData is List) {
        balances = BalancesModel.fromMap(Map<String, dynamic>.from(balanceData.first as Map));
    } else if (balanceData is Map) {
        balances = BalancesModel.fromMap(Map<String, dynamic>.from(balanceData));
    } else {
        log('_syncBalanceFromServer: Unexpected balance data format from server.', name: 'WARNING');
        return;
    }

    await saveLocalChanges(
      path: TransactionRepository.balancesPath,
      params: balances.toMap(),
    );
  }

  Future<void> saveLocalChanges({
    required String path,
    required Map<String, Object?> params,
  }) async {
    log('[SyncService] saveLocalChanges: Path=$path, Params=$params', name: 'DEBUG');
    try {
      final response = await databaseService.create(
        path: path,
        params: params,
      );

      final dynamic dataValue = response['data'];

      if (dataValue is bool) {
        if (!dataValue) {
          log('[SyncService] saveLocalChanges: databaseService.create retornou false para $path.', name: 'WARNING');
          throw const CacheException(code: 'write_failed_response_false');
        }
        log('[SyncService] saveLocalChanges: Sucesso para $path.', name: 'INFO');
      } else {
        log('[SyncService] saveLocalChanges: response[\'data\'] não é um booleano ou é nulo. Path: $path, Valor: $dataValue', name: 'ERROR');
        // CORRIGIDO: Removido o parâmetro 'message'
        throw CacheException(code: 'write_unexpected_response_type');
      }

      await secureStorageService.write(
        key: 'NEED_SYNC',
        value: true.toString(),
      );
    } catch (e, stackTrace) {
      log('[SyncService] saveLocalChanges: Erro ao salvar localmente para $path: $e', error: e, stackTrace: stackTrace, name: 'ERROR');
      rethrow;
    }
  }

  Future<DataResult<void>> syncToServer() async {
    log('syncToServer called', name: 'INFO');
    await connectionService.checkConnection();

    if (!connectionService.isConnected) {
        log('syncToServer: No connection, skipping sync.', name: 'INFO');
        return DataResult.success(null);
    }

    List<TransactionModel> localTransactions = await _getLocalTransactions(onlyUnsynced: true);

    if (localTransactions.isEmpty) {
        log('syncToServer: No local changes to sync.', name: 'INFO');
        return DataResult.success(null);
    }
    
    log('syncToServer: Found ${localTransactions.length} local transactions to sync.', name: 'INFO');

    try {
      for (final t in localTransactions) {
        log('syncToServer: Syncing transaction ID ${t.id}, Status: ${t.syncStatus}', name: 'DEBUG');
        await _syncLocalTransactionsToServer(t);
        
        if (t.syncStatus == SyncStatus.delete) {
          await databaseService.delete(
            path: TransactionRepository.transactionsPath,
            params: {'id': t.id});
          log('syncToServer: Deleted transaction ID ${t.id} locally after server sync.', name: 'INFO');
        } else {
          await saveLocalChanges(
            path: TransactionRepository.transactionsPath,
            params: t.copyWith(syncStatus: SyncStatus.synced).toDatabase(),
          );
          log('syncToServer: Marked transaction ID ${t.id} as synced locally.', name: 'INFO');
        }
      }

      await secureStorageService.write(
        key: 'NEED_SYNC',
        value: false.toString(),
      );
      log('syncToServer: All local changes synced. NEED_SYNC set to false.', name: 'INFO');
      return DataResult.success(null);
    } catch (e, stackTrace) {
      log('syncToServer exception: $e', error: e, stackTrace: stackTrace, name: 'ERROR');
      // CORRIGIDO: Removido o parâmetro 'message'
      return DataResult.failure(SyncException(code: 'error_sync_to_server'));
    }
  }

  Future<List<TransactionModel>> _getLocalTransactions({bool onlyUnsynced = false}) async {
    try {
        final response = await databaseService.read(
            path: TransactionRepository.transactionsPath,
        );

        final dynamic data = response['data'];
        if (data == null || data is! List) {
            log('_getLocalTransactions: No data or unexpected format from databaseService.read.', name: 'WARNING');
            return [];
        }

        final List<Map<String, dynamic>> transactionsMaps = List<Map<String, dynamic>>.from(data.map((e) => Map<String,dynamic>.from(e as Map)));

        final parsedTransactions = transactionsMaps.map((change) {
        return TransactionModel.fromMap(change);
        }).toList();

        if (onlyUnsynced) {
            final localChanges = parsedTransactions
                .where((t) => t.syncStatus != SyncStatus.synced && t.syncStatus != SyncStatus.none)
                .toList();
            log('_getLocalTransactions: Found ${localChanges.length} unsynced transactions.', name: 'DEBUG');
            return localChanges;
        }
        log('_getLocalTransactions: Found ${parsedTransactions.length} total local transactions.', name: 'DEBUG');
        return parsedTransactions;

    } catch (e, stackTrace) {
        log('_getLocalTransactions: Error reading local transactions: $e', error: e, stackTrace: stackTrace, name: 'ERROR');
        return [];
    }
  }

  Future<void> _syncLocalTransactionsToServer(
    TransactionModel localTransaction,
  ) async {
    log('_syncLocalTransactionsToServer called for transaction ID ${localTransaction.id}, Status: ${localTransaction.syncStatus}', name: 'INFO');
    try {
      var response = {};

      switch (localTransaction.syncStatus) {
        case SyncStatus.create:
          response = await graphQLService.create(
            path: Mutations.mAddNewTransaction,
            params: localTransaction.toGraphQLInput(),
          );
          break;
        case SyncStatus.update:
          final input = localTransaction.toGraphQLInput();
          input.removeWhere((key, value) => key == 'user_id' || key == 'id');
          response = await graphQLService.update(
            path: Mutations.mUpdateTransaction,
            params: {'id': localTransaction.id, '_set': input},
          );
          break;
        case SyncStatus.delete:
          response = await graphQLService.delete(
            path: Mutations.mDeleteTransaction,
            params: {'id': localTransaction.id},
          );
          break;
        default:
          log('_syncLocalTransactionsToServer: SyncStatus desconhecido ou não requer ação: ${localTransaction.syncStatus}', name: 'WARNING');
          return;
      }

      if (response.isEmpty && (localTransaction.syncStatus != SyncStatus.synced && localTransaction.syncStatus != SyncStatus.none)) {
        log('_syncLocalTransactionsToServer: Empty response from GraphQLService for ${localTransaction.syncStatus} on ID ${localTransaction.id}', name: 'ERROR');
        // CORRIGIDO: Removido o parâmetro 'message'
        throw SyncException(code: 'graphql_empty_response');
      }
      log('_syncLocalTransactionsToServer: Successfully synced transaction ID ${localTransaction.id} with status ${localTransaction.syncStatus}', name: 'INFO');

    } catch (e, stackTrace) {
      log('_syncLocalTransactionsToServer exception for ID ${localTransaction.id}: $e', error: e, stackTrace: stackTrace, name: 'ERROR');
      rethrow;
    }
  }
}
