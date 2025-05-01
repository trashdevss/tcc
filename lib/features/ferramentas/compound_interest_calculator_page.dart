// lib/features/tools/view/compound_interest_calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// Removido import dart:math se não usar pow()
// import 'dart:math';

import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';

class CompoundInterestCalculatorPage extends StatefulWidget {
  const CompoundInterestCalculatorPage({super.key});

  @override
  State<CompoundInterestCalculatorPage> createState() => _CompoundInterestCalculatorPageState();
}

class _CompoundInterestCalculatorPageState extends State<CompoundInterestCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _initialAmountController = TextEditingController(text: '0');
  final _monthlyContributionController = TextEditingController();
  final _periodYearsController = TextEditingController();
  final _annualRateController = TextEditingController();
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double? _totalAmount;
  double? _totalInvested;
  double? _totalInterest;
  bool _showResults = false;
  bool _isLoading = false;

  @override
  void dispose() { _initialAmountController.dispose(); _monthlyContributionController.dispose(); _periodYearsController.dispose(); _annualRateController.dispose(); super.dispose(); }

  void _calculateCompoundInterest() { FocusScope.of(context).unfocus(); if (_formKey.currentState!.validate()) { setState(() { _isLoading = true; _showResults = false; }); Future.delayed(const Duration(milliseconds: 200), () { final double initialAmount = double.tryParse(_initialAmountController.text.replaceAll(',', '.')) ?? 0.0; final double monthlyContribution = double.tryParse(_monthlyContributionController.text.replaceAll(',', '.')) ?? 0.0; final int periodYears = int.tryParse(_periodYearsController.text) ?? 0; final double annualRatePercent = double.tryParse(_annualRateController.text.replaceAll(',', '.')) ?? 0.0; if (periodYears <= 0 || annualRatePercent <= 0 || monthlyContribution <= 0) { setState(() { _isLoading = false; }); ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Valores inválidos. Verifique o Aporte Mensal, Anos e Taxa.'), backgroundColor: Colors.red) ); return; } final int numberOfMonths = periodYears * 12; final double monthlyRate = (annualRatePercent / 100) / 12; double currentBalance = initialAmount; double totalContributions = initialAmount; for (int i = 0; i < numberOfMonths; i++) { currentBalance += monthlyContribution; totalContributions += monthlyContribution; double interestThisMonth = currentBalance * monthlyRate; currentBalance += interestThisMonth; } double calculatedTotalInterest = currentBalance - totalContributions; setState(() { _totalAmount = currentBalance; _totalInvested = totalContributions; _totalInterest = calculatedTotalInterest; _showResults = true; _isLoading = false; }); }); } }

  @override
  Widget build(BuildContext context) { return Scaffold( appBar: AppBar( title: const Text('Calculadora Juros Compostos'), backgroundColor: AppColors.green, foregroundColor: AppColors.white, ), backgroundColor: AppColors.iceWhite, body: SingleChildScrollView( padding: const EdgeInsets.all(16.0), child: Form( key: _formKey, child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text( 'Veja a mágica dos juros compostos acontecer!', style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey), textAlign: TextAlign.center, ), const SizedBox(height: 24), _buildInputField( controller: _initialAmountController, label: 'Valor Inicial (R\$) (Opcional)', hint: 'Ex: 1000.00 (ou deixe 0)', icon: Icons.account_balance_wallet_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) { if (value == null || value.isEmpty) return null; return (double.tryParse(value.replaceAll(',', '.')) == null) ? 'Valor inválido' : null; } ), const SizedBox(height: 16), _buildInputField( controller: _monthlyContributionController, label: 'Aporte Mensal (R\$)', hint: 'Ex: 150.00', icon: Icons.savings_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Valor inválido' : null, ), const SizedBox(height: 16), _buildInputField( controller: _periodYearsController, label: 'Período (Anos)', hint: 'Ex: 5', icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (value) => (int.tryParse(value ?? '0') ?? 0) <= 0 ? 'Período inválido' : null, ), const SizedBox(height: 16), _buildInputField( controller: _annualRateController, label: 'Taxa de Juros ANUAL (%)', hint: 'Ex: 10', icon: Icons.percent, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Taxa inválida' : null, ), const SizedBox(height: 32), ElevatedButton.icon( icon: _isLoading ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : const Icon(Icons.calculate_outlined), label: Text(_isLoading ? 'Calculando...' : 'Calcular Juros Compostos'), style: ElevatedButton.styleFrom( backgroundColor: AppColors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), textStyle: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold), ), onPressed: _isLoading ? null : _calculateCompoundInterest, ), const SizedBox(height: 32), Visibility( visible: _showResults, child: _buildResultsSection(), ), ], ), ), ), ); }
  Widget _buildInputField({ required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}) { return TextFormField( controller: controller, decoration: InputDecoration( labelText: label, hintText: hint, prefixIcon: Icon(icon, color: AppColors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder( borderSide: const BorderSide(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8), ), ), keyboardType: keyboardType, inputFormatters: inputFormatters ?? [FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')),], validator: validator ?? (value) { if (value == null || value.isEmpty) { return 'Campo obrigatório'; } return null; }, ); }
  Widget _buildResultsSection() { if (_totalAmount == null || _totalInvested == null || _totalInterest == null) { return const Center(child: Text("Erro ao calcular resultados.")); } return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text("Resultado da Simulação", style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center,), const SizedBox(height: 16), _buildResultRow("Total Acumulado:", _totalAmount!, AppColors.green), const Divider(height: 16, thickness: 0.5), _buildResultRow("Total Aportado:", _totalInvested!, AppColors.darkGrey), _buildResultRow("Total em Juros:", _totalInterest!, AppColors.income), const SizedBox(height: 16), Text( '*Simulação de juros compostos com aportes mensais. A rentabilidade real pode variar.', style: AppTextStyles.smallText.copyWith(color: AppColors.grey, fontSize: 11), textAlign: TextAlign.center, ), ], ), ), ); }
  Widget _buildResultRow(String label, double value, Color valueColor) { return Padding( padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(label, style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey)), Text( _currencyFormatter.format(value), style: AppTextStyles.mediumText16w600.copyWith(color: valueColor), ), ], ), ); }
}