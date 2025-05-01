import 'dart:convert';
import 'package:uuid/uuid.dart';
// Certifique-se que este import contém a extensão '.toInt()' para booleanos
// e outras extensões que você possa usar.
import '../extensions/extensions.dart'; 

// Enum para status de sincronização (mantido como estava)
enum SyncStatus {
  none,
  synced,
  create,
  update,
  delete,
}

// Classe TransactionModel (completa)
class TransactionModel {
  TransactionModel({
    required this.category,
    required this.description,
    required this.value,
    required this.date,
    required this.status, // Deve ser sempre bool aqui
    required this.createdAt,
    this.id,
    this.userId,
    // Se syncStatus pode ser null no banco, defina um padrão aqui também
    this.syncStatus = SyncStatus.synced, 
  });

  final String description;
  final String category;
  final double value;
  final int date; // Armazenado como millisecondsSinceEpoch
  final bool status; // Armazenado como true (feita) ou false (pendente)
  final int createdAt; // Armazenado como millisecondsSinceEpoch
  final String? id;
  final String? userId;
  final SyncStatus? syncStatus;

  /// Usado para enviar dados ao Hasura nas mutations (mantido como estava)
  Map<String, dynamic> toGraphQLInput() {
    return <String, dynamic>{
      'id': id ?? const Uuid().v4(),
      'description': description,
      'category': category,
      'value': value,
      'date': DateTime.fromMillisecondsSinceEpoch(date).toIso8601String(),
      'created_at': DateTime.fromMillisecondsSinceEpoch(createdAt).toIso8601String(),
      'status': status, // Envia como booleano
      'user_id': userId ?? '',
    };
  }

  /// Usado para persistência no banco de dados local (mantido como estava)
  Map<String, dynamic> toDatabase() {
    return <String, dynamic>{
      'id': id ?? const Uuid().v4(),
      'description': description,
      'category': category,
      'value': value,
      'date': DateTime.fromMillisecondsSinceEpoch(date).toIso8601String(), // Salva como String ISO
      'created_at': DateTime.fromMillisecondsSinceEpoch(createdAt).toIso8601String(), // Salva como String ISO
      'status': status.toInt(), // Converte bool para int (ex: 1 ou 0) para salvar
      'user_id': userId,
      'sync_status': syncStatus?.name ?? SyncStatus.none.name, // Garante que não seja null
    };
  }

  // --- CONSTRUTOR fromMap CORRIGIDO ---
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // Lógica segura para fazer o parse do status vindo do banco
    bool finalStatus = false; // Começa assumindo 'false' (pendente) como padrão
    final dynamic statusFromMap = map['status']; // Pega o valor do mapa sem erro se for null

    if (statusFromMap is int) {
      // Se for inteiro, considera 1 como true, qualquer outro (incluindo 0) como false
      finalStatus = (statusFromMap == 1);
    } else if (statusFromMap is bool) {
      // Se já for booleano, usa o valor diretamente
      finalStatus = statusFromMap;
    }
    // Se for null ou qualquer outro tipo, mantém o padrão 'false'

    // Lógica segura para fazer o parse das datas vindas do banco (assumindo ISO String)
    int parseDate(String? dateString) {
      if (dateString == null) return DateTime(1970).millisecondsSinceEpoch; // Data padrão muito antiga
      try {
        return DateTime.parse(dateString).millisecondsSinceEpoch;
      } catch (e) {
        // print('Erro ao fazer parse da data "$dateString": $e'); // Log de erro opcional
        return DateTime(1970).millisecondsSinceEpoch; // Retorna padrão em caso de erro
      }
    }

    return TransactionModel(
      // Usa ?? '' para evitar null em campos String obrigatórios
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      // Usa tryParse para valor double
      value: double.tryParse(map['value']?.toString() ?? '0.0') ?? 0.0, 
      // Usa a função segura para parse das datas
      date: parseDate(map['date']?.toString()),
      createdAt: parseDate(map['created_at']?.toString()),
      
      status: finalStatus, // Usa o status que foi tratado com segurança
      
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      // Trata o sync_status
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['sync_status'],
        orElse: () => SyncStatus.none, // Padrão se não encontrar ou for null
      ),
    );
  }
  // --- Fim do fromMap corrigido ---

  String toJson() => json.encode(toGraphQLInput());

  factory TransactionModel.fromJson(String source) =>
      TransactionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  TransactionModel copyWith({
    String? description,
    String? category,
    double? value,
    int? date,
    bool? status,
    int? createdAt,
    String? id,
    String? userId,
    SyncStatus? syncStatus,
  }) {
    return TransactionModel(
      description: description ?? this.description,
      category: category ?? this.category,
      value: value ?? this.value,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      id: id ?? this.id ?? const Uuid().v4(), // Garante que id não seja null ao copiar
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Métodos == e hashCode (mantidos como estavam)
  @override
  bool operator ==(covariant TransactionModel other) {
    if (identical(this, other)) return true;

    return other.description == description &&
        other.category == category &&
        other.value == value &&
        other.date == date &&
        other.status == status &&
        other.id == id &&
        other.userId == userId &&
        other.createdAt == createdAt &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return description.hashCode ^
        category.hashCode ^
        value.hashCode ^
        date.hashCode ^
        createdAt.hashCode ^
        status.hashCode ^
        id.hashCode ^
        userId.hashCode ^
        syncStatus.hashCode;
  }
}

// --- Exemplo da extensão .toInt() (se não a tiver definido em outro lugar) ---
// Coloque isso em um arquivo de extensão apropriado, ex: lib/common/extensions/bool_extensions.dart
/*
extension BoolExtensions on bool {
  int toInt() => this ? 1 : 0;
}
*/