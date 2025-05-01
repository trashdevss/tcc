// lib/common/widgets/custom_bottom_app_bar.dart (ou onde estiver)

import 'package:flutter/material.dart';
// Seus imports (VERIFIQUE)
import '../constants/app_colors.dart'; // Para AppColors.lightGrey

// Classe CustomBottomAppBarItem (como mostrada antes)
class CustomBottomAppBarItem {
  final Key? key;
  final String? label;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;
  final VoidCallback? onPressed;

  CustomBottomAppBarItem({
    this.key,
    this.label,
    this.primaryIcon,
    this.secondaryIcon,
    this.onPressed,
  });
}

class CustomBottomAppBar extends StatefulWidget {
  final PageController controller;
  final Color? selectedItemColor;
  final List<CustomBottomAppBarItem> children; // Espera 6 itens

  const CustomBottomAppBar({
    super.key,
    this.selectedItemColor,
    required this.children,
    required this.controller,
  })  : assert(children.length == 6, 'CustomBottomAppBar requires exactly 6 children items.');

  @override
  State<CustomBottomAppBar> createState() => _CustomBottomAppBarState();
}

class _CustomBottomAppBarState extends State<CustomBottomAppBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.initialPage;
    widget.controller.addListener(_handlePageChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePageChange);
    super.dispose();
  }

  void _handlePageChange() {
    final newIndex = widget.controller.page?.round() ?? 0;
    if (newIndex != _currentIndex) {
      // Verifica se está montado antes de chamar setState
      if (mounted) {
          setState(() { _currentIndex = newIndex; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     // Lógica original de montar os rowItems (3 + Spacer + 3)
     List<Widget> rowItems = [];
     for (int i = 0; i < 3; i++) { rowItems.add(_buildItem(widget.children[i], i)); }
     rowItems.add(const Spacer());
     for (int i = 3; i < 6; i++) { rowItems.add(_buildItem(widget.children[i], i)); }

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      // color: Colors.white, // Cor original?
      // elevation: 8.0, // Sombra original?
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: rowItems,
      ),
    );
  }

  // Função _buildItem original
  Widget _buildItem(CustomBottomAppBarItem item, int itemIndex) {
      bool isCurrentItem = itemIndex == _currentIndex;
      // Cor original não selecionada
      Color itemColor = isCurrentItem
          ? (widget.selectedItemColor ?? Theme.of(context).primaryColor)
          : AppColors.lightGrey; // VERIFIQUE SUA COR PADRÃO

      return Expanded(
        child: InkWell(
          key: item.key,
          onTap: item.onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding original
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCurrentItem ? item.primaryIcon : item.secondaryIcon,
                  color: itemColor,
                  size: 24.0, // Tamanho original?
                ),
                if (item.label != null && item.label!.isNotEmpty)
                   const SizedBox(height: 3.0), // Espaço original?
                if (item.label != null && item.label!.isNotEmpty)
                   Text(
                      item.label!,
                      style: TextStyle( // Estilo de texto original?
                         color: itemColor,
                         fontSize: 10.0,
                         // fontWeight: ..., // Tinha fontWeight?
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                   )
              ],
            )
          ),
        ),
      );
  }
}