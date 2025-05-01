// lib/models/goal.dart

// Não precisa mais importar 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;          // ID (UUID ou o que o Hasura retornar)
  final String userId;      // ID do usuário (deve vir do Hasura agora)
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime createdAt; // Usaremos DateTime

  // Construtor principal
  Goal({
    required this.id,
    required this.userId, // Incluído para referência, se necessário
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.createdAt,
  });

  // Getters úteis
  double get progressFraction => (targetAmount > 0) ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  int get progressPercentage => (progressFraction * 100).toInt();
  bool get isCompleted => currentAmount >= targetAmount;

  // Factory constructor para criar a partir do Map JSON vindo do GraphQL/Hasura
  factory Goal.fromJson(Map<String, dynamic> json) {
    try {
      return Goal(
        id: json['id']?.toString() ?? '', // Hasura retorna UUID como string
        userId: json['user_id'] ?? '', // Nome da coluna no Hasura
        name: json['name'] ?? 'Meta sem nome',
        // Hasura retorna numeric/float como double ou int
        targetAmount: (json['target_amount'] ?? 0.0).toDouble(),
        currentAmount: (json['current_amount'] ?? 0.0).toDouble(),
        // Hasura retorna timestamp com timezone como String ISO 8601. Precisamos parsear.
        createdAt: json['created_at'] != null
                     ? DateTime.parse(json['created_at']) // Parse da String ISO
                     : DateTime.now(), // Fallback para data atual
      );
    } catch (e) {
      print("Erro ao parsear Goal do JSON: $e - JSON: $json");
      // Retorna um Goal 'inválido' ou lança exceção, dependendo do tratamento desejado
      // Aqui, retornamos um padrão para evitar quebrar o app inteiro, mas idealmente logaríamos o erro.
      return Goal(id: '', userId: '', name: 'Erro no Parse', targetAmount: 0, createdAt: DateTime.now());
    }
  }
}