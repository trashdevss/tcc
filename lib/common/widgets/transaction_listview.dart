// lib/common/widgets/transaction_listview.dart (ou seu caminho)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import para DateFormat
import 'package:tcc_3/common/features/balance_controller.dart';
// Ajuste os imports conforme sua estrutura
import 'package:tcc_3/common/widgets/custom_bottom_sheet.dart';
import 'package:tcc_3/common/widgets/custom_snackbar.dart';

import '../../locator.dart';
import '../constants/constants.dart';
// import '../extensions/date_time_ext.dart'; // Removido se usar DateFormat
import '../features/transaction/transaction_controller.dart';
import '../features/transaction/transaction_state.dart';
import '../models/transaction_model.dart'; // Seu modelo de transação

class TransactionListView extends StatefulWidget {
  // Construtor aceitando shrinkWrap e physics
  const TransactionListView({
    super.key,
    required this.transactionList,
    required this.onChange,
    this.selectedDate,
    this.filterType,
    this.shrinkWrap = false, // Necessário para Column/ListView dentro de SingleChildScrollView
    this.physics,          // Usado para determinar se deve ser rolável ou não
  });

  final List<TransactionModel> transactionList;
  final DateTime? selectedDate;
  final String? filterType;
  final VoidCallback onChange;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView>
    with CustomModalSheetMixin, CustomSnackBar, SingleTickerProviderStateMixin {

  final _transactionController = locator.get<TransactionController>();
  final _balanceController = locator.get<BalanceController>();

  @override
  void initState() {
    super.initState();
    _transactionController.addListener(_handleTransactionStateChange);
  }

  @override
  void dispose() {
    _transactionController.removeListener(_handleTransactionStateChange);
    super.dispose();
  }

  // Trata estados de erro do controller
  void _handleTransactionStateChange() {
    final state = _transactionController.state;
    switch (state.runtimeType) {
      case TransactionStateError:
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
          }
        });
        break;
    }
  }

  // Função para confirmar e deletar a transação
  Future<bool> _confirmDeleteTransaction(TransactionModel item) async {
      final bool? confirm = await showCustomModalBottomSheet(
        context: context,
        content: 'Deseja realmente excluir a transação "${item.description.isNotEmpty ? item.description : "sem descrição"}"?',
        actions: [ /* ... seus botões ... */ ],
      );
      return confirm ?? false;
  }

  // Função para executar a exclusão
  Future<void> _deleteTransaction(TransactionModel item) async {
     try {
       await _transactionController.deleteTransaction(item);
       await _balanceController.updateBalance(oldTransaction: item, newTransaction: item.copyWith(value: 0));
       widget.onChange.call();
       if(mounted){ showCustomSnackBar(context: context, text: 'Transação excluída.', type: SnackBarType.success); }
    } catch(e) {
       if(mounted){ showCustomSnackBar(context: context, text: 'Erro ao excluir: $e', type: SnackBarType.error); }
    }
  }

  // Função helper para construir um item da lista (ListTile com Dismissible)
  Widget _buildTransactionItem(TransactionModel item) {
      final bool isIncome = item.value >= 0;
      final Color itemColor = isIncome ? AppColors.income : AppColors.outcome;
      final IconData itemIcon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
      final valueString = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(item.value);
      String formattedDate = 'Data inválida';
      try {
         final date = DateTime.fromMillisecondsSinceEpoch(item.date);
         formattedDate = DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
      } catch (e) { print("Erro formatar data: $e"); }

      return Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
           color: AppColors.error.withOpacity(0.85),
           padding: const EdgeInsets.symmetric(horizontal: 20.0),
           alignment: Alignment.centerRight,
           child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
         ),
        confirmDismiss: (direction) => _confirmDeleteTransaction(item),
        onDismissed: (direction) => _deleteTransaction(item),
        child: ListTile(
          onTap: () async {
             final result = await Navigator.pushNamed(context, '/transaction', arguments: item);
             if (result == true && mounted) { widget.onChange.call(); }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: CircleAvatar(
            backgroundColor: itemColor.withAlpha(30),
            foregroundColor: itemColor,
            child: Icon(itemIcon, size: 20),
          ),
          title: Text(
            item.description.isNotEmpty ? item.description : (item.category),
            style: AppTextStyles.mediumText16w500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            formattedDate,
            style: AppTextStyles.smallText13.copyWith(color: AppColors.lightGrey),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text( valueString, style: AppTextStyles.mediumText16w600.copyWith(color: itemColor)),
              const SizedBox(height: 2),
              Text(
                item.status ? 'Pago' : 'Pendente',
                style: AppTextStyles.smallText13.copyWith(
                  color: item.status ? AppColors.income.withAlpha(230) : AppColors.notification.withAlpha(230),
                  fontSize: (AppTextStyles.smallText13.fontSize ?? 13) * 0.95,
                  fontWeight: item.status ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
  }


  @override
  Widget build(BuildContext context) {
    // Lógica de filtragem (mantida)
    List<TransactionModel> filteredTransactions = widget.transactionList;
    if (widget.selectedDate != null) {
      // ... sua lógica de filtro ...
       filteredTransactions = widget.transactionList.where((transaction) {
        final transactionDate = DateTime.fromMillisecondsSinceEpoch(transaction.date);
        final sameMonth = transactionDate.month == widget.selectedDate!.month;
        final sameYear = transactionDate.year == widget.selectedDate!.year;
        if (widget.filterType == 'upcomingBills') {
          return sameMonth && sameYear && !transaction.status;
        }
        return sameMonth && sameYear;
      }).toList();
    }

    // ==============================================
    // <<<--- LÓGICA DE RENDERIZAÇÃO CONDICIONAL --- >>>
    // ==============================================
    // Verifica se a física indica que NÃO deve rolar (geralmente quando dentro de outro scroll)
    final bool isNonScrollable = widget.physics is NeverScrollableScrollPhysics;

    // Se a lista filtrada estiver vazia, mostra a mensagem
    if (filteredTransactions.isEmpty) {
      // Se não for rolável, usa um Container simples
      if (isNonScrollable) {
         return Center(
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
             child: Text(
               widget.filterType == 'upcomingBills' ? 'Nenhuma conta pendente encontrada.' : 'Nenhuma transação encontrada.',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.grey[600], fontSize: 15),
             ),
           ),
         );
      } else { // Se for rolável (usado em tela cheia), usa SliverFillRemaining
         return CustomScrollView(
            physics: widget.physics ?? const BouncingScrollPhysics(), // Usa a física passada ou padrão
            slivers: [
               SliverFillRemaining(
                 hasScrollBody: false,
                 child: Center(
                   child: Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                     child: Text(
                       widget.filterType == 'upcomingBills' ? 'Nenhuma conta pendente encontrada.' : 'Nenhuma transação encontrada.',
                       textAlign: TextAlign.center,
                       style: TextStyle(color: Colors.grey[600], fontSize: 15),
                     ),
                   ),
                 ),
               ),
            ],
         );
      }
    }

    // Se TEM itens e NÃO deve rolar (está dentro de SingleChildScrollView)
    if (isNonScrollable) {
      // Retorna uma Column simples com os itens
      return Column(
        // shrinkWrap é implícito em Column
        children: filteredTransactions.map(_buildTransactionItem).toList(),
      );
    } else {
      // Se TEM itens e PODE rolar (usado como lista principal)
      // Retorna o CustomScrollView com SliverList
      return CustomScrollView(
        shrinkWrap: widget.shrinkWrap, // Passa shrinkWrap (geralmente false aqui)
        physics: widget.physics ?? const BouncingScrollPhysics(), // Usa a física passada ou padrão
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTransactionItem(filteredTransactions[index]),
              childCount: filteredTransactions.length,
            ),
          ),
        ],
      );
    }
    // ==============================================
  }
}

// --- Lembretes ---
// ... (Imports, Constantes, Intl, etc.)
