// lib/common/helpers/category_icon_helper.dart

import 'package:flutter/foundation.dart'; // Para debugPrint, se mantido
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart'; // Necessário para IconData

class CategoryIconHelper {
  CategoryIconHelper._();

  static IconData getIcon(String category) {
    // Converte para minúsculas para a comparação no switch
    final lowerCaseCategory = category.toLowerCase();

    // DEBUG: Imprime no console para verificar os nomes exatos
    // debugPrint("CategoryIconHelper - Recebido: '$category', Convertido: '$lowerCaseCategory'");

    switch (lowerCaseCategory) {
      // --- RECEITAS ---
      case 'salário': // Note o acento e minúsculas
        return FontAwesomeIcons.sackDollar;
      case 'serviços': // Note o 'ç' e acento
        return FontAwesomeIcons.briefcase;
      case 'investimentos':
        return FontAwesomeIcons.chartLine;
      case 'vendas':
        return FontAwesomeIcons.tags;
      case 'reembolsos':
        return FontAwesomeIcons.receipt;
      case 'receita': // Adicionado para cobrir Pix recebido ou outras receitas genéricas
        return FontAwesomeIcons.arrowDownWideShort; 

      // --- DESPESAS ---
      case 'moradia':
        return FontAwesomeIcons.houseChimney;
      case 'alimentação': // Note o 'ç' e 'ã'
        return FontAwesomeIcons.utensils;
      case 'contas': // Esta é a categoria para Pix enviado e outras contas
        return FontAwesomeIcons.fileInvoiceDollar;
      case 'transporte':
        return FontAwesomeIcons.busSimple;
      case 'lazer':
        return FontAwesomeIcons.puzzlePiece;
      case 'educação': // Note o 'ç' e 'ã'
        return FontAwesomeIcons.graduationCap;
      case 'saúde': // Note o acento
        return FontAwesomeIcons.briefcaseMedical;
      case 'vestuário': // Note o acento
        return FontAwesomeIcons.shirt;
      case 'compras':
        return FontAwesomeIcons.bagShopping;
      case 'viagens':
        return FontAwesomeIcons.planeDeparture;
      
      // --- ÍCONE PARA TRANSFERÊNCIA PIX ---
      // Ajustado para 'transferencia pix' (sem acento) para corresponder à saída do JoveNotificationService
      case 'transferencia pix': 
        return FontAwesomeIcons.pix; // Ícone da marca PIX (ideal se disponível)
        // Alternativas se FontAwesomeIcons.pix não estiver disponível ou não for desejado:
        // return FontAwesomeIcons.moneyBillTransfer; 
        // return FontAwesomeIcons.arrowRightArrowLeft;
        // return FontAwesomeIcons.qrcode;

      // --- OUTROS ---
      case 'outros':
        return FontAwesomeIcons.ellipsis;

      // --- Ícone Padrão ---
      default:
        // Se chegar aqui, significa que o nome da categoria não bateu com nenhum case
        // Mantenha o debugPrint se achar útil durante o desenvolvimento
        if (kDebugMode) { // Apenas imprime em modo debug
            print(
             "CategoryIconHelper - Ícone não encontrado para categoria: '$category' (lower: '$lowerCaseCategory')");
        }
        return FontAwesomeIcons.circleQuestion; // Interrogação
    }
  }
}