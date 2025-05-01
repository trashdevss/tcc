// lib/features/home/widgets/balance_card_widget.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/features/balance_state.dart';
import '../../../common/constants/constants.dart';
import '../../../common/extensions/extensions.dart';

// --- Widget TransactionValue (sem alterações) ---
enum TransactionType { income, outcome }
class TransactionValueWidget extends StatelessWidget {
 // ... (código idêntico ao anterior) ...
 const TransactionValueWidget({ super.key, required this.amount, required this.controller, this.type = TransactionType.income, });
 final BalanceController controller;
 final double amount;
 final TransactionType type;
 @override
 Widget build(BuildContext context) { /* ... código interno ... */
    double textScaleFactor = MediaQuery.of(context).size.width <= 360 ? 0.8 : 1.0;
    double iconSize = MediaQuery.of(context).size.width <= 360 ? 16.0 : 24.0;
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$'); // <<< CONFIRME MOEDA
    final formattedAmount = currencyFormatter.format(amount); // <<< CONFIRME FORMATO DESPESA (use .abs()?)
    return Row(mainAxisSize: MainAxisSize.min,children: [Container(padding: const EdgeInsets.all(4.0), decoration: BoxDecoration( color: AppColors.white.withOpacity(0.06), borderRadius: const BorderRadius.all(Radius.circular(16.0)), ), child: Icon( type == TransactionType.income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: AppColors.white, size: iconSize, ), ),const SizedBox(width: 8.0),Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,children: [Text( type == TransactionType.income ? 'Income' : 'Expense', textScaleFactor: textScaleFactor, style: AppTextStyles.mediumText16w500.apply(color: AppColors.white), ),SizedBox(height: 2.h),AnimatedBuilder( animation: controller, builder: (context, _) { if (controller.state is BalanceStateLoading) { return Container( margin: const EdgeInsets.only(top: 2.0), color: AppColors.white.withOpacity(0.1), height: 24.h, width: 80.w, child: const Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54))),); } return Text( formattedAmount, textScaleFactor: textScaleFactor, style: AppTextStyles.mediumText20.apply(color: AppColors.white), overflow: TextOverflow.ellipsis, maxLines: 1, ); }),],)],);
 }
}

// --- Widget Principal BalanceCardWidget ---
class BalanceCardWidget extends StatefulWidget {
 const BalanceCardWidget({ Key? key, required this.controller, this.drawBackground = true, }) : super(key: key);
 final BalanceController controller;
 final bool drawBackground; // Controla se desenha o fundo próprio

 @override
 State<BalanceCardWidget> createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget> {
 final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$'); // <<< CONFIRME MOEDA

 @override
 void initState() { super.initState(); widget.controller.addListener(_handleBalanceStateChange); }
 @override
 void dispose() { widget.controller.removeListener(_handleBalanceStateChange); super.dispose(); }
 void _handleBalanceStateChange() { if (mounted) { setState(() {}); } }

 @override
 Widget build(BuildContext context) {
   double textScaleFactor = MediaQuery.of(context).size.width <= 360 ? 0.8 : 1.0;

   // Define a decoração: Verde ESCURO com borda se drawBackground for true, senão transparente
   BoxDecoration cardDecoration = widget.drawBackground
       ? const BoxDecoration(
           // <<< COR ALTERADA PARA VERDE ESCURO >>>
           color: AppColors.darkGreen,
           // <<< CURVA DO CARD: Mantida original (todos os cantos) >>>
           borderRadius: BorderRadius.all(Radius.circular(16.0)),
         )
       : const BoxDecoration( color: Colors.transparent, );

   // Define o padding interno: Aumentado verticalmente quando desenha o fundo
   EdgeInsets cardPadding = EdgeInsets.symmetric(
     horizontal: 24.w,
     // <<< PADDING VERTICAL AUMENTADO (quando desenha fundo) >>>
     vertical: widget.drawBackground ? 32.h : 8.h, // Ex: 32h com fundo, 8h sem fundo
   );

   return Container(
     padding: cardPadding,
     decoration: cardDecoration,
     child: Column(
       mainAxisSize: MainAxisSize.min, // Importante para o Stack calcular a altura
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row( /* Linha Saldo e Botão ... */
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Column( /* Saldo */
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text( 'Total Balance', textScaleFactor: textScaleFactor, style: AppTextStyles.mediumText16w600.apply(color: AppColors.white), ),
                 SizedBox(height: 4.h),
                 AnimatedBuilder( animation: widget.controller, builder: (context, _) { if (widget.controller.state is BalanceStateLoading) { /* Loading */ return Container( color: AppColors.white.withOpacity(0.1), height: 36.h, width: 150.w, child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54))),); } return Text( /* Valor Saldo */ _currencyFormatter.format(widget.controller.balances.totalBalance), textScaleFactor: textScaleFactor, style: AppTextStyles.mediumText30.apply(color: AppColors.white), overflow: TextOverflow.ellipsis, maxLines: 1, ); })
               ],
             ),
             // <<< BOTÃO '...' - Remova/Comente se não quiser >>>
             PopupMenuButton( padding: EdgeInsets.zero, icon: const Icon( Icons.more_horiz, color: AppColors.white, ), itemBuilder: (context) => [ const PopupMenuItem( height: 30.0, value: 'opt1', child: Text("Opção 1")), const PopupMenuItem( height: 30.0, value: 'opt2', child: Text("Opção 2")), ], onSelected: (value) { log('Menu selecionado: $value'); }, ),
           ],
         ),

         // <<< ESPAÇAMENTO INTERNO AUMENTADO >>>
         SizedBox(height: 36.h), // Aumentado para "esticar" o card

         Row( /* Linha Income / Expense */
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             TransactionValueWidget( amount: widget.controller.balances.totalIncome, controller: widget.controller, type: TransactionType.income, ),
             TransactionValueWidget( amount: widget.controller.balances.totalOutcome, controller: widget.controller, type: TransactionType.outcome, ), // Use .abs() para positivo
           ],
         ),
       ],
     ),
   );
 }
}