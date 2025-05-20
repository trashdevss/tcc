import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import 'package:tcc_3/common/data/exceptions.dart';
import 'package:tcc_3/services/data_service/data_service.dart';
// Ajuste os imports conforme sua estrutura
// Removido import do locator se não for usado diretamente aqui, pois o db é acessado via this.db
// import '../../locator.dart'; 

class DatabaseService implements DataService<Map<String, dynamic>> {
  // Se você registra DatabaseService no GetIt e o obtém via locator em outros lugares,
  // um construtor público simples é suficiente.
  // Se você usa este como um Singleton manual, o _internal e factory são apropriados.
  DatabaseService();

  static const _dbName = 'tcc_3.db';
  static const int _dbVersion = 1; // É bom versionar seu schema
  Database? _db;

  Database get db {
    if (_db == null || !_db!.isOpen) {
      log('DatabaseService: ERRO - Tentativa de acesso ao DB antes de estar inicializado ou após ser fechado.', name: 'DB_SERVICE_ERROR');
      throw StateError('DatabaseService não inicializado ou DB fechado. Chame init() e aguarde sua conclusão primeiro.');
    }
    return _db!;
  }

  Future<void> get deleteDB async {
    log('DELETING DATABASE $_dbName', name: 'DB_SERVICE', time: DateTime.now());
    await close(); 
    try {
        String path = await getDatabasesPath();
        await deleteDatabase('$path/$_dbName');
        log('DATABASE $_dbName DELETED SUCCESSFULLY', name: 'DB_SERVICE');
    } catch (e) {
        log('ERROR DELETING DATABASE $_dbName: $e', name: 'DB_SERVICE_ERROR');
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
      String path = await getDatabasesPath();
      _db = await openDatabase(
        '$path/$_dbName',
        version: _dbVersion,
        onCreate: (Database db, int version) async {
          log('DatabaseService: onCreate - Criando tabelas (versão $version)...', name: 'DB_SERVICE');
          await db.execute(
              'CREATE TABLE IF NOT EXISTS transactions (id TEXT PRIMARY KEY, description TEXT, category TEXT, status INTEGER, value NUMERIC, date TEXT, created_at TEXT, user_id TEXT, sync_status TEXT)');
          await db.execute(
              'CREATE TABLE IF NOT EXISTS balances (id INTEGER PRIMARY KEY DEFAULT 1, total_balance NUMERIC DEFAULT 0, total_income NUMERIC DEFAULT 0, total_outcome NUMERIC DEFAULT 0)');
          log('DatabaseService: Tabelas criadas/verificadas.', name: 'DB_SERVICE');
          await _insertInitialBalanceRecord(db);
        },
        onOpen: (Database db) async {
            log('DatabaseService: onOpen - Verificando tabela balances...', name: 'DB_SERVICE');
            await _insertInitialBalanceRecord(db); // Garante que o balanço exista ao abrir também
        }
      );
      log('DatabaseService: init concluído com sucesso. DB Path: ${db.path}', name: 'DB_SERVICE');
    } catch (e, stackTrace) {
      log('DatabaseService: Erro ao inicializar o banco de dados: $e', name: 'DB_SERVICE_ERROR', stackTrace: stackTrace);
      rethrow; 
    }
    return this;
  }

  Future<void> _insertInitialBalanceRecord(Database currentDb) async {
      final count = Sqflite.firstIntValue(await currentDb.rawQuery('SELECT COUNT(*) FROM balances'));
      if (count == 0) {
          log('DatabaseService: Tabela balances está vazia. Inserindo registro inicial.', name: 'DB_SERVICE');
          try {
            await currentDb.insert(
                'balances',
                {
                    'total_balance': 0.0,
                    'total_income': 0.0,
                    'total_outcome': 0.0,
                },
                conflictAlgorithm: ConflictAlgorithm.ignore 
            );
            log('DatabaseService: Registro inicial inserido em balances.', name: 'DB_SERVICE');
          } catch (e, stackTrace) {
            log('DatabaseService: Erro ao inserir registro inicial em balances: $e', name: 'DB_SERVICE_ERROR', stackTrace: stackTrace);
          }
      } else {
            log('DatabaseService: Tabela balances já contém dados (count: $count).', name: 'DB_SERVICE');
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
          log('[DB_SERVICE] create (update existing transaction): Path=$path, ID=$id', name: 'DB_OPS');
          final result = await db.update(path, params, where: 'id = ?', whereArgs: [id]);
          return {'data': result != 0};
        } else {
          log('[DB_SERVICE] create (insert new transaction): Path=$path, ID=$id', name: 'DB_OPS');
          final result = await db.insert(path, params, conflictAlgorithm: ConflictAlgorithm.replace);
          return {'data': result != 0};
        }
      } else if (path == 'balances') { 
          log('[DB_SERVICE] create (upserting balances): Path=$path', name: 'DB_OPS');
          final result = await db.update(path, params); 
          if (result > 0) {
            return {'data': true};
          } else {
            log('[DB_SERVICE] create (update balances failed, trying insert): Path=$path', name: 'DB_OPS_WARN');
            final insertResult = await db.insert(path, params, conflictAlgorithm: ConflictAlgorithm.replace);
            return {'data': insertResult != 0};
          }
      } else { 
            log('[DB_SERVICE] create (generic insert for path without ID): Path=$path', name: 'DB_OPS');
            final result = await db.insert(path, params, conflictAlgorithm: ConflictAlgorithm.replace);
            return {'data': result != 0};
      }
    } catch (e, stackTrace) {
      log('[DB_SERVICE] create: Erro: $e', name: 'DB_OPS_ERROR', stackTrace: stackTrace);
      // CORRIGIDO: Removido o parâmetro 'message'
      throw const CacheException(code: 'write'); 
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

        if (params.containsKey('start_date') &&
            params.containsKey('end_date')) {
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
        
        log('[DB_SERVICE] read: Querying with Where="$whereClause", Args=$whereArgs', name: 'DB_OPS_DETAIL');
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
      // CORRIGIDO: Removido o parâmetro 'message'
      throw const CacheException(code: 'read');
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
        log('[DB_SERVICE] update (updating balances): Path=$path', name: 'DB_OPS');
        final result = await db.update(path, params);
        return {'data': result != 0};
      } else {
         log('[DB_SERVICE] update (no ID in params or unknown path for specific logic): Path=$path', name: 'DB_OPS_WARN');
         final result = await db.update(path, params); 
         return {'data': result != 0};
      }
    } catch (e, stackTrace) {
      log('[DB_SERVICE] update: Erro: $e', name: 'DB_OPS_ERROR', stackTrace: stackTrace);
      // CORRIGIDO: Removido o parâmetro 'message'
      throw const CacheException(code: 'update');
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
        log('[DB_SERVICE] delete (no ID in params, deleting all from path!): Path=$path', name: 'DB_OPS_WARNING');
        final result = await db.delete(path);
        return {'data': result != 0};
      }
    } catch (e, stackTrace) {
      log('[DB_SERVICE] delete: Erro: $e', name: 'DB_OPS_ERROR', stackTrace: stackTrace);
      // CORRIGIDO: Removido o parâmetro 'message'
      throw const CacheException(code: 'delete');
    }
  }
}
