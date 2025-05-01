// lib/features/home/home_page.dart

import 'package:flutter/material.dart';
// Imports de Controllers e Widgets (Verifique os paths)
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/widgets/custom_bottom_app_bar.dart'; // Para BottomAppBarItem
import 'package:tcc_3/common/widgets/custom_circular_progress_indicator.dart';
import 'package:tcc_3/common/widgets/custom_bottom_sheet.dart'; // Para CustomModalSheetMixin
import 'package:tcc_3/common/widgets/tip_card.dart';
// Imports de Constantes, Extensões, etc (Verifique os paths)
import '../../common/constants/constants.dart';
import '../../common/extensions/extensions.dart';
import '../../common/widgets/transaction_listview.dart';
import '../../locator.dart';
// Imports locais da Feature Home
import 'home_controller.dart';
import 'home_state.dart';
import 'widgets/balance_card_widget.dart';
import 'models/tip_model.dart';

// --- Widget AppHeader ---
class AppHeader extends StatelessWidget {
 const AppHeader({Key? key}) : super(key: key);
 @override
 Widget build(BuildContext context) {
   final homeController = locator.get<HomeController>();
   final Color headerTextColor = AppColors.white;
   return AnimatedBuilder( animation: homeController, builder: (context, _) { if (homeController.state is HomeStateSuccess) { final userName = homeController.userData.name?.capitalize() ?? ''; String greeting = 'Olá'; int hour = DateTime.now().hour; if (hour < 12) { greeting = 'Bom dia'; } else if (hour < 18) { greeting = 'Boa tarde'; } else { greeting = 'Boa noite'; } return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( '$greeting,\n$userName', style: AppTextStyles.mediumText18.copyWith(color: headerTextColor), ), IconButton( onPressed: () { /* Ação sino */ print("Sino Clicado!"); }, icon: Icon(Icons.notifications_outlined, color: headerTextColor), ), ], ); } return const SizedBox(height: 56); });
 }
}

// --- HomePage Principal ---
class HomePage extends StatefulWidget {
 const HomePage({super.key});
 @override
 State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with CustomModalSheetMixin {
 final homePageController = locator.get<HomeController>();
 final balanceController = locator.get<BalanceController>();

 @override
 void initState() { super.initState(); homePageController.getUserData(); homePageController.getLatestTransactions(); balanceController.getBalances(); homePageController.loadTips(); homePageController.addListener(_handleHomeStateChange); }
 @override
 void dispose() { homePageController.removeListener(_handleHomeStateChange); super.dispose(); }
 void _handleHomeStateChange() { if (mounted) { setState(() {}); } }


 @override
 Widget build(BuildContext context) {
   // <<< USANDO STACK >>>
   // <<< VALORES COM AJUSTE PARA DESCER AS DICAS - REVISE E AJUSTE! >>>

   // --- ESTIMATIVAS (Baseado no seu código anterior) ---
   double headerBackgroundHeight = 260.h; // Mantido alto como no seu último código
   double headerContentTop = 40.h;      // Mantido (ou 50.h?)
   double balanceCardTop = 130.h;       // Mantido como no seu último código

   // Estimativa da altura do Card Verde (Use o Inspector!)
   double balanceCardHeightEstimate = 190.h; // Mantido alto como no seu último código

   // <<< ESPAÇO DEPOIS DO CARD AUMENTADO PARA DESCER AS DICAS >>>
   double spacingAfterCard = 40.h; // Ex: Aumentado de 16.h para 40.h (AJUSTE ESTE VALOR!)

   // Altura da seção Dicas
   double tipsSectionHeight = 180; // Mantido como no seu último código (AJUSTE!)
   double spacingAfterTips = 40.h; // Mantido como no seu último código

   // Novos Tops Calculados (CONFIRA E AJUSTE ESTES VALORES!)
   // Este valor vai aumentar porque spacingAfterCard aumentou
   double topNovoDicas = balanceCardTop + balanceCardHeightEstimate + spacingAfterCard; // ~130 + 210 + 40 = 380.h
   // Este valor também vai aumentar automaticamente
   double topNovoHistory = topNovoDicas + tipsSectionHeight + spacingAfterTips; // ~380 + 190 + 40 = 610.h


   return Scaffold(
     backgroundColor: AppColors.iceWhite,
     body: Stack(
       children: [

         // --- 1. Fundo Verde Claro do Topo ---
         Positioned(
           top: 0,
           left: 0,
           right: 0,
           height: headerBackgroundHeight, // Usando valor alto do seu código
           child: Container(
             decoration: const BoxDecoration(
               color: AppColors.green, // Verde Claro
               // Mantendo borda arredondada embaixo
               borderRadius: BorderRadius.only(
                 bottomLeft: Radius.circular(18.0),
                 bottomRight: Radius.circular(18.0),
               ),
             )
           ),
         ),

         // --- 2. App Header (Saudação) ---
         Positioned(
           top:60.h, // Ex: 40.h ou 50.h
           left: 16.w,
           right: 16.w,
           child: const AppHeader(),
         ),

         // --- 3. Balance Card (Verde Escuro) ---
         Positioned(
           top: balanceCardTop, // Ex: 130.h (Card baixo)
           left: 16.w,
           right: 16.w,
           child: BalanceCardWidget(
             controller: balanceController,
             drawBackground: true,
             // Certifique-se que BalanceCardWidget está na versão sem botão '...'
             // e com espaçamento interno que resulta na altura estimada (balanceCardHeightEstimate)
           ),
         ),


         // --- 4. Seção "Dicas pra você" ---
         Positioned(
           // <<< TOP AUMENTADO (porque spacingAfterCard aumentou) >>>
           top: topNovoDicas, // Ex: ~380.h (AJUSTE!)
           left: 0,
           right: 0,
           height: tipsSectionHeight, // Ex: 190 (AJUSTE!)
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding( padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0), child: Text('Dicas pra você', style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkGrey)), ),
               Expanded(
                 child: AnimatedBuilder(
                   animation: homePageController,
                   builder: (context, _) {
                     if (homePageController.isLoadingTips) { return const Center(child: CustomCircularProgressIndicator()); }
                     if (homePageController.tips.isEmpty) { return const Center(child: Text("Nenhuma dica disponível.")); }
                     return ListView.builder( scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16.0), itemCount: homePageController.tips.length, itemBuilder: (context, index) { return Padding( padding: EdgeInsets.only(right: index == homePageController.tips.length - 1 ? 0 : 12.0), child: TipCard(tip: homePageController.tips[index]), ); }, );
                   }
                 ),
               ),
             ],
           ),
         ),
         // --- Fim da Seção "Dicas pra você" ---


         // --- 5. Seção Histórico de Transações ---
         Positioned(
           // <<< TOP AUMENTADO (porque topNovoDicas aumentou) >>>
           top: topNovoHistory, // Ex: ~610.h (AJUSTE!)
           left: 0,
           right: 0,
           bottom: 0,
           child: Column(
             children: [
               Padding( /* Row Título (Sem See All) */ padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0), child: Row( mainAxisAlignment: MainAxisAlignment.start, children: [ Text( 'Transaction History', style: AppTextStyles.mediumText18.copyWith(color: AppColors.darkGrey), ), ], ), ),
               Expanded(
                 child: AnimatedBuilder(
                   animation: homePageController,
                   builder: (context, _) {
                     if (homePageController.transactions.isEmpty) { return const Center( child: Padding( padding: EdgeInsets.symmetric(vertical: 40.0), child: Text('Nenhuma transação encontrada.'), ) ); }
                     return TransactionListView( transactionList: homePageController.transactions, onChange: () { if (mounted) {setState(() {});} }, );
                   },
                 ),
               ),
             ],
           ),
         ), // --- Fim da Seção Histórico de Transações ---

       ], // Fim dos filhos do Stack
     ),
   );
 }
}