// lib/common/widgets/transaction_listview.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necessário para NumberFormat e DateFormat
import 'dart:developer';    // Para log() (opcional)

// --- VERIFIQUE SEUS IMPORTS ---
// Adapte os imports para a estrutura real do seu projeto
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/features/transaction/transaction_controller.dart';
import 'package:tcc_3/common/helpers/category_icon_helper.dart'; // Seu helper de ícones
import 'package:tcc_3/common/models/transaction_model.dart';
import '../../common/constants/constants.dart'; // AppColors, AppTextStyles, NamedRoute
import '../../common/extensions/extensions.dart'; // capitalize()
import '../../locator.dart'; // locator.get<T>()
// Import necessário se CustomCircularProgressIndicator ou mixins forem usados diretamente aqui
import 'widgets.dart';
// --- FIM DOS IMPORTS ---

class TransactionListView extends StatefulWidget {
  const TransactionListView({
    super.key,
    required this.transactionList,
    required this.onChange,
    this.selectedDate,
    this.filterType,
  });

  final List<TransactionModel> transactionList;
  final DateTime? selectedDate;
  final String? filterType;
  final VoidCallback onChange; // Callback para notificar pai sobre mudanças (delete/edit)

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView>
    with CustomModalSheetMixin, CustomSnackBar { // Mixins (verifique se estão definidos em widgets.dart ou importe direto)

  final _scrollController = ScrollController(); // Controller de scroll
  // Acessa os controllers globais via locator
  final _transactionController = locator.get<TransactionController>();
  final _balanceController = locator.get<BalanceController>();

  // Formatadores (criados uma vez para reutilização)
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR'); // Ajuste locale se necessário

  @override
  void dispose() {
    _scrollController.dispose(); // Libera o controller de scroll
    super.dispose();
  }

  // Função para confirmar exclusão
  Future<bool> _confirmDelete(BuildContext context, TransactionModel transaction) async {
     final confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar Exclusão'),
              content: Text('Deseja realmente excluir a transação "${transaction.description}"?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Excluir'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            );
          },
        );
     return confirm ?? false; // Retorna false se o diálogo for fechado sem confirmação
  }

  // Função para deletar a transação (com mounted checks)
  Future<void> _deleteTransaction(BuildContext context, TransactionModel item) async {
     try {
       final deleteResult = await _transactionController.deleteTransaction(item);
       final balanceResult = await _balanceController.updateBalance( oldTransaction: item, newTransaction: item.copyWith(value: 0), );

       if (!context.mounted) return; // Verifica ANTES de usar context/callback

       
     } catch (e, s) {
        print("Erro inesperado ao deletar no ListView: $e\n$s");
        if(context.mounted) { // Verifica antes do SnackBar no catch
          showCustomSnackBar(context: context, text: 'Erro inesperado ao excluir.', type: SnackBarType.error);
        }
     }
  }

  // Função para navegar para edição (com mounted check)
  Future<void> _navigateToEdit(BuildContext context, TransactionModel transaction) async {
    final result = await Navigator.pushNamed( context, NamedRoute.transaction, arguments: transaction, );
    if (result == true && context.mounted) {
      widget.onChange(); // Notifica o pai
    }
  }


  @override
  Widget build(BuildContext context) {
    // A lista já vem filtrada do widget pai (WalletPage)
    final transactionsToShow = widget.transactionList;

    // ----- CUSTOMSCROLLVIEW CORRIGIDO -----
    // Removemos shrinkWrap e physics para permitir scroll natural
    // dentro do espaço delimitado pelo widget pai (Expanded na HomePage)
    return CustomScrollView(
      // shrinkWrap: true, // REMOVIDO
      // physics: const NeverScrollableScrollPhysics(), // REMOVIDO
      controller: _scrollController, // Controller de scroll
      slivers: [
        // Estado Vazio: Mostra uma mensagem se a lista estiver vazia
        if (transactionsToShow.isEmpty)
          SliverFillRemaining( // Ocupa o espaço restante se a lista estiver vazia
            hasScrollBody: false, // Importante para não tentar rolar o vazio
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                child: Text(
                  // Mensagem pode variar um pouco dependendo do filtro aplicado na WalletPage
                  widget.filterType == 'upcomingBills'
                   ? 'Nenhuma conta pendente neste período.'
                   : 'Nenhuma transação registrada neste período.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.smallText.copyWith(color: AppColors.grey), // Seu estilo
                ),
              ),
            ),
          ),

        // Lista de Transações: Mostra os itens se a lista não estiver vazia
        if (transactionsToShow.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: transactionsToShow.length,
              (context, index) {
                final item = transactionsToShow[index];
                final color = item.value.isNegative ? AppColors.outcome : AppColors.income;
                final value = _currencyFormatter.format(item.value); // Usa o formatador
                final bool isIncome = item.value >= 0;
                // Ícone baseado na categoria ou Entrada/Saída (ajuste conforme seu helper)
                final IconData itemIcon = CategoryIconHelper.getIcon(item.category ?? '') ?? (isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);
                String formattedDate = 'Data inválida';
                 try { final date = DateTime.fromMillisecondsSinceEpoch(item.date); formattedDate = _dateFormatter.format(date); } catch (e) { /* Log erro se quiser */ }

                // Widget Dismissible para cada item
                return Dismissible(
                   key: ValueKey(item.id ?? item.hashCode), // Chave única
                   direction: DismissDirection.endToStart, // Direção do arrasto
                   background: Container( color: AppColors.error.withOpacity(0.85), padding: const EdgeInsets.symmetric(horizontal: 20.0), alignment: Alignment.centerRight, child: const Icon(Icons.delete_outline, color: Colors.white, size: 28), ), // Fundo vermelho
                   confirmDismiss: (direction) async => await _confirmDelete(context, item), // Chama confirmação
                   onDismissed: (direction) async { await _deleteTransaction(context, item); }, // Chama exclusão (agora async/await)
                   // ListTile para exibir a transação
                   child: ListTile(
                     onTap: () => _navigateToEdit(context, item), // Chama edição
                     contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0), // Padding do ListTile
                     leading: CircleAvatar( radius: 22, backgroundColor: color.withAlpha(30), foregroundColor: color, child: Icon(itemIcon, size: 20), ),
                     title: Text( item.description.isNotEmpty ? item.description : (item.category ?? 'Sem Categoria'), style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey), maxLines: 1, overflow: TextOverflow.ellipsis, ),
                     subtitle: Text( item.category?.capitalize() ?? 'Sem Categoria',
                                      style: AppTextStyles.smallText13.copyWith(color: AppColors.lightGrey),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,),
                     trailing: Column( // Valor e Status/Data na direita
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text( value.replaceAll(RegExp(r'\s+'), ''), // Remove espaços extras do R$
                               style: AppTextStyles.mediumText16w600.copyWith(color: color)),
                         const SizedBox(height: 2),
                         // Exibe Status (Pago/Pendente) - Verifique se 'AppColors.notification' existe
                         Text( item.status ? 'Pago' : 'Pendente',
                               style: AppTextStyles.smallText13.copyWith(
                                 color: item.status ? AppColors.income.withAlpha(230) : AppColors.notification?.withAlpha(230) ?? Colors.orange, // Fallback para orange
                                 fontSize: (AppTextStyles.smallText13.fontSize ?? 13) * 0.95,
                                 fontWeight: item.status ? FontWeight.normal : FontWeight.w500,
                               ),
                         ),
                       ],
                     ),
                   ),
                 );
              }, // fim do itemBuilder
            ), // fim do SliverChildBuilderDelegate
          ), // fim do SliverList
      ], // fim dos slivers
    );
    // ----- FIM DO CUSTOMSCROLLVIEW CORRIGIDO -----
  }
}