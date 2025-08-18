// lib/features/achievements/models/achievement_model.dart

import 'package:flutter/foundation.dart';

@immutable
class AchievementModel {
  final String id;
  final String title;
  final String description; // O que o usuário fez para ganhar
  final String imagePath;   // O ícone/imagem do badge (ex: 'assets/images/achievements/trophy.png')
  final bool isUnlocked;    // Para a UI saber se mostra colorido ou em tons de cinza

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.isUnlocked = false,
  });

  // Um método helper para facilmente criar uma cópia desbloqueada da conquista
  AchievementModel unlock() {
    return AchievementModel(
      id: id,
      title: title,
      description: description,
      imagePath: imagePath,
      isUnlocked: true,
    );
  }
}