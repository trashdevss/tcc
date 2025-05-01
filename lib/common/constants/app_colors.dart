// lib/common/constants/app_colors.dart

// Import correto para a classe Color
import 'package:flutter/material.dart';

class AppColors {
 AppColors._(); // Construtor privado

 // --- Verdes Principais ---
 // Mantive seu verde médio como principal "claro/médio"
 static const Color green = Color(0xFF43ac6f); // Verde Médio (#43ac6f)

 // <<< CORRIGIDO: Um verde escuro que combina com o AppColors.green >>>
 // Usei uma tonalidade mais escura do verde médio original.
 static const Color darkGreen = Color(0xFF2a6b44); // Verde Escuro (#2a6b44)

 // --- Outros Verdes / Azuis / Cores de Status ---
 // Mantive estes como estavam no seu arquivo, podem servir como alternativas
 static const Color greenOne = Color(0xFF2d4454); // Verde/Azul Bem Escuro (#2d4454)
 static const Color greenTwo = Color(0xFF63B5AF); // Verde Teal Médio (#63B5AF)

 // Verde para Receitas (Income) - Mantido
 static const Color income = Color(0xFF8fdb71);
 // Vermelho/Coral para Despesas (Outcome) - Mantido
 static const Color outcome = Color(0xFFF95B51);

 // --- Neutros ---
 static const Color white = Color(0xFFFFFFFF);
 static const Color iceWhite = Color(0xFFEEF8F7);      // Fundo bem claro
 static const Color antiFlashWhite = Color(0xFFF0F6F5); // Outro fundo claro
 static const Color lightGrey = Color(0xFFAAAAAA);    // Cinza claro
 static const Color grey = Color(0xFF666666);          // Cinza médio
 static const Color darkGrey = Color(0xFF444444);      // Cinza escuro
 static const Color blackGrey = Color(0xFF222222);     // Quase preto

 // --- Cores de Alerta / Notificação ---
 static const Color error = Color(0xFFF44336);        // Vermelho erro
 static const Color notification = Color(0xFFFFAB7B); // Laranja notificação

 // --- Gradientes ---
 // <<< GRADIENTE ATUALIZADO para usar as cores definidas >>>
 static const List<Color> greenGradient = [
   AppColors.green,     // Começa com o verde médio
   AppColors.darkGreen, // Termina com o novo verde escuro
 ];

 static const List<Color> greyGradient = [
   Color(0xFFB5B5B5),
   Color(0xFF7F7F7F),
 ];

 /*
 // Comentando a definição antiga e incorreta de darkGreen se quiser manter referência
 static const Color darkGreen_OLD_INCORRECT = Color.fromARGB(255, 21, 206, 123);
 */

}