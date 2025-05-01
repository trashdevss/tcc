// lib/features/transactions/transaction_page.dart

import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import para NumberFormat (se usado na validação ou em outro lugar)
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/helpers/category_icon_helper.dart'; // Verifique path
import '../../common/constants/constants.dart';
import '../../common/extensions/extensions.dart';
import '../../common/features/transaction/transaction.dart';
import '../../common/models/models.dart';
import '../../common/utils/utils.dart'; // Para MoneyMaskedTextController
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

 // Listas de Categorias em PT-BR
 final _incomes = ['Salário', 'Serviços', 'Investimentos', 'Vendas', 'Reembolsos', 'Outros'];
 final _outcomes = ['Moradia', 'Alimentação', 'Contas', 'Transporte', 'Lazer', 'Educação', 'Saúde', 'Vestuário', 'Compras', 'Viagens', 'Outros'];

 DateTime? _newDate;
 bool value = false; // Status pago/pendente

 final _descriptionController = TextEditingController();
 final _categoryController = TextEditingController();
 final _dateController = TextEditingController();

 // <<< CORREÇÃO 1: Usar 'prefix' em vez de 'leftSymbol' >>>
 final _amountController = MoneyMaskedTextController(
     decimalSeparator: ',', thousandSeparator: '.', prefix: 'R\$ '); // Corrigido aqui!

 late final TabController _tabController;

 // ... (Restante do initState, dispose, _handleTransactionStateChange como antes) ...
 int get _initialIndex { if (widget.transaction != null && widget.transaction!.value.isNegative) { return 1; } return 0; }
 String get _date { if (widget.transaction?.date != null) { return DateTime.fromMillisecondsSinceEpoch(widget.transaction!.date).toText; } else { return ''; } }
 @override
 void initState() {
   super.initState();
   _amountController.updateValue(widget.transaction?.value.abs() ?? 0);
   value = widget.transaction?.status ?? false;
   _descriptionController.text = widget.transaction?.description ?? '';
   _categoryController.text = widget.transaction?.category ?? '';
   _newDate = widget.transaction?.date != null ? DateTime.fromMillisecondsSinceEpoch(widget.transaction!.date) : DateTime.now();
   _dateController.text = _newDate!.toText;
   _tabController = TabController( length: 2, vsync: this, initialIndex: _initialIndex, );
   _transactionController.addListener(_handleTransactionStateChange);
 }
 @override
 void dispose() {
   _tabController.dispose(); _amountController.dispose(); _descriptionController.dispose(); _categoryController.dispose(); _dateController.dispose(); _transactionController.removeListener(_handleTransactionStateChange);
   super.dispose();
 }
 void _handleTransactionStateChange() {
   final state = _transactionController.state;
   switch (state.runtimeType) {
     case TransactionStateLoading: if (!mounted) return; showDialog( barrierDismissible: false, context: context, builder: (context) => const CustomCircularProgressIndicator(), ); break;
     case TransactionStateSuccess: if (!mounted) return; if (Navigator.of(context).canPop()){ Navigator.of(context).pop();} break;
     case TransactionStateError: if (!mounted) return; if (Navigator.of(context).canPop()){ Navigator.of(context).pop();} showCustomSnackBar( context: context, text: (state as TransactionStateError).message, type: SnackBarType.error, ); break;
   }
 }


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: Stack(
       children: [
         AppHeader(
           preffixOption: true,
           title: widget.transaction != null ? 'Editar Transação' : 'Adicionar Transação',
         ),
         Positioned(
           top: 164.h, // Ajuste conforme necessário
           left: 28.w,
           right: 28.w,
           bottom: 16.h,
           child: Container(
             padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
             decoration: BoxDecoration( color: AppColors.white, borderRadius: BorderRadius.circular(16.0), boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: Offset(0, 2),), ] ),
             child: Form(
               key: _formKey,
               child: SingleChildScrollView(
                 physics: const BouncingScrollPhysics(),
                 child: Column(
                   children: [
                     StatefulBuilder( // TabBar Income/Expense
                       builder: (context, setState) { /* ... código da TabBar ... */
                          return TabBar( labelPadding: EdgeInsets.zero, controller: _tabController, onTap: (_) { if (_tabController.indexIsChanging && _categoryController.text.isNotEmpty) { _categoryController.clear(); } setState(() {}); }, tabs: [ Tab( child: Container( alignment: Alignment.center, decoration: BoxDecoration( color: _tabController.index == 0 ? AppColors.iceWhite : AppColors.white, borderRadius: const BorderRadius.all( Radius.circular(24.0), ), ), child: Text( 'Receita', style: AppTextStyles.mediumText16w500 .apply(color: AppColors.darkGrey), ), ), ), Tab( child: Container( alignment: Alignment.center, decoration: BoxDecoration( color: _tabController.index == 1 ? AppColors.iceWhite : AppColors.white, borderRadius: const BorderRadius.all( Radius.circular(24.0), ), ), child: Text( 'Despesa', style: AppTextStyles.mediumText16w500 .apply(color: AppColors.darkGrey), ), ), ), ], );
                       },
                     ),
                     const SizedBox(height: 16.0),

                     // --- Campo Valor ---
                     CustomTextFormField(
                       padding: const EdgeInsets.symmetric(vertical: 8.0),
                       controller: _amountController,
                       keyboardType: TextInputType.number,
                       labelText: "Valor",
                       hintText: "Digite o valor",
                       suffixIcon: StatefulBuilder( builder: (context, setState) { return IconButton( onPressed: () => setState(() => value = !value), icon: Icon( value ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded, color: value ? AppColors.green : AppColors.notification, ), ); }, ),
                       validator: (value) { if (_amountController.numberValue <= 0) { return 'Digite um valor válido.'; } return null; },
                     ),

                     // --- Campo Descrição ---
                     CustomTextFormField(
                       padding: const EdgeInsets.symmetric(vertical: 8.0),
                       controller: _descriptionController,
                       labelText: 'Descrição',
                       hintText: 'Adicione uma descrição',
                       // <<< CORREÇÃO 2: Validador inline >>>
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Este campo não pode ser vazio.';
                         }
                         return null;
                       },
                     ),

                     // --- Campo Categoria ---
                     CustomTextFormField(
                       padding: const EdgeInsets.symmetric(vertical: 8.0),
                       controller: _categoryController,
                       readOnly: true,
                       labelText: "Categoria",
                       hintText: "Selecione uma categoria",
                       suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                        // <<< CORREÇÃO 3: Validador inline >>>
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Este campo não pode ser vazio.';
                         }
                         return null;
                       },
                       onTap: () async { /* ... código do showModalBottomSheet ... */
                          final categories = _tabController.index == 0 ? _incomes : _outcomes;
                          final selectedCategory = await showModalBottomSheet<String>( context: context, shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(24)), ), builder: (context) { return ListView.builder( itemCount: categories.length, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemBuilder: (context, index) { final categoryName = categories[index]; return ListTile( leading: Icon(CategoryIconHelper.getIcon(categoryName)), title: Text(categoryName), onTap: () { Navigator.pop(context, categoryName); }, ); }, ); } );
                          if (selectedCategory != null && selectedCategory.isNotEmpty) { _categoryController.text = selectedCategory; }
                       },
                     ),

                     // --- Campo Data ---
                     CustomTextFormField(
                       padding: const EdgeInsets.symmetric(vertical: 8.0),
                       controller: _dateController,
                       readOnly: true,
                       suffixIcon: const Icon(Icons.calendar_month_outlined),
                       labelText: "Data",
                       hintText: "Selecione uma data",
                        // <<< CORREÇÃO 4: Validador inline >>>
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Este campo não pode ser vazio.';
                         }
                         return null;
                       },
                       onTap: () async { /* ... código do showDatePicker ... */
                         DateTime? pickedDate = await showDatePicker( context: context, initialDate: _newDate ?? DateTime.now(), firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime(DateTime.now().year + 5), );
                         if (pickedDate != null) { _newDate = DateTime.now().copyWith( day: pickedDate.day, month: pickedDate.month, year: pickedDate.year, ); _dateController.text = _newDate!.toText; }
                       },
                     ),
                     const SizedBox(height: 16.0),

                     // --- Botão Salvar/Adicionar ---
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                       child: PrimaryButton(
                         text: widget.transaction != null ? 'Salvar Alterações' : 'Adicionar Transação',
                         onPressed: () async { /* ... código do onPressed (lógica de salvar/adicionar) ... */
                            FocusScope.of(context).unfocus();
                            if (_formKey.currentState!.validate()) {
                              final newValue = _amountController.numberValue;
                              final now = DateTime.now().millisecondsSinceEpoch;
                              final finalDate = _newDate?.millisecondsSinceEpoch ?? now;
                              final newTransaction = TransactionModel( id: widget.transaction?.id, category: _categoryController.text, description: _descriptionController.text, value: _tabController.index == 1 ? newValue * -1 : newValue, date: finalDate, createdAt: widget.transaction?.createdAt ?? now, status: value, );
                              if (widget.transaction != null && widget.transaction == newTransaction) { Navigator.pop(context); return; }
                              if (widget.transaction != null) { await _transactionController.updateTransaction(newTransaction); await _balanceController.updateBalance( oldTransaction: widget.transaction!, newTransaction: newTransaction, ); } else { await _transactionController.addTransaction(newTransaction); await _balanceController.updateBalance( newTransaction: newTransaction, ); }
                              if (mounted && Navigator.canPop(context)) { Navigator.of(context).pop(true); }
                            } else { log('Formulário inválido'); }
                          },
                       ),
                     ),
                   ],
                 ),
               ),
             ),
           ),
         ),
       ],
     ),
   );
 }
}