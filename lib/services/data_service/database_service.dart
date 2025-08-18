import 'dart:developer';
import 'package:path/path.dart'; // Import necessário para a função join
import 'package:sqflite/sqflite.dart';
// Ajuste os caminhos dos imports abaixo conforme a estrutura do seu projeto:
import 'package:tcc_3/common/data/exceptions.dart';
import 'package:tcc_3/services/data_service/data_service.dart';

class DatabaseService implements DataService<Map<String, dynamic>> {
  DatabaseService();

  static const String _dbName = 'tcc_3.db';
  static const int _dbVersion = 1; // Incremente se fizer alterações no schema (e use onUpgrade)
  Database? _db;

  Database get db {
    if (_db == null || !_db!.isOpen) {
      log('DatabaseService: ERRO - Tentativa de acesso ao DB antes de estar inicializado ou após ser fechado.', name: 'DB_SERVICE_ERROR');
      throw StateError('DatabaseService não inicializado ou DB fechado. Chame init() e aguarde sua conclusão primeiro.');
    }
    return _db!;
  }

  Future<void> get deleteDB async {
    log('DELETANDO DATABASE $_dbName', name: 'DB_SERVICE', time: DateTime.now());
    await close();
    try {
      String path = await getDatabasesPath();
      await deleteDatabase(join(path, _dbName)); // Usar join para consistência
      log('DATABASE $_dbName DELETADO COM SUCESSO', name: 'DB_SERVICE');
    } catch (e) {
      log('ERRO AO DELETAR DATABASE $_dbName: $e', name: 'DB_SERVICE_ERROR');
    }
    _db = null;
  }

  Future<DatabaseService> init() async {
    log('DatabaseService: init chamado', name: 'DB_SERVICE');
    if (_db != null && _db!.isOpen) {
      log('DatabaseService: Database já está aberto.', name: 'DB_SERVICE');
      return this;
    }

    try {
      String dbPath = await getDatabasesPath();
      _db = await openDatabase(
        join(dbPath, _dbName), // Usar join para construir o path
        version: _dbVersion,
        onCreate: (Database db, int version) async {
          log('DatabaseService: onCreate - Criando tabelas (versão $version)...', name: 'DB_SERVICE');
          // Criação da tabela de transações
          await db.execute(
              'CREATE TABLE IF NOT EXISTS transactions (id TEXT PRIMARY KEY, description TEXT, category TEXT, status INTEGER, value NUMERIC, date TEXT, created_at TEXT, user_id TEXT, sync_status TEXT)');
          // Criação da tabela de balanços (saldos) - ESSENCIAL PARA CORRIGIR O ERRO
          await db.execute(
              'CREATE TABLE IF NOT EXISTS balances (id INTEGER PRIMARY KEY DEFAULT 1, total_balance NUMERIC DEFAULT 0, total_income NUMERIC DEFAULT 0, total_outcome NUMERIC DEFAULT 0)');
          log('DatabaseService: Tabelas criadas/verificadas.', name: 'DB_SERVICE');
          // Insere o registro inicial na tabela de balanços APÓS a criação da tabela
          await _insertInitialBalanceRecord(db);
        },
        onOpen: (Database db) async {
          log('DatabaseService: onOpen - Verificando tabela balances...', name: 'DB_SERVICE');
          // Garante que o registro de balanço exista ao abrir o DB também (robustez)
          await _insertInitialBalanceRecord(db);
        },
        // onUpgrade: (Database db, int oldVersion, int newVersion) async {
        //   // Se você mudar _dbVersion, adicione a lógica de migração aqui
        //   log('DatabaseService: onUpgrade - Atualizando de $oldVersion para $newVersion', name: 'DB_SERVICE');
        //   if (oldVersion < NEW_VERSION_WHERE_BALANCES_WAS_ADDED) {
        //      await db.execute('CREATE TABLE IF NOT EXISTS balances (id INTEGER PRIMARY KEY DEFAULT 1, ...)')
        //      await _insertInitialBalanceRecord(db);
        //   }
        // },
      );
      log('DatabaseService: init concluído com sucesso. DB Path: ${_db?.path}', name: 'DB_SERVICE');
    } catch (e, stackTrace) {
      log('DatabaseService: Erro ao inicializar o banco de dados: $e', name: 'DB_SERVICE_ERROR', stackTrace: stackTrace);
      rethrow; // Re-lança a exceção para que a camada superior possa tratá-la
    }
    return this;
  }

  Future<void> _insertInitialBalanceRecord(Database currentDb) async {
    try {
      final count = Sqflite.firstIntValue(await currentDb.rawQuery('SELECT COUNT(*) FROM balances'));
      if (count == 0) {
        log('DatabaseService: Tabela balances está vazia. Inserindo registro inicial.', name: 'DB_SERVICE');
        await currentDb.insert(
          'balances',
          {
            // 'id' não é explicitamente necessário aqui devido ao 'DEFAULT 1' na DDL
            'total_balance': 0.0,
            'total_income': 0.0,
            'total_outcome': 0.0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        log('DatabaseService: Registro inicial inserido em balances.', name: 'DB_SERVICE');
      } else {
        log('DatabaseService: Tabela balances já contém dados (count: $count).', name: 'DB_SERVICE');
      }
    } catch (e, stackTrace) {
        // Se a tabela não existir aqui, o erro original "no such table" ainda pode ocorrer
        // se _insertInitialBalanceRecord for chamado antes de onCreate completar ou em um contexto errado.
        // No entanto, com a chamada dentro de onCreate e onOpen (após onCreate ter rodado na primeira vez),
        // a tabela já deve existir.
        log('DatabaseService: Erro em _insertInitialBalanceRecord (verifique se a tabela "balances" existe): $e', name: 'DB_SERVICE_ERROR', stackTrace: stackTrace);
        // Não relance aqui necessariamente, pois pode ser uma verificação opcional em onOpen.
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
      log('DatabaseService: Conexão com o banco de dados fechada.', name: 'DB_SERVICE');
    }
  }

  @override
  Future<Map<String, dynamic>> create({
    required String path,
    Map<String, dynamic> params = const {},
  }) async {
    log('[DB_SERVICE] create: Path=$path, Params=$params', name: 'DB_OPS');
    try {
      if (params.containsKey('id') && path == 'transactions') {
        final id = params['id'];
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) from $path WHERE id = ?', [id]),
        );

        if (count != null && count > 0) {
          final result = await db.update(path, params, where: 'id = ?', whereArgs: [id]);
          return {'data': result != 0};
        } else {
          final result = await db.insert(path, params, conflictAlgorithm: ConflictAlgorithm.replace);
          return {'data': result != 0};
        }
      } else if (path == 'balances') {
        final result = await db.update(path, params, where: 'id = ?', whereArgs: [params['id'] ?? 1]);
        if (result > 0) {
          return {'data': true};
        } else {
          final insertResult = await db.insert(path, params, conflictAlgorithm: ConflictAlgorithm.replace);
          return {'data': insertResult != 0};
        }
      } else {
        final result = await db.insert(path, params, conflictAlgorithm: ConflictAlgorithm.replace);
        return {'data': result != 0};
      }
    } catch (e, stackTrace) {
      log('[DB_SERVICE] create: Erro: $e', name: 'DB_OPS_ERROR', stackTrace: stackTrace);
      throw CacheException(code: 'write',); // Adicionando a mensagem original da exceção
    }
  }

  @override
  Future<Map<String, dynamic>> read({
    required String path,
    Map<String, dynamic> params = const {},
  }) async {
    log('[DB_SERVICE] read: Path=$path, Params=$params', name: 'DB_OPS');
    try {
      if (params.containsKey('id')) {
        final result = await db.query(
          path,
          where: 'id = ?',
          whereArgs: [params['id']],
        );
        return {'data': result};
      } else {
        String whereClause = '';
        List<dynamic> whereArgs = [];

        if (params.containsKey('start_date') && params.containsKey('end_date')) {
          whereClause = 'date BETWEEN ? AND ?';
          whereArgs = [params['start_date'], params['end_date']];
        }

        if (params.containsKey('skip_status')) {
          if (whereClause.isNotEmpty) {
            whereClause += ' AND ';
          }
          whereClause += 'sync_status != ?';
          whereArgs.add(params['skip_status']);
        }
        
        final result = await db.query(
          path,
          limit: params['limit'] as int?,
          offset: params['offset'] as int?,
          orderBy: params['order_by'] as String?,
          where: whereClause.isEmpty ? null : whereClause,
          whereArgs: whereArgs.isEmpty ? null : whereArgs,
        );
        return {'data': result};
      }
    } catch (e, stackTrace) {
      log('[DB_SERVICE] read: Erro: $e', name: 'DB_OPS_ERROR', stackTrace: stackTrace);
      throw CacheException(code: 'read',);
    }
  }

  @override
  Future<Map<String, dynamic>> update({
    required String path,
    Map<String, dynamic> params = const {},
  }) async {
    log('[DB_SERVICE] update: Path=$path, Params=$params', name: 'DB_OPS');
    try {
      if (params.containsKey('id') && path == 'transactions') {
        final id = params['id'];
        final result = await db.update(
          path,
          params,
          where: 'id = ?',
          whereArgs: [id],
        );
        return {'data': result != 0};
      } else if (path == 'balances'){
        final result = await db.update(path, params, where: 'id = ?', whereArgs: [params['id'] ?? 1]);
        return {'data': result != 0};
      } else {
         // Para updates genéricos, é mais seguro exigir um 'id' ou uma cláusula 'where' explícita
         // Se 'id' estiver em params, use-o para o 'where'.
         if (params.containsKey('id')) {
            final result = await db.update(path, params, where: 'id = ?', whereArgs: [params['id']]);
            return {'data': result != 0};
         } else {
            // Atualizar sem 'where' é perigoso, pois afeta todas as linhas.
            // Considere lançar um erro ou logar um aviso mais forte se isso não for intencional.
            log('[DB_SERVICE] update (WARNING: updating all rows in $path as no ID/WHERE provided)', name: 'DB_OPS_DANGER');
            final result = await db.update(path, params); 
            return {'data': result != 0};
         }
      }
    } catch (e, stackTrace) {
      log('[DB_SERVICE] update: Erro: $e', name: 'DB_OPS_ERROR', stackTrace: stackTrace);
      throw CacheException(code: 'update');
    }
  }

  @override
  Future<Map<String, dynamic>> delete({
    required String path,
    Map<String, dynamic> params = const {},
  }) async {
    log('[DB_SERVICE] delete: Path=$path, Params=$params', name: 'DB_OPS');
    try {
      if (params.containsKey('id')) {
        final result = await db.delete(
          path,
          where: 'id = ?',
          whereArgs: [params['id']],
        );
        return {'data': result != 0};
      } else {
        log('[DB_SERVICE] delete (WARNING: no ID in params, deleting all from path!): Path=$path', name: 'DB_OPS_WARNING');
        final result = await db.delete(path);
        return {'data': result != 0};
      }
    } catch (e, stackTrace) {
      log('[DB_SERVICE] delete: Erro: $e', name: 'DB_OPS_ERROR', stackTrace: stackTrace);
      throw CacheException(code: 'delete');
    }
  }
}