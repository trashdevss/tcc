// lib/features/home/view/home_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/features/transaction/transaction_state.dart';
import 'package:tcc_3/common/widgets/custom_bottom_sheet.dart';
import 'package:tcc_3/common/widgets/home_tips_section.dart';
import 'package:tcc_3/features/home/home_controller.dart';
import 'package:tcc_3/features/home/home_state.dart';
import 'package:tcc_3/features/home/widgets/balance_card_widget.dart'; // Import do Card corrigido

import '../../../common/constants/constants.dart';
import '../../../common/extensions/extensions.dart';
import '../../../common/widgets/app_header.dart';
import '../../../common/widgets/custom_circular_progress_indicator.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../../../locator.dart';
import '../../../common/models/transaction_model.dart';
import '../../../common/features/transaction/transaction_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with CustomModalSheetMixin, CustomSnackBar {
  final _homeController = locator.get<HomeController>();
  final _balanceController = locator.get<BalanceController>();
  final _transactionController = locator.get<TransactionController>();
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

  @override
  void initState() { /* ... código sem alterações ... */ super.initState(); _homeController.getUserData(); _homeController.getLatestTransactions(); _balanceController.getBalances(); _homeController.addListener(_handleHomeStateChange); _transactionController.addListener(_handleTransactionError); }
  @override
  void dispose() { /* ... código sem alterações ... */ _homeController.removeListener(_handleHomeStateChange); _transactionController.removeListener(_handleTransactionError); super.dispose(); }
  void _handleHomeStateChange() { /* ... código sem alterações ... */ final state = _homeController.state; if (!mounted) return; switch (state.runtimeType) { case HomeStateError: showCustomModalBottomSheet( context: context, content: (_homeController.state as HomeStateError).message ?? 'Erro desconhecido', buttonText: 'Ir para Login', isDismissible: false, onPressed: () => Navigator.pushNamedAndRemoveUntil( context, NamedRoute.initial, (route) => false, ), ); break; } }
  void _handleTransactionError() { /* ... código sem alterações ... */ final state = _transactionController.state; if (!mounted) return; if (state is TransactionStateError) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { showCustomSnackBar(context: context, text: state.message, type: SnackBarType.error); } }); } }
  Future<bool> _confirmDeleteTransaction(TransactionModel item) async { /* ... código sem alterações ... */ final confirm = await showCustomModalBottomSheet( context: context, content: 'Deseja realmente excluir a transação "${item.description.isNotEmpty ? item.description : "sem descrição"}"?', actions: [ Expanded( child: OutlinedButton( onPressed: () => Navigator.pop(context, false), style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[700], side: BorderSide(color: Colors.grey[400]!)), child: const Text('Cancelar'), ), ), const SizedBox(width: 16.0), Expanded( child: PrimaryButton( text: 'Confirmar', onPressed: () => Navigator.pop(context, true), ), ), ], ); return confirm == true; }
  Future<void> _deleteTransaction(TransactionModel item) async { /* ... código sem alterações ... */ try { await _transactionController.deleteTransaction(item); await _balanceController.updateBalance( oldTransaction: item, newTransaction: item.copyWith(value: 0), ); await _homeController.getLatestTransactions(); await _balanceController.getBalances(); if(mounted){ showCustomSnackBar(context: context, text: 'Transação excluída.', type: SnackBarType.success); } } catch(e) { print("Erro no _deleteTransaction: $e"); } }
  Future<void> _refreshData() async { /* ... código sem alterações ... */ print("Refreshing data..."); await Future.wait([ _homeController.getUserData(), _homeController.getLatestTransactions(), _balanceController.getBalances() ]); }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // --- Cabeçalho do Aplicativo ---
                  AnimatedBuilder(
                    animation: _homeController,
                    builder: (context, child) {
                      // *** CORREÇÃO: Envolver AppHeader com SizedBox ***
                      return SizedBox(
                        // Use a altura desejada/esperada para o seu header
                        // Pode ser um valor fixo ou baseado em .h se usar ScreenUtil
                        height: 290, // Exemplo - ajuste conforme necessário
                        child: const AppHeader(),
                      );
                      // *************************************************
                    }
                  ),
                  // --- Card Principal de Saldo ---
                  // *** CORREÇÃO: Adicionado Padding horizontal ***
                  Padding(
                    // Use o valor de padding que estava no Positioned (left/right)
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Exemplo com 16.0
                    // Use 24.w se estiver usando ScreenUtil e essa for a intenção:
                    // padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: BalanceCardWidget(controller: _balanceController),
                  ),
                  // **********************************************
                  const SizedBox(height: 8), // Espaço abaixo do card
                ],
              ),
            ),
          ];
        },
        // Corpo principal que rola por baixo do header
        body: RefreshIndicator(
           onRefresh: _refreshData,
           color: AppColors.green,
           child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // --- Seção de Dicas ---
                const Padding( padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0), child: Text('Dicas pra você', style: AppTextStyles.mediumText18), ),
                const HomeTipsSection(),
                const SizedBox(height: 16.0),

                // --- Seção de Histórico de Transações ---
                Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Transaction History', style: AppTextStyles.mediumText18), GestureDetector( onTap: () { try { _homeController.pageController.jumpToPage(4); } catch (e) { print("Erro ao navegar para Wallet: $e"); } }, child: const Text('See all', style: AppTextStyles.inputLabelText), ), ], ), ),
                const SizedBox(height: 8.0),
                Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0), child: AnimatedBuilder( // Lista de Transações
                    animation: _homeController, builder: (context, _) { /* ... lógica da lista ... */ if (_homeController.state is HomeStateLoading && _homeController.transactions.isEmpty) { return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: CustomCircularProgressIndicator(color: AppColors.green))); } if (_homeController.state is HomeStateError && _homeController.transactions.isEmpty) { return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text((_homeController.state as HomeStateError).message ?? 'Erro ao buscar transações.'))); } final transactions = _homeController.transactions; if (transactions.isEmpty) { return const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0), child: Text( 'Nenhuma transação registrada ainda.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15), ),),); } return Column( children: transactions.map((item) { final bool isIncome = item.value >= 0; final Color itemColor = isIncome ? AppColors.income : AppColors.outcome; final IconData itemIcon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded; final valueString = _currencyFormatter.format(item.value); String formattedDate = 'Data inválida'; try { final date = DateTime.fromMillisecondsSinceEpoch(item.date); formattedDate = DateFormat('dd/MM/yyyy', 'pt_BR').format(date); } catch (e) { print("Erro formatar data: $e"); } return Dismissible( key: ValueKey(item.id), direction: DismissDirection.endToStart, background: Container( color: AppColors.error.withOpacity(0.85), padding: const EdgeInsets.symmetric(horizontal: 20.0), alignment: Alignment.centerRight, child: const Icon(Icons.delete_outline, color: Colors.white, size: 28), ), confirmDismiss: (direction) => _confirmDeleteTransaction(item), onDismissed: (direction) => _deleteTransaction(item), child: ListTile( onTap: () async { final result = await Navigator.pushNamed(context, NamedRoute.transaction, arguments: item); if (result == true && mounted) { _refreshData(); } }, contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), leading: CircleAvatar( backgroundColor: itemColor.withAlpha(30), foregroundColor: itemColor, child: Icon(itemIcon, size: 20), ), title: Text( item.description.isNotEmpty ? item.description : (item.category ?? 'Sem Categoria'), style: AppTextStyles.mediumText16w500, maxLines: 1, overflow: TextOverflow.ellipsis, ), subtitle: Text( formattedDate, style: AppTextStyles.smallText13.copyWith(color: AppColors.lightGrey), ), trailing: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [ Text( valueString, style: AppTextStyles.mediumText16w600.copyWith(color: itemColor)), const SizedBox(height: 2), Text( item.status ? 'Pago' : 'Pendente', style: AppTextStyles.smallText13.copyWith( color: item.status ? AppColors.income.withAlpha(230) : AppColors.notification.withAlpha(230), fontSize: (AppTextStyles.smallText13.fontSize ?? 13) * 0.95, fontWeight: item.status ? FontWeight.normal : FontWeight.w500, ), ), ], ), ), ); }).toList(), ); } ), ),
                const SizedBox(height: 20),
              ],
           ),
         ),
      ),
    );
  }
}