// lib/common/helpers/category_icon_helper.dart

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart'; // Necessário para IconData

class CategoryIconHelper {
 CategoryIconHelper._();

 static IconData getIcon(String category) {
   // Converte para minúsculas para a comparação no switch
   final lowerCaseCategory = category.toLowerCase();

   // DEBUG: Imprime no console para verificar os nomes exatos
   // print("CategoryIconHelper - Recebido: '$category', Convertido: '$lowerCaseCategory'");

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

     // --- DESPESAS ---
     case 'moradia':
       return FontAwesomeIcons.houseChimney;
     case 'alimentação': // Note o 'ç' e 'ã'
       return FontAwesomeIcons.utensils;
     case 'contas':
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

     // --- OUTROS ---
     case 'outros':
       return FontAwesomeIcons.ellipsis;

     // --- Ícone Padrão ---
     default:
       // Se chegar aqui, significa que o nome da categoria não bateu com nenhum case
       debugPrint("CategoryIconHelper - Ícone não encontrado para categoria: '$category' (lower: '$lowerCaseCategory')");
       return FontAwesomeIcons.circleQuestion; // Interrogação
   }
 }
}