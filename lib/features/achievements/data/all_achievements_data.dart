// lib/features/achievements/data/all_achievements_data.dart
import '../models/achievement_model.dart';

// Esta é a lista de todas as conquistas que existem no seu app.
// Você precisará criar as imagens correspondentes na sua pasta de assets.
const List<AchievementModel> allAchievements = [
  AchievementModel(
    id: 'primeiro_passo',
    title: 'Primeiro Passo',
    description: 'Você adicionou sua primeira transação financeira!',
    imagePath: 'assets/images/achievements/primeiro_passo.png',
  ),
  AchievementModel(
    id: 'planejador_mestre',
    title: 'Planejador Mestre',
    description: 'Parabéns! Você usou todas as 3 calculadoras financeiras.',
    imagePath: 'assets/images/achievements/planejador.png',
  ),
  AchievementModel(
    id: 'mao_fechada',
    title: 'Mão Fechada',
    description: 'Você conseguiu fechar um mês com saldo positivo (mais receitas do que despesas).',
    imagePath: 'assets/images/achievements/mao_fechada.png',
  ),
  AchievementModel(
    id: 'sonhador',
    title: 'Sonhador',
    description: 'Você criou sua primeira meta financeira para alcançar um objetivo.',
    imagePath: 'assets/images/achievements/sonhador.png',
  ),
   AchievementModel(
    id: 'meta_batida',
    title: 'Meta Batida!',
    description: 'Incrível! Você completou sua primeira meta financeira.',
    imagePath: 'assets/images/achievements/meta_batida.png',
  ),
  AchievementModel(
    id: 'investidor_iniciante',
    title: 'Investidor Iniciante',
    description: 'Você usou a calculadora de juros compostos para simular o futuro.',
    imagePath: 'assets/images/achievements/investidor.png',
  ),
  // Adicione quantas conquistas você quiser!
];