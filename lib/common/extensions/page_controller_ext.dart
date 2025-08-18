import 'package:flutter/material.dart';

// 1. ATUALIZAR O ENUM: Adicionar graficos, ferramentas e renomear stats para metas
// A ordem aqui DEVE corresponder à ordem das páginas no PageView
enum BottomAppBarItem {
  home,        // Índice 0
  graficos,    // Índice 1 (Novo)
  metas,       // Índice 2 (Antigo stats, renomeado)
  wallet,      // Índice 3
  ferramentas, // Índice 4 (Novo)
  profile      // Índice 5
}

extension PageControllerExt on PageController {
  // Este _selectedIndex parece ser um fallback, pode manter como está por enquanto.
  static int _selectedIndex = 0;

  // 3. CORRIGIR A LÓGICA DO GETTER: O espaço do FAB agora é depois do índice 2
  int get selectedBottomAppBarItemIndex {
    // Obtém o índice da página atual no PageView (0 a 5)
    final pageIndex = page?.round() ?? _selectedIndex;

    // Mapeia o índice da página para o índice visual do item na barra
    // (0, 1, 2, pula o 3, 4, 5, 6)
    if (pageIndex >= 3) { // Se a página for Wallet (3), Ferramentas (4) ou Profile (5)
      return pageIndex + 1; // O índice visual na barra será 4, 5 ou 6
    }
    // Para as páginas Home (0), Gráficos (1), Metas (2)
    return pageIndex; // O índice visual é o mesmo (0, 1, 2)
  }

  // Este setter parece ok, apenas atualiza o fallback _selectedIndex.
  set setBottomAppBarItemIndex(int newIndex) {
    // Considerar se este setter ainda é necessário ou se a lógica
    // deve depender apenas do estado do PageController.
    _selectedIndex = newIndex;
  }

  // 2. ATUALIZAR O SWITCH CASE: Adicionar os novos casos e ajustar o nome 'metas'
  void navigateTo(BottomAppBarItem item) {
    // Usa o índice do enum para pular para a página correta no PageView
    // Isso funciona SE a ordem no enum for a mesma das children no PageView.
    switch (item) {
      case BottomAppBarItem.home:
        jumpToPage(BottomAppBarItem.home.index); // index = 0
        break;
      case BottomAppBarItem.graficos: // Novo caso
        jumpToPage(BottomAppBarItem.graficos.index); // index = 1
        break;
      case BottomAppBarItem.metas: // Caso renomeado (era stats)
        jumpToPage(BottomAppBarItem.metas.index); // index = 2
        break;
      case BottomAppBarItem.wallet:
        jumpToPage(BottomAppBarItem.wallet.index); // index = 3
        break;
      case BottomAppBarItem.ferramentas: // Novo caso
        jumpToPage(BottomAppBarItem.ferramentas.index); // index = 4
        break;
      case BottomAppBarItem.profile:
        jumpToPage(BottomAppBarItem.profile.index); // index = 5
        break;
      // Não é necessário default se todos os casos do enum estão cobertos.
    }
    // Talvez você queira atualizar o _selectedIndex aqui também,
    // embora o getter use page?.round() como preferência.
    // _selectedIndex = item.index;
  }
}