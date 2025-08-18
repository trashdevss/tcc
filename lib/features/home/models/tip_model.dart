import 'package:flutter/foundation.dart'; // Para @immutable

@immutable
class TipActionModel {
  final String? type; // navigateTo, showInfo, openUrl, etc. (nullable)
  final String? value; // Rota, chave de info, URL (nullable)

  const TipActionModel({this.type, this.value});

  // Factory para criar a partir do JSON (Map)
  // Retorna null se o JSON for null
  static TipActionModel? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null; // Sem ação definida
    }
    return TipActionModel(
      type: json['type'] as String?,
      value: json['value'] as String?,
    );
  }
}

@immutable
class TipModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl; // Por enquanto, String
  final TipActionModel? action; // Pode ser nulo

  const TipModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.action,
  });

  // Factory para criar a partir do JSON (Map)
  factory TipModel.fromJson(Map<String, dynamic> json) {
    return TipModel(
      id: json['id'] as String? ?? '', // Lida com ID nulo se acontecer
      title: json['title'] as String? ?? 'Sem Título',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '', // Lida com URL nula
      action: TipActionModel.fromJson(json['action'] as Map<String, dynamic>?), // Lida com action nulo
    );
  }
}