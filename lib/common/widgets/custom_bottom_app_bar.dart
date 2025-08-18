// lib/common/widgets/custom_bottom_app_bar.dart (ou o nome correto do seu arquivo)

import 'package:flutter/material.dart';

// Verifique se estes imports estão corretos para seu projeto
import '../constants/app_colors.dart';
import '../extensions/page_controller_ext.dart'; // Para selectedBottomAppBarItemIndex

// --- Classe de Dados para o Item ---
class CustomBottomAppBarItem {
 final Key? key;
 final String? label; // O label que será mostrado
 final IconData? primaryIcon; // Ícone quando selecionado
 final IconData? secondaryIcon; // Ícone quando não selecionado
 final VoidCallback? onPressed; // Ação ao clicar

 CustomBottomAppBarItem({
   this.key,
   this.label,
   this.primaryIcon,
   this.secondaryIcon,
   this.onPressed,
 });

 // Construtor para o item vazio (placeholder do FAB)
 CustomBottomAppBarItem.empty({
   this.key,
   this.label = '', // Define um label vazio para evitar null
   this.primaryIcon, // Sem ícone
   this.secondaryIcon,
   this.onPressed, // Sem ação
 });
}


// --- Widget da Barra de Navegação Customizada ---
class CustomBottomAppBar extends StatefulWidget {
 final PageController controller;
 final Color? selectedItemColor; // Cor para item selecionado
 final List<CustomBottomAppBarItem> children; // Lista de itens

 const CustomBottomAppBar({
   Key? key,
   this.selectedItemColor,
   required this.children,
   required this.controller,
   // A validação do número de filhos pode ser ajustada se necessário
 })  : assert(children.length == 7 || children.length == 5, 'children.length must be appropriate (e.g., 5 or 7)'),
       super(key: key);

 @override
 State<CustomBottomAppBar> createState() => _CustomBottomAppBarState();
}

class _CustomBottomAppBarState extends State<CustomBottomAppBar> {
 @override
 void initState() {
   super.initState();
   widget.controller.addListener(_handlePageChange);
 }

 @override
 void dispose() {
   widget.controller.removeListener(_handlePageChange);
   // Não dê dispose no controller aqui se ele for gerenciado externamente
   // widget.controller.dispose();
   super.dispose();
 }

 // Atualiza a UI quando a página muda
 void _handlePageChange() {
   if (mounted) {
      setState(() {});
   }
 }

 @override
 Widget build(BuildContext context) {
   // Usa o BottomAppBar padrão para o recorte do FAB
   return BottomAppBar(
     shape: const CircularNotchedRectangle(),
     notchMargin: 6.0,
     color: AppColors.white, // Fundo da barra
     elevation: 8.0,
     child: Row( // Organiza os itens
       mainAxisAlignment: MainAxisAlignment.spaceAround,
       children: widget.children.map( // Itera sobre os itens passados
         (item) {
           // <<< CORRIGIDO: Usa a extensão para verificar o item selecionado >>>
           bool currentItem = widget.children.indexOf(item) ==
               widget.controller.selectedBottomAppBarItemIndex;

           // Garante que o item vazio não seja marcado como selecionado
           if (item.primaryIcon == null && item.secondaryIcon == null){
              currentItem = false;
           }

           // Cria a área clicável
           return Expanded(
             key: item.key,
             child: InkWell(
               onTap: item.onPressed, // Executa a ação definida na HomePageView
               // Opcional: remover feedback visual se não desejar
               splashColor: Colors.transparent,
               highlightColor: Colors.transparent,
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                 child: Column( // <<< USA COLUMN PARA ÍCONE E LABEL >>>
                   mainAxisSize: MainAxisSize.min,
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: <Widget>[
                     // 1. Ícone
                     Icon(
                       currentItem ? item.primaryIcon : item.secondaryIcon,
                       color: currentItem
                           ? widget.selectedItemColor ?? Theme.of(context).primaryColor
                           : AppColors.grey, // Cor não selecionada
                       size: 24,
                     ),
                     // Espaço
                     const SizedBox(height: 4.0),
                     // 2. Texto (Label)
                     Text(
                       item.label ?? '', // Mostra o label
                       style: TextStyle(
                         color: currentItem
                              ? widget.selectedItemColor ?? Theme.of(context).primaryColor
                              : AppColors.grey, // Cor não selecionada
                         fontSize: 11, // Tamanho da fonte
                         // fontWeight: currentItem ? FontWeight.w600 : FontWeight.normal,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ],
                 ),
               ),
             ),
           );
         },
       ).toList(),
     ),
   );
 }
}