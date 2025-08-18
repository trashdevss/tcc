// lib/features/metas/view/goals_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// Imports do seu projeto (ajuste os caminhos)
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/common/widgets/custom_circular_progress_indicator.dart';
import 'package:tcc_3/common/widgets/goal_card.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/features/metas/goals_controller.dart';
import 'package:tcc_3/features/metas/goals_state.dart';
import 'package:tcc_3/common/constants/routes.dart'; // Import das Rotas
import 'package:tcc_3/common/widgets/custom_snackbar.dart'; // Import do Snackbar Mixin/Widget

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

// Adiciona CustomSnackBar se não estiver global
class _GoalsScreenState extends State<GoalsScreen> with CustomSnackBar {
  // Calculadora
  final _calculatorFormKey = GlobalKey<FormState>();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController(text: '0');
  final _monthlyContributionController = TextEditingController();
  final _annualRateController = TextEditingController(text: '0');
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String? _estimatedTimeResult;
  bool _isCalculating = false;

  // Controller de Metas
  final _goalsController = locator.get<GoalsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _goalsController.fetchGoals(); // Busca metas ao iniciar
    });
  }

  @override
  void dispose() {
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _monthlyContributionController.dispose();
    _annualRateController.dispose();
    super.dispose();
  }

  void _calculateTimeToGoal() { /* ... (Lógica da calculadora - Sem alterações) ... */ FocusScope.of(context).unfocus(); if (_calculatorFormKey.currentState!.validate()) { setState(() { _isCalculating = true; _estimatedTimeResult = null; }); Future.delayed(const Duration(milliseconds: 100), () { final double targetAmount = double.tryParse(_targetAmountController.text.replaceAll(',', '.')) ?? 0.0; final double currentAmount = double.tryParse(_currentAmountController.text.replaceAll(',', '.')) ?? 0.0; final double monthlyContribution = double.tryParse(_monthlyContributionController.text.replaceAll(',', '.')) ?? 0.0; final double annualRatePercent = double.tryParse(_annualRateController.text.replaceAll(',', '.')) ?? 0.0; if (targetAmount <= currentAmount) { setState(() { _isCalculating = false; _estimatedTimeResult = "Meta já atingida ou superada!"; }); return; } if (monthlyContribution <= 0) { setState(() { _isCalculating = false; }); ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('O aporte mensal deve ser maior que zero.'), backgroundColor: Colors.red) ); return; } double remainingAmount = targetAmount - currentAmount; double monthlyRate = (annualRatePercent / 100) / 12; double currentBalance = currentAmount; int months = 0; const int maxMonths = 1200; if (monthlyRate > 0) { while (currentBalance < targetAmount && months < maxMonths) { months++; double interestThisMonth = currentBalance * monthlyRate; currentBalance += interestThisMonth; currentBalance += monthlyContribution; } } else { if (monthlyContribution <= 0) { setState(() { _isCalculating = false; _estimatedTimeResult = "Aporte mensal necessário."; }); return; } months = (remainingAmount / monthlyContribution).ceil(); } String resultText; if (months >= maxMonths) { resultText = "Mais de 100 anos"; } else { int years = months ~/ 12; int remainingMonths = months % 12; if (years > 0 && remainingMonths > 0) { resultText = "Aprox. $years ano(s) e $remainingMonths mes(es)"; } else if (years > 0) { resultText = "Aprox. $years ano(s)"; } else { resultText = "Aprox. $months mes(es)"; } } setState(() { _estimatedTimeResult = resultText; _isCalculating = false; }); }); } }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Metas'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.iceWhite,
      body: AnimatedBuilder( // Ouve o controller para reconstruir a tela toda
        animation: _goalsController,
        builder: (context, _) {
          return ListView( // Permite rolagem geral
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Seção da Calculadora ---
              _buildCalculatorSection(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- Seção da Lista de Metas ---
              Text("Minhas Metas Criadas", style: AppTextStyles.mediumText18),
              const SizedBox(height: 16),
              _buildGoalsListSection(), // Chama método auxiliar
            ],
          );
        }
      ),
      // +++ FAB COM onPressed CORRIGIDO +++
      floatingActionButton: FloatingActionButton.extended(
         heroTag: 'fab_new_goal',
        onPressed: () async { // MARCAR COMO ASYNC
          print("FAB: Navegando para ${NamedRoute.addEditGoal}..."); // Debug
          try {
            // Tenta navegar para a rota de adicionar/editar (sem argumentos = adicionar)
            final result = await Navigator.pushNamed(context, NamedRoute.addEditGoal);

            // Código executado DEPOIS que a tela AddEditGoalPage for fechada
            if (result == true) {
              // Se retornou true, a meta foi salva com sucesso no controller.
              // O controller já chamou fetchGoals e notificou, então a lista
              // na GoalsScreen deve atualizar automaticamente via AnimatedBuilder.
              print("FAB: Retornou 'true' da tela AddEditGoalPage. Lista deve atualizar.");
            } else {
               print("FAB: Retornou da tela AddEditGoalPage sem 'true' (ou retornou null/false).");
            }
          } catch (e) {
             // Captura erros que possam ocorrer durante a NAVEGAÇÃO ou construção da página
             print("FAB ERROR: Erro ao navegar/retornar de AddEditGoalPage: $e");
             if (mounted) { // Verifica se o widget ainda está na tela
               showCustomSnackBar(context: context, text: 'Erro ao abrir tela de nova meta.', type: SnackBarType.error);
             }
          }
        },
        label: const Text('Nova Meta'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
      ),
      // ++++++++++++++++++++++++++++++++++++
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildCalculatorSection() { /* ... (Código igual ao anterior) ... */ return Form( key: _calculatorFormKey, child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text( "Calculadora: Tempo para Atingir a Meta", style: AppTextStyles.mediumText16w600.copyWith(color: AppColors.darkGrey), textAlign: TextAlign.center, ), const SizedBox(height: 16), _buildInputField( controller: _targetAmountController, label: 'Valor da Meta (R\$)', icon: Icons.flag_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse(v?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Valor inválido' : null, ), const SizedBox(height: 12), _buildInputField( controller: _currentAmountController, label: 'Valor Guardado (R\$) (Opcional)', icon: Icons.savings_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse(v?.replaceAll(',', '.') ?? '-1') ?? -1) < 0 ? 'Valor inválido' : null, ), const SizedBox(height: 12), _buildInputField( controller: _monthlyContributionController, label: 'Quanto guardar por mês (R\$)', icon: Icons.payments_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse(v?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Valor inválido' : null, ), const SizedBox(height: 12), _buildInputField( controller: _annualRateController, label: 'Taxa Juros Anual (%) (Opcional)', hint: 'Ex: 10 (ou deixe 0)', icon: Icons.percent, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse(v?.replaceAll(',', '.') ?? '-1') ?? -1) < 0 ? 'Taxa inválida' : null, ), const SizedBox(height: 20), ElevatedButton( onPressed: _isCalculating ? null : _calculateTimeToGoal, style: ElevatedButton.styleFrom( backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), ), child: Text(_isCalculating ? 'Calculando...' : 'Calcular Tempo Estimado'), ), const SizedBox(height: 16), Visibility( visible: _estimatedTimeResult != null, child: Text( _estimatedTimeResult ?? '', textAlign: TextAlign.center, style: AppTextStyles.mediumText16w600.copyWith(color: AppColors.green), ), ) ], ), ); }
  Widget _buildInputField({ required TextEditingController controller, required String label, String? hint, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}) { /* ... (igual ao anterior) ... */ return TextFormField( controller: controller, decoration: InputDecoration( labelText: label, hintText: hint, prefixIcon: Icon(icon, color: AppColors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder( borderSide: const BorderSide(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8), ), contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12) ), keyboardType: keyboardType, inputFormatters: inputFormatters ?? [FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')),], validator: validator ?? (value) { if (value == null || value.isEmpty) { return 'Campo obrigatório'; } return null; }, ); }

  Widget _buildGoalsListSection() {
    final state = _goalsController.state;
    if (state is GoalsStateLoading) { return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CustomCircularProgressIndicator())); }
    if (state is GoalsStateError) { return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)))); }
    if (state is GoalsStateSuccess) {
      final goals = state.goals;
      if (goals.isEmpty) { return const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0), child: Text( 'Você ainda não cadastrou nenhuma meta.\nClique no botão "+" para começar!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15), ),),); }
      // Constrói a lista
      return ListView.separated(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          // Cria o GoalCard (onTap agora está dentro dele)
          return GoalCard( goal: goal );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      );
    }
    // Estado inicial ou inesperado
     return const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0), child: Text( 'Crie sua primeira meta clicando no botão "+".', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15), ),),);
  }
}