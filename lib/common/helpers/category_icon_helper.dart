import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart'; // Necessário para IconData

class CategoryIconHelper {
  static IconData getIcon(String category) {
    // Converte para minúsculas para comparação sem diferenciar maiúsculas/minúsculas
    switch (category.toLowerCase()) {

      // --- RECEITAS ---
      case 'salário':
        return FontAwesomeIcons.moneyBillWave; // Ou wallet
      case 'serviços': // Mantém o original, se aplicável
        return FontAwesomeIcons.briefcase;
      case 'vendas':
        return FontAwesomeIcons.tags; // Ou store
      case 'investimentos': // Mantém o original, se aplicável
      case 'investment':
        return FontAwesomeIcons.chartLine; // Ou seedling
      case 'mesada':
        return FontAwesomeIcons.children; // Ou handHoldingDollar
      case 'bolsa auxílio':
        return FontAwesomeIcons.graduationCap; // Ou bookOpenReader
      case 'presente': // Ícone para presente recebido
        return FontAwesomeIcons.gift;
      case 'reembolso':
        return FontAwesomeIcons.receipt; // Ou arrowRotateLeft
      case 'aluguel recebido':
        return FontAwesomeIcons.houseUser; // Ou key

      // --- DESPESAS ---
      case 'moradia': // Mantém o original, se aplicável
      case 'house':
        return FontAwesomeIcons.houseChimney; // Ou house apenas
      case 'mercado': // Mantém o original, se aplicável
      case 'grocery':
        return FontAwesomeIcons.cartShopping;
      case 'alimentação fora':
        return FontAwesomeIcons.utensils; // Ou burger
      case 'transporte':
        return FontAwesomeIcons.carRear; // Ou bus, motorcycle
      case 'contas fixas':
        return FontAwesomeIcons.fileInvoiceDollar; // Ou lightbulb, wifi
      case 'lazer e hobbies':
        return FontAwesomeIcons.gamepad; // Ou film, guitar, palette
      case 'educação':
        return FontAwesomeIcons.bookOpen; // Ou graduationCap
      case 'saúde':
        return FontAwesomeIcons.notesMedical; // Ou heartPulse, pills
      case 'roupas e calçados':
        return FontAwesomeIcons.shirt; // Ou personDress, shoePrints
      case 'cuidados pessoais':
        return FontAwesomeIcons.spa; // Ou scissors, shop
      case 'assinaturas':
        return FontAwesomeIcons.creditCard; // Ou play, calendarCheck
      case 'presentes (dados)': // Ícone diferente para presente dado
        return FontAwesomeIcons.boxOpen;
      case 'dívidas/empréstimos':
        return FontAwesomeIcons.landmark; // Ou fileInvoiceDollar
      case 'impostos e taxas':
        return FontAwesomeIcons.landmark; // Ou receipt, percent
      case 'pets':
        return FontAwesomeIcons.paw;
      case 'viagem':
        return FontAwesomeIcons.planeDeparture; // Ou suitcaseRolling
      case 'casa e decoração':
        return FontAwesomeIcons.couch; // Ou paintRoller, lamp
      case 'doações':
        return FontAwesomeIcons.handHoldingHeart;
      case 'saques':
        return FontAwesomeIcons.moneyBillTransfer; // Ou sackDollar

      // --- OUTROS (Genérico) ---
      case 'outras receitas':
      case 'outras despesas':
      case 'other': // Mantém o original, se aplicável
        return FontAwesomeIcons.ellipsis; // Ícone de "mais opções"

      // --- Ícone Padrão ---
      default:
        // Retorna um ícone de interrogação se a categoria não for encontrada
        return FontAwesomeIcons.circleQuestion; // Usando um diferente do ellipsis
    }
  }
}