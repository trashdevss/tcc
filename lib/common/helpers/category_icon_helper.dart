// lib/common/helpers/category_icon_helper.dart

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
        return FontAwesomeIcons.arrowDownWideShort; // Exemplo de ícone para receita

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
      case 'Transferência Pix':
        return FontAwesomeIcons.houseChimney;  
      
      // O case para 'Transferência' foi removido, pois a intenção é usar 'Contas' ou 'Receita'.

      // --- OUTROS ---
      case 'outros':
        return FontAwesomeIcons.ellipsis;

      // --- Ícone Padrão ---
      default:
        // Se chegar aqui, significa que o nome da categoria não bateu com nenhum case
        debugPrint(
            "CategoryIconHelper - Ícone não encontrado para categoria: '$category' (lower: '$lowerCaseCategory')");
        return FontAwesomeIcons.circleQuestion; // Interrogação
    }
  }
}