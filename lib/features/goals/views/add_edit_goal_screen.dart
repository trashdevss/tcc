// lib/features/goals/view/add_edit_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
import 'package:intl/intl.dart'; // Para NumberFormat
import 'package:tcc_3/common/utils/money_mask_controller.dart';

// --- AJUSTE ESTE IMPORT ---
// Importe seu MoneyMaskedTextController (ajuste o caminho se necessário)
// --------------------------

import 'package:tcc_3/common/models/goal.dart';
// Ajuste os caminhos
import '../../../services/goal_service.dart';
// Importe constantes se usar (ex: AppColors, AppTextStyles)
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';


class AddEditGoalScreen extends StatefulWidget {
  final GoalService goalService;
  final Goal? goalToEdit;

  const AddEditGoalScreen({
    super.key,
    required this.goalService,
    this.goalToEdit,
  });

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  // Usando TextEditingController normal para Valor Alvo, como no seu código original
  late TextEditingController _targetAmountController;
  bool _isLoading = false;

  // +++ Controllers e Variável para a Calculadora +++
  final _calcMonthsController = TextEditingController();
  final _calcSavedController = MoneyMaskedTextController( // Controller de máscara para valor já guardado
      prefix: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.',
  );
  String? _calcResultText; // Guarda o texto do resultado da calculadora
  // +++++++++++++++++++++++++++++++++++++++++++++++

  bool get _isEditing => widget.goalToEdit != null;

  // Formatter para exibir resultado da calculadora
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goalToEdit?.name ?? '');
    _targetAmountController = TextEditingController(
        text: widget.goalToEdit != null
            ? widget.goalToEdit!.targetAmount.toStringAsFixed(2).replaceAll('.', ',') // Mantém formatação com vírgula
            : '');
    // Inicializa valor já guardado da calculadora (se editando meta que já tem valor atual)
     _calcSavedController.updateValue(widget.goalToEdit?.currentAmount ?? 0.0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    // +++ Dispose dos controllers da calculadora +++
    _calcMonthsController.dispose();
    _calcSavedController.dispose();
    // ++++++++++++++++++++++++++++++++++++++++++++++
    super.dispose();
  }

  // Função para salvar/atualizar meta (sem alterações)
  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final name = _nameController.text;
      // Converte valor alvo (tratando vírgula)
      final targetAmount = double.tryParse(_targetAmountController.text.replaceAll(',', '.')) ?? 0.0;

      try {
        if (_isEditing) {
          await widget.goalService.updateGoal( widget.goalToEdit!.id, name, targetAmount, /* Passar currentAmount se necessário */ );
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Meta "$name" atualizada!'), backgroundColor: Colors.blue), );
        } else {
          await widget.goalService.addGoal(name, targetAmount);
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Meta "$name" criada!'), backgroundColor: Colors.green), );
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao salvar meta: $e'), backgroundColor: Colors.red), );
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }


  // +++ Função para Calcular Economia Mensal +++
  void _calculateMonthlySavings() {
    FocusScope.of(context).unfocus(); // Esconde teclado

    // Pega valor alvo do formulário principal, tratando vírgula
    final double? goalAmount = double.tryParse(_targetAmountController.text.replaceAll(',', '.'));
    // Pega meses do novo campo da calculadora
    final int? months = int.tryParse(_calcMonthsController.text);
     // Pega valor já guardado do novo campo da calculadora
    final double alreadySaved = _calcSavedController.numberValue;

    // Validações
    if (goalAmount == null || goalAmount <= 0) {
      setState(() => _calcResultText = "Insira um 'Valor Alvo' válido acima.");
      return;
    }
     if (months == null || months <= 0) {
      setState(() => _calcResultText = "Insira um número de meses válido.");
      return;
    }
    if (alreadySaved < 0) {
       setState(() => _calcResultText = "O valor já guardado não pode ser negativo.");
       return;
    }
     if (alreadySaved >= goalAmount) {
       setState(() => _calcResultText = "Parabéns! Você já alcançou ou superou esta meta!");
       return;
    }

    // Cálculo
    final double amountNeeded = goalAmount - alreadySaved;
    final double monthlySavings = amountNeeded / months;

    // Formata e exibe o resultado
    final formattedGoal = _currencyFormatter.format(goalAmount);
    final formattedMonthly = _currencyFormatter.format(monthlySavings);
    setState(() {
      _calcResultText = "Para alcançar $formattedGoal em $months meses, tente guardar $formattedMonthly por mês.";
    });
  }
  // ++++++++++++++++++++++++++++++++++++++++++++


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Meta' : 'Criar Nova Meta'),
        // Ajuste estilo se desejar
      ),
      body: SingleChildScrollView( // Mantido para rolagem geral
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Campo Nome --- (Existente)
              TextFormField( controller: _nameController, decoration: const InputDecoration( labelText: 'Nome da Meta*', hintText: 'Ex: Viagem Fim de Semana', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag_outlined), ), maxLength: 50, validator: (value) { if (value == null || value.trim().isEmpty) { return 'O nome da meta não pode ficar vazio.'; } if (value.trim().length < 3) { return 'O nome deve ter pelo menos 3 caracteres.'; } return null; },
              ),
              const SizedBox(height: 24.0),

              // --- Campo Valor Alvo --- (Existente)
              TextFormField( controller: _targetAmountController, decoration: const InputDecoration( labelText: 'Valor Alvo*', hintText: 'Ex: 100,00', prefixText: 'R\$ ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monetization_on_outlined), ), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]?\d{0,2})')), ], validator: (value) { if (value == null || value.isEmpty) { return 'Insira o valor alvo.'; } final amount = double.tryParse(value.replaceAll(',', '.')); if (amount == null || amount <= 0) { return 'O valor alvo deve ser maior que zero.'; } return null; },
              ),
              const SizedBox(height: 24.0), // Espaço antes da calculadora

              // =========== CALCULADORA DE METAS INSERIDA AQUI ===========
              Divider(thickness: 1, height: 32), // Separador visual
              Text("Planejamento (Opcional)", style: AppTextStyles.mediumText16w600), // Título da seção
              const SizedBox(height: 16.0),

              // Campo "Em quantos meses?"
              TextFormField(
                  controller: _calcMonthsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Só números inteiros
                  decoration: const InputDecoration(
                    labelText: "Em quantos meses?",
                    hintText: "Ex: 12",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    isDense: true,
                  ),
                  validator: (value){ // Validação opcional aqui também
                    if (value != null && value.isNotEmpty){
                      final months = int.tryParse(value);
                      if (months == null || months <= 0) return 'Valor inválido.';
                    }
                    return null;
                  },
              ),
              const SizedBox(height: 12.0),

              // Campo "Quanto já tenho guardado?"
              TextFormField(
                controller: _calcSavedController, // Usando o controller de máscara
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Quanto já tenho? (R\$)",
                  hintText: "Ex: 200,00",
                  // prefixText: 'R\$ ', // Controller já coloca
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.savings_outlined),
                  isDense: true,
                ),
                 validator: (value){ // Validação opcional
                    if (value != null && _calcSavedController.numberValue < 0) {
                       return 'Valor inválido.';
                    }
                    return null;
                  },
              ),
              const SizedBox(height: 16.0),

              // Botão "Calcular"
              OutlinedButton.icon( // Botão diferente para não confundir com o Salvar
                  onPressed: _calculateMonthlySavings, // Chama a função de cálculo
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text("Calcular quanto guardar por mês"),
                  style: OutlinedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     //foregroundColor: AppColors.primary, // Cor opcional
                     //side: BorderSide(color: AppColors.primary), // Borda opcional
                  ),
              ),
              const SizedBox(height: 16.0),

              // Texto do Resultado da Calculadora
              if (_calcResultText != null && _calcResultText!.isNotEmpty)
                Center(
                  child: Text( _calcResultText!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.mediumText14.copyWith(color: AppColors.darkGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 16.0),
              Divider(thickness: 1, height: 32), // Separador visual
             // ============================================================

              const SizedBox(height: 24.0), // Espaço antes do botão salvar

              // --- Botão Salvar --- (Existente)
              ElevatedButton.icon( icon: _isLoading ? Container( width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator( color: Colors.white, strokeWidth: 3, ), ) : Icon(_isEditing ? Icons.save_alt : Icons.check_circle_outline), label: Text(_isLoading ? 'Salvando...' : (_isEditing ? 'Salvar Alterações' : 'Criar Meta')), style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), ), onPressed: _isLoading ? null : _saveGoal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}