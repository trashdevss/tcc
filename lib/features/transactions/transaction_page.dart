import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
// --- AJUSTE ESTE IMPORT ---
// Coloque o caminho relativo CORRETO para o arquivo onde você
// definiu sua classe MoneyMaskedTextController. Exemplo:

import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/helpers/category_icon_helper.dart';
import '../../common/constants/constants.dart';
import '../../common/extensions/extensions.dart';
import '../../common/features/transaction/transaction.dart';
import '../../common/models/models.dart';
import '../../common/utils/utils.dart';
import '../../common/widgets/widgets.dart';
import '../../locator.dart';

class TransactionPage extends StatefulWidget {
  final TransactionModel? transaction;
  const TransactionPage({
    super.key,
    this.transaction,
  });

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin, CustomSnackBar {
  final _transactionController = locator.get<TransactionController>();
  final _balanceController = locator.get<BalanceController>();

  final _formKey = GlobalKey<FormState>();

  // Categorias em Português
  final List<String> _receitas = [ 'Salário', 'Serviços', 'Vendas', 'Investimentos', 'Mesada', 'Bolsa Auxílio', 'Presente', 'Reembolso', 'Aluguel Recebido', 'Outras Receitas' ];
  final List<String> _despesas = [ 'Moradia', 'Mercado', 'Alimentação Fora', 'Transporte', 'Contas Fixas', 'Lazer e Hobbies', 'Educação', 'Saúde', 'Roupas e Calçados', 'Cuidados Pessoais', 'Assinaturas', 'Presentes (Dados)', 'Dívidas/Empréstimos', 'Impostos e Taxas', 'Pets', 'Viagem', 'Casa e Decoração', 'Doações', 'Saques', 'Outras Despesas' ];

  DateTime? _newDate;
  bool value = false; // Status Pago/Não Pago

  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = MoneyMaskedTextController( prefix: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.', );

  late final TabController _tabController;

  int get _initialIndex { if (widget.transaction != null && widget.transaction!.value.isNegative) { return 1; } return 0; }
  String get _date { if (widget.transaction?.date != null) { return DateTime.fromMillisecondsSinceEpoch(widget.transaction!.date).toText; } else { return ''; } }

  @override
  void initState() { super.initState(); _amountController.updateValue(widget.transaction?.value.abs() ?? 0.0); value = widget.transaction?.status ?? false; _descriptionController.text = widget.transaction?.description ?? ''; _categoryController.text = widget.transaction?.category ?? ''; _newDate = widget.transaction?.date != null ? DateTime.fromMillisecondsSinceEpoch(widget.transaction!.date) : null; _dateController.text = _newDate?.toText ?? ''; _tabController = TabController( length: 2, vsync: this, initialIndex: _initialIndex, ); _transactionController.addListener(_handleTransactionStateChange); }
  @override
  void dispose() { _tabController.dispose(); _amountController.dispose(); _descriptionController.dispose(); _categoryController.dispose(); _dateController.dispose(); _transactionController.removeListener(_handleTransactionStateChange); super.dispose(); }

  void _handleTransactionStateChange() { final state = _transactionController.state; switch (state.runtimeType) { case TransactionStateLoading: if(Navigator.of(context).canPop()) Navigator.of(context).pop(); if (!mounted) return; showDialog( barrierDismissible: false, context: context, builder: (context) => const CustomCircularProgressIndicator(), ); break; case TransactionStateSuccess: if(Navigator.of(context).canPop()) Navigator.of(context).pop(); if(Navigator.of(context).canPop()) Navigator.of(context).pop(true); break; case TransactionStateError: if(Navigator.of(context).canPop()) Navigator.of(context).pop(); if (!mounted) return; showCustomSnackBar( context: context, text: (state as TransactionStateError).message, type: SnackBarType.error, ); break; } }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          AppHeader( preffixOption: true, title: widget.transaction != null ? 'Edit Transaction' : 'Add Transaction', ),
          Positioned(
            top: 164.h, left: 28.w, right: 28.w, bottom: 16.h,
            child: Container(
              decoration: BoxDecoration( color: AppColors.white, borderRadius: BorderRadius.circular(16.0), ),
              child: Form(
                key: _formKey,
                child: ListView( // Layout principal com ListView para rolagem geral
                  padding: const EdgeInsets.all(16.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                       StatefulBuilder( builder: (context, setState) { return TabBar( labelPadding: EdgeInsets.zero, controller: _tabController, onTap: (_) { if (_tabController.indexIsChanging) { setState(() {}); final currentList = _tabController.index == 0 ? _receitas : _despesas; if (_categoryController.text.isNotEmpty && !currentList.contains(_categoryController.text)) { _categoryController.clear(); } } }, tabs: [ Tab( child: Container( alignment: Alignment.center, decoration: BoxDecoration( color: _tabController.index == 0 ? AppColors.iceWhite : AppColors.white, borderRadius: const BorderRadius.all(Radius.circular(24.0)), ), child: Text( 'Income', style: AppTextStyles.mediumText16w500.apply(color: AppColors.darkGrey), ), ), ), Tab( child: Container( alignment: Alignment.center, decoration: BoxDecoration( color: _tabController.index == 1 ? AppColors.iceWhite : AppColors.white, borderRadius: const BorderRadius.all(Radius.circular(24.0)), ), child: Text( 'Expense', style: AppTextStyles.mediumText16w500.apply(color: AppColors.darkGrey), ), ), ), ], ); }, ),
                       const SizedBox(height: 16.0),
                       CustomTextFormField( padding: const EdgeInsets.symmetric(vertical: 8.0), controller: _amountController, keyboardType: TextInputType.number, labelText: "Amount", hintText: "Type an amount", suffixIcon: StatefulBuilder( builder: (context, setState) { return IconButton( onPressed: () { setState(() { value = !value; }); }, icon: AnimatedContainer( transform: value ? Matrix4.rotationX(math.pi * 2) : Matrix4.rotationX(math.pi), transformAlignment: Alignment.center, duration: const Duration(milliseconds: 200), child: Icon(value ? Icons.thumb_up_alt_rounded: Icons.thumb_down_alt_rounded, color: value ? AppColors.green : AppColors.grey), ), tooltip: value ? 'Paid' : 'Unpaid', ); }, ), validator: (v) => _amountController.numberValue <= 0 ? 'Enter a value greater than zero.' : null, ),
                       CustomTextFormField( padding: const EdgeInsets.symmetric(vertical: 8.0), controller: _descriptionController, labelText: 'Description', hintText: 'Add a description', validator: (v) => _descriptionController.text.isEmpty ? 'This field cannot be empty.' : null, ),
                       CustomTextFormField(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          controller: _categoryController,
                          readOnly: true,
                          labelText: "Category", hintText: "Select a category",
                          validator: (v) => _categoryController.text.isEmpty ? 'This field cannot be empty.' : null,
                          // ========== CORREÇÃO DO BOTTOM SHEET ==========
                          onTap: () => showModalBottomSheet(
                            // isScrollControlled: true, // REMOVIDO para usar altura padrão
                            context: context,
                            shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            builder: (context) {
                                final categories = _tabController.index == 0 ? _receitas : _despesas;
                                // Usando ListView.builder para rolagem interna
                                return ListView.builder(
                                    shrinkWrap: true, // Importante
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                        final category = categories[index];
                                        return ListTile(
                                            leading: Icon(CategoryIconHelper.getIcon(category), color: AppColors.darkGrey),
                                            title: Text(category),
                                            onTap: () {
                                                _categoryController.text = category;
                                                Navigator.pop(context);
                                            },
                                        );
                                    },
                                );
                            },
                          ),
                          // ============================================
                       ),
                       CustomTextFormField( padding: const EdgeInsets.symmetric(vertical: 8.0), controller: _dateController, readOnly: true, suffixIcon: const Icon(Icons.calendar_month_outlined), labelText: "Date", hintText: "Select a date", validator: (v) => _dateController.text.isEmpty ? 'This field cannot be empty.' : null, onTap: () async { DateTime initialPickerDate = _newDate ?? DateTime.now(); DateTime firstPickerDate = DateTime(DateTime.now().year - 5); DateTime lastPickerDate = DateTime(DateTime.now().year + 5); DateTime? pickedDate = await showDatePicker( context: context, initialDate: initialPickerDate, firstDate: firstPickerDate, lastDate: lastPickerDate, ); if (pickedDate != null) { final TimeOfDay originalTime = _newDate != null ? TimeOfDay.fromDateTime(_newDate!) : TimeOfDay.now(); setState(() { _newDate = DateTime( pickedDate.year, pickedDate.month, pickedDate.day, originalTime.hour, originalTime.minute, ); _dateController.text = _newDate!.toText; }); } }, ),
                       const SizedBox(height: 16.0),
                       Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0), child: PrimaryButton( text: widget.transaction != null ? 'Save' : 'Add', onPressed: () async { FocusScope.of(context).unfocus(); if (_formKey.currentState!.validate()) { final newValue = _amountController.numberValue; final now = DateTime.now(); final DateTime transactionDate = _newDate ?? now; final newTransaction = TransactionModel( category: _categoryController.text, description: _descriptionController.text, value: _tabController.index == 1 ? newValue * -1 : newValue, date: transactionDate.millisecondsSinceEpoch, createdAt: widget.transaction?.createdAt ?? now.millisecondsSinceEpoch, status: value, id: widget.transaction?.id, ); if (widget.transaction != null && widget.transaction == newTransaction) { Navigator.pop(context); return; } if (widget.transaction != null) { await _transactionController .updateTransaction(newTransaction); await _balanceController.updateBalance( oldTransaction: widget.transaction!, newTransaction: newTransaction, ); } else { await _transactionController .addTransaction(newTransaction); final TransactionModel dummyZero = TransactionModel( value: 0.0, date: 0, category: '', description: '', status: false, createdAt: 0, ); await _balanceController.updateBalance( newTransaction: newTransaction, oldTransaction: widget.transaction ?? dummyZero ); } } else { log('invalid'); } }, ), ),
                       if (widget.transaction != null)
                         Padding( padding: const EdgeInsets.only(top: 8.0), child: TextButton.icon( icon: const Icon(Icons.delete_outline, color: AppColors.outcome), label: Text( 'Delete Transaction', style: (AppTextStyles.mediumText14 ?? const TextStyle()).copyWith(color: AppColors.outcome), ), onPressed: () async { if (widget.transaction != null) { final TransactionModel dummyZeroTransaction = TransactionModel( id: widget.transaction!.id, category: widget.transaction!.category, description: widget.transaction!.description, value: 0.0, date: widget.transaction!.date, createdAt: widget.transaction!.createdAt, status: widget.transaction!.status, ); await _transactionController.deleteTransaction(widget.transaction!); await _balanceController.updateBalance( oldTransaction: widget.transaction!, newTransaction: dummyZeroTransaction, ); } }, ), ),
                       const SizedBox(height: 100.0),
                  ],
               ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}