// lib/features/tools/view/budget_calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';

class BudgetCalculatorPage extends StatefulWidget {
  const BudgetCalculatorPage({super.key});

  @override
  State<BudgetCalculatorPage> createState() => _BudgetCalculatorPageState();
}

class _BudgetCalculatorPageState extends State<BudgetCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double? _essentialsAmount;
  double? _nonEssentialsAmount;
  double? _savingsAmount;
  bool _showResults = false;
  bool _isLoading = false;

  @override
  void dispose() { _incomeController.dispose(); super.dispose(); }

  void _calculateBudget() { FocusScope.of(context).unfocus(); if (_formKey.currentState!.validate()) { setState(() { _isLoading = true; _showResults = false; }); Future.delayed(const Duration(milliseconds: 100), () { final double monthlyIncome = double.tryParse(_incomeController.text.replaceAll(',', '.')) ?? 0.0; if (monthlyIncome <= 0) { setState(() { _isLoading = false; }); ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Informe um valor de renda válido.'), backgroundColor: Colors.red) ); return; } setState(() { _essentialsAmount = monthlyIncome * 0.50; _nonEssentialsAmount = monthlyIncome * 0.30; _savingsAmount = monthlyIncome * 0.20; _showResults = true; _isLoading = false; }); }); } }

  @override
  Widget build(BuildContext context) { return Scaffold( appBar: AppBar( title: const Text('Calculadora Orçamento 50/30/20'), backgroundColor: AppColors.green, foregroundColor: AppColors.white, ), backgroundColor: AppColors.iceWhite, body: SingleChildScrollView( padding: const EdgeInsets.all(16.0), child: Form( key: _formKey, child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text( 'Divida sua renda mensal de forma inteligente com a regra 50/30/20.', style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey), textAlign: TextAlign.center, ), const SizedBox(height: 24), _buildInputField( controller: _incomeController, label: 'Renda Líquida Mensal (R\$)', hint: 'Ex: 2500.00', icon: Icons.wallet_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Valor inválido' : null, ), const SizedBox(height: 32), ElevatedButton.icon( icon: _isLoading ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : const Icon(Icons.calculate_outlined), label: Text(_isLoading ? 'Calculando...' : 'Calcular Divisão'), style: ElevatedButton.styleFrom( backgroundColor: AppColors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), textStyle: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold), ), onPressed: _isLoading ? null : _calculateBudget, ), const SizedBox(height: 32), Visibility( visible: _showResults, child: _buildResultsSection(), ), ], ), ), ), ); }
  Widget _buildInputField({ required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}) { return TextFormField( controller: controller, decoration: InputDecoration( labelText: label, hintText: hint, prefixIcon: Icon(icon, color: AppColors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder( borderSide: const BorderSide(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8), ), ), keyboardType: keyboardType, inputFormatters: inputFormatters ?? [FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')),], validator: validator ?? (value) { if (value == null || value.isEmpty) { return 'Campo obrigatório'; } return null; }, ); }
  Widget _buildResultsSection() { if (_essentialsAmount == null || _nonEssentialsAmount == null || _savingsAmount == null) { return const Center(child: Text("Erro ao calcular resultados.")); } return Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text("Sugestão de Orçamento", style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center,), const SizedBox(height: 16), _buildBudgetCategoryCard( title: "Gastos Essenciais (50%)", amount: _essentialsAmount!, description: "Moradia, alimentação, transporte, contas básicas, saúde.", color: Colors.orange.shade700, ), const SizedBox(height: 12), _buildBudgetCategoryCard( title: "Gastos Não Essenciais (30%)", amount: _nonEssentialsAmount!, description: "Lazer, compras, assinaturas, restaurantes, viagens.", color: Colors.blue.shade700, ), const SizedBox(height: 12), _buildBudgetCategoryCard( title: "Poupança e Metas (20%)", amount: _savingsAmount!, description: "Guardar para objetivos, investir, pagar dívidas.", color: AppColors.green, ), ], ); }
  Widget _buildBudgetCategoryCard({ required String title, required double amount, required String description, required Color color, }) { return Card( elevation: 1, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.7), width: 1) ), child: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( title, style: AppTextStyles.mediumText16w600.copyWith(color: color), ), const SizedBox(height: 8), Text( _currencyFormatter.format(amount), style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkGrey), ), const SizedBox(height: 8), Text( description, style: AppTextStyles.smallText.copyWith(color: AppColors.grey, fontSize: 13), ), ], ), ), ); }
}