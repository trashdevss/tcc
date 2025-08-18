// lib/features/metas/view/add_edit_goal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tcc_3/features/metas/goal_model.dart';
import 'package:uuid/uuid.dart';

import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/widgets/primary_button.dart';
import 'package:tcc_3/common/widgets/custom_snackbar.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/features/metas/goals_controller.dart';

class AddEditGoalPage extends StatefulWidget {
  final GoalModel? goalToEdit; // Recebe a meta para edição

  const AddEditGoalPage({super.key, this.goalToEdit});

  bool get isEditing => goalToEdit != null;

  @override
  State<AddEditGoalPage> createState() => _AddEditGoalPageState();
}

class _AddEditGoalPageState extends State<AddEditGoalPage> with CustomSnackBar {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  // +++ Controller para valor atual (necessário para edição) +++
  final _currentAmountController = TextEditingController();
  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  final _goalsController = locator.get<GoalsController>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      // Preenche campos no modo de edição
      _nameController.text = widget.goalToEdit!.name;
      _targetAmountController.text = widget.goalToEdit!.targetAmount.toStringAsFixed(2);
      _currentAmountController.text = widget.goalToEdit!.currentAmount.toStringAsFixed(2); // Preenche valor atual
    } else {
      // Define valor inicial 0 se adicionando
      _currentAmountController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose(); // Dispose do novo controller
    super.dispose();
  }

  // Função para salvar (Adicionar OU Editar)
  Future<void> _saveGoal() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final String name = _nameController.text;
      final double targetAmount = double.tryParse(_targetAmountController.text.replaceAll(',', '.')) ?? 0.0;
      // Pega valor atual do controller (seja editando ou o 0 inicial)
      final double currentAmount = double.tryParse(_currentAmountController.text.replaceAll(',', '.')) ?? 0.0;

      // Cria ou atualiza o objeto GoalModel
      final goal = GoalModel(
        id: widget.isEditing ? widget.goalToEdit!.id : const Uuid().v4(), // Usa ID existente ou gera novo
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount, // Usa valor do campo (importante para edição)
      );

      try {
        if (widget.isEditing) {
          // --- CHAMA updateGoal SE EDITANDO ---
          await _goalsController.updateGoal(goal);
          if (mounted) { showCustomSnackBar(context: context, text: "Meta '${goal.name}' atualizada!", type: SnackBarType.success); Navigator.pop(context, true); }
          // ------------------------------------
        } else {
          // --- CHAMA addGoal SE ADICIONANDO ---
          await _goalsController.addGoal(goal);
          if (mounted) { showCustomSnackBar(context: context, text: "Meta '${goal.name}' adicionada!", type: SnackBarType.success); Navigator.pop(context, true); }
          // ------------------------------------
        }
      } catch (e) {
         if (mounted) { showCustomSnackBar(context: context, text: "Erro ao ${widget.isEditing ? 'atualizar' : 'salvar'} meta: $e", type: SnackBarType.error); }
      } finally {
         if (mounted) { setState(() { _isLoading = false; }); }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Meta' : 'Nova Meta'),
        backgroundColor: AppColors.green, foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo Nome da Meta
              TextFormField( controller: _nameController, /* ... decoração ... */ decoration: InputDecoration( labelText: 'Nome da Meta', hintText: 'Ex: Comprar Notebook', prefixIcon: const Icon(Icons.flag_outlined, color: AppColors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder( borderSide: const BorderSide(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8), ), ), validator: (value) { if (value == null || value.trim().isEmpty) { return 'Nome é obrigatório'; } return null; }, ),
              const SizedBox(height: 16),

              // Campo Valor Alvo
              TextFormField( controller: _targetAmountController, /* ... decoração ... */ decoration: InputDecoration( labelText: 'Valor Alvo (R\$)', hintText: 'Ex: 5500.00', prefixIcon: const Icon(Icons.attach_money, color: AppColors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder( borderSide: const BorderSide(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8), ), ), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')),], validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Valor alvo inválido' : null, ),
              const SizedBox(height: 16),

              // +++ CAMPO VALOR ATUAL (Editável apenas no modo edição talvez?) +++
               TextFormField(
                 controller: _currentAmountController,
                 decoration: InputDecoration( labelText: 'Valor Atual Guardado (R\$)', hintText: 'Ex: 1200.00', prefixIcon: const Icon(Icons.savings_outlined, color: AppColors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder( borderSide: const BorderSide(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8), ), ),
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')),],
                 // Permitir edição ou não? Se não, adicione readOnly: !widget.isEditing
                 // readOnly: !widget.isEditing,
                  validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '-1') ?? -1) < 0 ? 'Valor atual inválido' : null, // Permite 0
               ),
              // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

              const SizedBox(height: 32),
              PrimaryButton( text: _isLoading ? 'Salvando...' : (widget.isEditing ? 'Atualizar Meta' : 'Adicionar Meta'), onPressed: _isLoading ? null : _saveGoal, ),
            ],
          ),
        ),
      ),
    );
  }
}