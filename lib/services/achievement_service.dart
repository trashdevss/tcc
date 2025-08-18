// lib/services/achievement_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Seus imports (garanta que os caminhos estão corretos)
import 'package:tcc_3/common/widgets/custom_snackbar.dart';
import 'package:tcc_3/features/achievements/data/all_achievements_data.dart';
import 'package:tcc_3/features/achievements/models/achievement_model.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/repositories/transaction_repository.dart';

class AchievementService {

  // Retorna a conquista que foi desbloqueada (ou nulo se nenhuma for)
  Future<AchievementModel?> checkAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList('unlocked_achievements') ?? [];

    // --- LÓGICA DE VERIFICAÇÃO DE CADA CONQUISTA ---

    // Exemplo 1: Verifica a conquista "Primeiro Passo"
    if (!unlockedIds.contains('primeiro_passo')) {
      
      // --- CORREÇÃO APLICADA AQUI ---
      // Usa o método que realmente existe no seu repositório
      final transactionRepo = locator.get<TransactionRepository>();
      int count = 0;
      
      // Define um período de tempo muito grande para pegar todas as transações
      final startDate = DateTime(2020); 
      final endDate = DateTime.now();

      final result = await transactionRepo.getTransactionsByDateRange(
        startDate: startDate,
        endDate: endDate,
      ); 
      
      result.fold(
        (error) => count = 0,
        (data) => count = data.length,
      );

      if (count > 0) {
        // Se ganhou, retorna o modelo da conquista desbloqueada
        return await _unlockAchievement('primeiro_passo', unlockedIds, prefs);
      }
    }
    
    // ... Adicione aqui as verificações para as outras conquistas ...


    // Se nenhuma conquista for desbloqueada nesta verificação, retorna nulo
    return null;
  }
  
  // Método privado para desbloquear uma conquista e retornar seu modelo
  Future<AchievementModel> _unlockAchievement(
    String id, 
    List<String> unlockedIds, 
    SharedPreferences prefs
  ) async {
    unlockedIds.add(id);
    await prefs.setStringList('unlocked_achievements', unlockedIds);

    final achievement = allAchievements.firstWhere((a) => a.id == id);
    print('🎉 Conquista Desbloqueada: ${achievement.title}');
    
    return achievement;
  }
}