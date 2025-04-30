// lib/features/tools/view/debt_impact_calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para InputFormatters
import 'package:intl/intl.dart';      // Para formatar moeda
import 'dart:math';                  // Para usar max() e min()

import 'package:tcc_3/common/constants/app_colors.dart';    // Suas cores
import 'package:tcc_3/common/constants/app_text_styles.dart'; // Seus estilos
// Use um AppBar padrão ou seu AppHeader se ele implementar PreferredSizeWidget
// import 'package:tcc_3/common/widgets/app_header.dart';

class DebtImpactCalculatorPage extends StatefulWidget {
  const DebtImpactCalculatorPage({super.key});

  @override
  State<DebtImpactCalculatorPage> createState() => _DebtImpactCalculatorPageState();
}

class _DebtImpactCalculatorPageState extends State<DebtImpactCalculatorPage> {
  final _formKey = GlobalKey<FormState>();

  final _debtAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _minPaymentPercentController = TextEditingController();
  final _customPaymentController = TextEditingController();

  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  int? _minPayoffMonths;
  double? _minTotalPaid;
  double? _minTotalInterest;
  int? _customPayoffMonths;
  double? _customTotalPaid;
  double? _customTotalInterest;

  bool _showResults = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _debtAmountController.dispose();
    _interestRateController.dispose();
    _minPaymentPercentController.dispose();
    _customPaymentController.dispose();
    super.dispose();
  }

  void _calculateDebtImpact() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _showResults = false; });

      Future.delayed(const Duration(milliseconds: 300), () {
        final double initialDebt = double.tryParse(_debtAmountController.text.replaceAll(',', '.')) ?? 0.0;
        final double annualInterestRatePercent = double.tryParse(_interestRateController.text.replaceAll(',', '.')) ?? 0.0;
        final double minPaymentPercent = double.tryParse(_minPaymentPercentController.text.replaceAll(',', '.')) ?? 0.0;
        final double customPaymentAmount = double.tryParse(_customPaymentController.text.replaceAll(',', '.')) ?? 0.0;

        if (initialDebt <= 0 || annualInterestRatePercent <= 0 || minPaymentPercent <= 0) {
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Valores inválidos. Verifique os campos obrigatórios.'), backgroundColor: Colors.red) ); return;
        }
        if (customPaymentAmount <= 0) {
           setState(() { _isLoading = false; });
           ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Informe um valor de pagamento customizado maior que zero.'), backgroundColor: Colors.red) ); return;
        }

        final double monthlyInterestRate = (annualInterestRatePercent / 100) / 12;

        // Cálculo com Pagamento MÍNIMO
        double minCurrentBalance = initialDebt; int minMonths = 0; double minTotalPaidCalc = 0; double minTotalInterestCalc = 0; const int maxIterations = 600;
        while (minCurrentBalance > 0.01 && minMonths < maxIterations) {
          minMonths++; double interestThisMonth = minCurrentBalance * monthlyInterestRate; minTotalInterestCalc += interestThisMonth;
          double minPayment = minCurrentBalance * (minPaymentPercent / 100); double minimumRequired = interestThisMonth + 0.01; double absoluteMinimum = 15.0;
          minPayment = [minPayment, minimumRequired, absoluteMinimum].reduce(max); minPayment = min(minPayment, minCurrentBalance + interestThisMonth);
          minTotalPaidCalc += minPayment; minCurrentBalance += interestThisMonth - minPayment;
        }

        // Cálculo com Pagamento CUSTOMIZADO
        double customCurrentBalance = initialDebt; int customMonths = 0; double customTotalPaidCalc = 0; double customTotalInterestCalc = 0;
        if (customPaymentAmount <= (initialDebt * monthlyInterestRate)) {
            setState(() { _isLoading = false; });
            ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('O pagamento customizado não cobre nem os juros iniciais! A dívida nunca será paga.'), backgroundColor: Colors.orange) ); return;
        }
        while (customCurrentBalance > 0.01 && customMonths < maxIterations) {
           customMonths++; double interestThisMonth = customCurrentBalance * monthlyInterestRate; customTotalInterestCalc += interestThisMonth;
           double payment = min(customPaymentAmount, customCurrentBalance + interestThisMonth);
           customTotalPaidCalc += payment; customCurrentBalance += interestThisMonth - payment;
        }

        setState(() {
          _minPayoffMonths = (minMonths >= maxIterations) ? null : minMonths; _minTotalPaid = (minMonths >= maxIterations) ? null : minTotalPaidCalc; _minTotalInterest = (minMonths >= maxIterations) ? null : minTotalInterestCalc;
          _customPayoffMonths = (customMonths >= maxIterations) ? null : customMonths; _customTotalPaid = (customMonths >= maxIterations) ? null : customTotalPaidCalc; _customTotalInterest = (customMonths >= maxIterations) ? null : customTotalInterestCalc;
          _showResults = true; _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Impacto da Dívida'),
        backgroundColor: AppColors.green, // Cor exemplo
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.iceWhite, // Fundo da página
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text( 'Simule o pagamento da sua dívida (Ex: Cartão de Crédito)', style: AppTextStyles.mediumText14.copyWith(color: AppColors.darkGrey), textAlign: TextAlign.center, ),
              const SizedBox(height: 24),
              _buildInputField( controller: _debtAmountController, label: 'Valor Total da Dívida (R\$)', hint: 'Ex: 1500.00', icon: Icons.attach_money, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Valor inválido' : null, ),
              const SizedBox(height: 16),
              _buildInputField( controller: _interestRateController, label: 'Taxa de Juros ANUAL (%)', hint: 'Ex: 300', icon: Icons.percent, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Taxa inválida' : null, ),
              const SizedBox(height: 16),
              _buildInputField( controller: _minPaymentPercentController, label: 'Pagamento Mínimo (%)', hint: 'Ex: 15', icon: Icons.payment, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? '% inválido' : null, ),
              const SizedBox(height: 16),
              _buildInputField( controller: _customPaymentController, label: 'Pagamento Customizado (R\$)', hint: 'Quanto você pode pagar por mês?', icon: Icons.savings, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) => (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0 ? 'Valor inválido' : null, ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: _isLoading ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : const Icon(Icons.calculate),
                label: Text(_isLoading ? 'Calculando...' : 'Calcular Impacto'),
                style: ElevatedButton.styleFrom( backgroundColor: AppColors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), textStyle: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold), ),
                onPressed: _isLoading ? null : _calculateDebtImpact,
              ),
              const SizedBox(height: 32),
              Visibility(
                visible: _showResults,
                child: _buildResultsSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({ required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, }) {
    return TextFormField( controller: controller, decoration: InputDecoration( labelText: label, hintText: hint, prefixIcon: Icon(icon, color: AppColors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder( borderSide: const BorderSide(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8), ), ), keyboardType: keyboardType, inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')), ], validator: validator ?? (value) { if (value == null || value.isEmpty) { return 'Campo obrigatório'; } return null; }, );
  }

  Widget _buildResultsSection() {
    if (_minPayoffMonths == null && _customPayoffMonths == null) { return const Card( color: Colors.amberAccent, child: Padding( padding: EdgeInsets.all(16.0), child: Text( 'Não foi possível calcular com os valores fornecidos (talvez o pagamento mínimo não cubra os juros ou o limite de tempo foi atingido). Verifique os valores e tente novamente.', textAlign: TextAlign.center), ), ); }
    return Column( children: [ Text("Resultados da Simulação", style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ Expanded( child: _buildResultCard( title: 'Pagando o MÍNIMO (${_minPaymentPercentController.text}%)', payoffMonths: _minPayoffMonths, totalPaid: _minTotalPaid, totalInterest: _minTotalInterest, isMinimum: true, ), ), const SizedBox(width: 16), Expanded( child: _buildResultCard( title: 'Pagando ${_currencyFormatter.format(double.tryParse(_customPaymentController.text.replaceAll(',', '.')) ?? 0)}/mês', payoffMonths: _customPayoffMonths, totalPaid: _customTotalPaid, totalInterest: _customTotalInterest, isMinimum: false, ), ), ], ), const SizedBox(height: 16), if (_minTotalInterest != null && _customTotalInterest != null && _minTotalInterest! > _customTotalInterest!) Card( color: AppColors.income.withAlpha(30), child: Padding( padding: const EdgeInsets.all(12.0), child: Text( 'Pagando um valor maior por mês, você economizaria aproximadamente ${_currencyFormatter.format(_minTotalInterest! - _customTotalInterest!)} só em juros e quitaria a dívida muito mais rápido!', style: AppTextStyles.smallText.copyWith(color: AppColors.darkGrey, fontSize: 14), textAlign: TextAlign.center, ), ), ), const SizedBox(height: 16), Text( '*Atenção: Esta é uma simulação simplificada. As regras de pagamento mínimo e taxas do seu cartão podem variar. Consulte seu banco para informações exatas.', style: AppTextStyles.smallText.copyWith(color: AppColors.grey, fontSize: 11), textAlign: TextAlign.center, ), ], );
  }

  Widget _buildResultCard({ required String title, required int? payoffMonths, required double? totalPaid, required double? totalInterest, required bool isMinimum, }) { final Color titleColor = isMinimum ? AppColors.outcome : AppColors.income; final String timeText = payoffMonths == null ? '> 50 anos (!)' : '$payoffMonths meses'; final String paidText = totalPaid == null ? 'N/A' : _currencyFormatter.format(totalPaid); final String interestText = totalInterest == null ? 'N/A' : _currencyFormatter.format(totalInterest); return Card( elevation: 1, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), side: BorderSide(color: titleColor.withOpacity(0.5)) ), child: Padding( padding: const EdgeInsets.all(12.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: AppTextStyles.mediumText16w600.copyWith(color: titleColor)), const Divider(height: 16), _buildResultRow('Tempo:', timeText), _buildResultRow('Total Pago:', paidText), _buildResultRow('Total Juros:', interestText, isInterest: true), ], ), ), ); }

  // *** CORREÇÃO APLICADA AQUI: Usando Flexible no valor ***
  Widget _buildResultRow(String label, String value, {bool isInterest = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Removido para Flexible funcionar melhor
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha pelo topo se quebrar linha
        children: [
          Text(label, style: AppTextStyles.smallText.copyWith(color: AppColors.darkGrey)),
          const SizedBox(width: 8), // Espaço entre label e valor
          Flexible( // Permite que o valor quebre linha
            child: Text(
              value,
              style: AppTextStyles.mediumText16w500.copyWith(
                color: isInterest ? AppColors.outcome : AppColors.darkGrey,
                fontWeight: isInterest ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.end, // Alinha valor à direita
              softWrap: true, // Garante a quebra de linha
            ),
          ),
        ],
      ),
    );
  }
  // **********************************************************

}