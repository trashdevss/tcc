// lib/common/constants/app_colors.dart (ou onde seu arquivo estiver)

import 'package:flutter/material.dart'; // Usar Color do Material

class AppColors {
  AppColors._(); // Construtor privado

  // --- Verdes Revisitados (Mais Vibrantes/Acolhedores) ---
  // Era 0xFF438883 (Teal) -> Agora MediumSeaGreen
  static const Color greenOne = Color(0xFF3CB371);
  // Era 0xFF63B5AF (Light Teal) -> Agora um tom mais claro e vivo do novo verde
  static const Color greenTwo = Color(0xFF66CDAA); // MediumAquamarine
  // Gradiente usando os novos verdes
  static const List<Color> greenGradient = [
    AppColors.greenTwo, // Usa o novo valor de greenTwo
    AppColors.greenOne, // Usa o novo valor de greenOne
  ];
  // Era 0xFF438883 -> Mesmo que greenOne agora
  static const Color green = Color(0xFF3CB371);
  // Era 0xFF2F7E79 (Dark Teal) -> Agora um tom mais escuro do novo verde
  static const Color darkGreen = Color(0xFF2E8B57); // SeaGreen

  // --- Neutros e Cinzas (Ajustados para Contraste e Fundo) ---
  // Mantido Branco puro
  static const Color white = Color(0xFFFFFFFF);
  // Era 0xFFEEF8F7 -> Agora um cinza muito claro para fundo geral
  static const Color iceWhite = Color(0xFFF5F5F5); // Grey 100
  // Era 0xFFF0F6F5 -> Pode usar a mesma cor de fundo ou um tom sutilmente diferente
  static const Color antiFlashWhite = Color(0xFFFAFAFA); // Grey 50 (quase branco)
  // Era 0xFF222222 -> Agora um cinza bem escuro (quase preto) para texto principal forte
  static const Color blackGrey = Color(0xFF212121); // Grey 900
  // Era 0xFF444444 -> Agora um cinza escuro padrão para texto
  static const Color darkGrey = Color(0xFF424242); // Grey 800
  // Era 0xFF666666 -> Agora um cinza médio padrão
  static const Color grey = Color(0xFF757575); // Grey 600
  // Era 0xFFAAAAAA -> Agora um cinza mais claro com melhor contraste (tom azulado)
  static const Color lightGrey = Color(0xFFB0BEC5); // Blue Grey 200
  // Gradiente usando os novos cinzas
  static const List<Color> greyGradient = [
    AppColors.lightGrey, // Usa o novo valor de lightGrey
    AppColors.grey,      // Usa o novo valor de grey
  ];

  // --- Cores de Status e Alerta (Mantidas ou Ajustadas) ---
  // Mantido o vermelho padrão para erros
  static const Color error = Color(0xFFF44336); // Red 500
  // Mantido o verde para receitas
  static const Color income = Color(0xFF25A969);
  // Mantido o vermelho/laranja para despesas
  static const Color outcome = Color(0xFFF95B51);
  // Era 0xFFFFAB7B (Laranja claro) -> Agora um Amarelo/Âmbar para destaque ou notificações positivas
  static const Color notification = Color(0xFFFFC107); // Amber
  // Se precisar de um azul para notificações informativas, pode adicionar:
  // static const Color infoBlue = Color(0xFF1E88E5); // Blue 600
}
