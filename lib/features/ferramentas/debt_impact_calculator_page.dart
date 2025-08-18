
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';

// --- NOVO: Enum para controlar o modo da calculadora ---
enum CalculatorMode { calculateTime, calculatePayment }

class DebtImpactCalculatorPage extends StatefulWidget {
  const DebtImpactCalculatorPage({super.key});

  @override
  State<DebtImpactCalculatorPage> createState() =>
      _DebtImpactCalculatorPageState();
}

class _DebtImpactCalculatorPageState extends State<DebtImpactCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _debtAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _minPaymentPercentController = TextEditingController();
  final _customPaymentController = TextEditingController();
  // --- NOVO: Controller para o tempo em meses ---
  final _periodMonthsController = TextEditingController();
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Variáveis de resultado
  int? _minPayoffMonths;
  double? _minTotalPaid;
  double? _minTotalInterest;
  int? _customPayoffMonths;
  double? _customTotalPaid;
  double? _customTotalInterest;
  // --- NOVO: Variável para o resultado da parcela calculada ---
  double? _calculatedMonthlyPayment;

  bool _showResults = false;
  bool _isLoading = false;
  bool _modoAulaAtivo = false;
  
  // --- NOVO: Variável de estado para o modo da calculadora ---
  CalculatorMode _calculatorMode = CalculatorMode.calculateTime;


  @override
  void dispose() {
    _debtAmountController.dispose();
    _interestRateController.dispose();
    _minPaymentPercentController.dispose();
    _customPaymentController.dispose();
    _periodMonthsController.dispose(); // --- NOVO ---
    super.dispose();
  }

  void _onCalculatorModeChanged(CalculatorMode newMode) {
    setState(() {
      _calculatorMode = newMode;
      _showResults = false; // Esconde resultados antigos ao trocar de modo
      // Limpa os campos que mudam de função
      _customPaymentController.clear();
      _periodMonthsController.clear();
    });
  }

  void _startCalculation() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _showResults = false;
      });

      // Simula um pequeno delay para o feedback de loading
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_calculatorMode == CalculatorMode.calculateTime) {
          _calculateDebtPayoffTime();
        } else {
          _calculateMonthlyPayment();
        }
      });
    }
  }

  // --- LÓGICA DE CÁLCULO SEPARADA ---
  void _calculateDebtPayoffTime() {
    // ... (lógica que você já tinha, para calcular o tempo) ...
    // (com pequenas melhorias para clareza)
    final double initialDebt = double.tryParse(_debtAmountController.text.replaceAll(',', '.')) ?? 0.0;
    final double annualInterestRatePercent = double.tryParse(_interestRateController.text.replaceAll(',', '.')) ?? 0.0;
    final double minPaymentPercent = double.tryParse(_minPaymentPercentController.text.replaceAll(',', '.')) ?? 0.0;
    final double customPaymentAmount = double.tryParse(_customPaymentController.text.replaceAll(',', '.')) ?? 0.0;

    final double monthlyInterestRate = (annualInterestRatePercent / 100) / 12;

    if (customPaymentAmount <= (initialDebt * monthlyInterestRate)) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O pagamento customizado não cobre nem os juros iniciais!', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange));
      return;
    }
    
    // ... O restante da lógica de cálculo do tempo que você já tinha ...
    // Cálculo Pagamento Mínimo
    double minCurrentBalance = initialDebt;
    int minMonths = 0;
    double minTotalPaidCalc = 0;
    double minTotalInterestCalc = 0;
    const int maxIterations = 600; // 50 anos

    while (minCurrentBalance > 0.01 && minMonths < maxIterations) {
      minMonths++;
      double interestThisMonth = minCurrentBalance * monthlyInterestRate;
      minTotalInterestCalc += interestThisMonth;
      double minPayment = minCurrentBalance * (minPaymentPercent / 100);
      double minimumRequired = interestThisMonth + 0.01;
      double absoluteMinimum = 15.0; 
      minPayment = [minPayment, minimumRequired, absoluteMinimum].reduce(max);
      minPayment = min(minPayment, minCurrentBalance + interestThisMonth);
      minTotalPaidCalc += minPayment;
      minCurrentBalance += interestThisMonth - minPayment;
    }

    // Cálculo Pagamento Customizado
    double customCurrentBalance = initialDebt;
    int customMonths = 0;
    double customTotalPaidCalc = 0;
    double customTotalInterestCalc = 0;

    while (customCurrentBalance > 0.01 && customMonths < maxIterations) {
      customMonths++;
      double interestThisMonth = customCurrentBalance * monthlyInterestRate;
      customTotalInterestCalc += interestThisMonth;
      double payment = min(customPaymentAmount, customCurrentBalance + interestThisMonth);
      customTotalPaidCalc += payment;
      customCurrentBalance += interestThisMonth - payment;
    }
    
    setState(() {
      _minPayoffMonths = (minMonths >= maxIterations) ? null : minMonths;
      _minTotalPaid = (minMonths >= maxIterations) ? null : minTotalPaidCalc;
      _minTotalInterest = (minMonths >= maxIterations) ? null : minTotalInterestCalc;

      _customPayoffMonths = (customMonths >= maxIterations) ? null : customMonths;
      _customTotalPaid = (customMonths >= maxIterations) ? null : customTotalPaidCalc;
      _customTotalInterest = (customMonths >= maxIterations) ? null : customTotalInterestCalc;
      
      _calculatedMonthlyPayment = null; // Garante que o resultado do outro modo seja limpo
      _showResults = true;
      _isLoading = false;
    });
  }

  // --- NOVO: Lógica para calcular a parcela mensal ---
  void _calculateMonthlyPayment() {
    final double initialDebt = double.tryParse(_debtAmountController.text.replaceAll(',', '.')) ?? 0.0;
    final double annualInterestRatePercent = double.tryParse(_interestRateController.text.replaceAll(',', '.')) ?? 0.0;
    final int periodMonths = int.tryParse(_periodMonthsController.text) ?? 0;

    if (periodMonths <= 0) {
      setState(() => _isLoading = false);
      return; // A validação do form já deve pegar isso
    }

    final double monthlyInterestRate = (annualInterestRatePercent / 100) / 12;

    // Fórmula do PMT (Pagamento Mensal) para uma anuidade
    double pmt;
    if (monthlyInterestRate > 0) {
      pmt = (initialDebt * monthlyInterestRate * pow(1 + monthlyInterestRate, periodMonths)) / (pow(1 + monthlyInterestRate, periodMonths) - 1);
    } else {
      // Se não há juros, o pagamento é simplesmente a dívida dividida pelo tempo
      pmt = initialDebt / periodMonths;
    }

    double totalPaid = pmt * periodMonths;
    double totalInterest = totalPaid - initialDebt;

    setState(() {
      _calculatedMonthlyPayment = pmt;
      _customTotalPaid = totalPaid; // Reutilizando variáveis de resultado
      _customTotalInterest = totalInterest; // Reutilizando variáveis de resultado
      _customPayoffMonths = periodMonths;

      _minPayoffMonths = null; // Limpa resultado do outro modo
      _minTotalPaid = null;
      _minTotalInterest = null;
      _showResults = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Labels dinâmicas baseadas no modo
    final bool isCalculateTimeMode = _calculatorMode == CalculatorMode.calculateTime;
    final String periodLabel = isCalculateTimeMode ? 'Período para pagar (Anos)' : 'Quitar em (Meses)';
    final String paymentLabel = isCalculateTimeMode ? 'Pagamento Mensal (R\$)' : 'Pagamento Mensal (Resultado)';
    final String buttonLabel = isCalculateTimeMode ? 'Calcular Impacto' : 'Calcular Parcela Mensal';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Impacto da Dívida'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.iceWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entenda o verdadeiro custo da sua dívida e planeje sua saída!',
                style: AppTextStyles.mediumText16w500
                    .copyWith(color: AppColors.darkGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // --- NOVO: Seletor de modo de cálculo ---
              SegmentedButton<CalculatorMode>(
                segments: const <ButtonSegment<CalculatorMode>>[
                  ButtonSegment<CalculatorMode>(value: CalculatorMode.calculateTime, label: Text('Calcular Tempo'), icon: Icon(Icons.hourglass_bottom)),
                  ButtonSegment<CalculatorMode>(value: CalculatorMode.calculatePayment, label: Text('Calcular Parcela'), icon: Icon(Icons.payments)),
                ],
                selected: {_calculatorMode},
                onSelectionChanged: (Set<CalculatorMode> newSelection) {
                  _onCalculatorModeChanged(newSelection.first);
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: AppColors.green,
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: AppColors.green,
                ),
              ),
              const SizedBox(height: 16),

              // --- NOVO: Switch para ativar o Modo Aula ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("💡 Modo Aula", style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(
                    value: _modoAulaAtivo,
                    activeColor: AppColors.green,
                    onChanged: (value) {
                      setState(() {
                        _modoAulaAtivo = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Campos do formulário
              _buildInputField(
                  controller: _debtAmountController,
                  label: 'Valor Total da Dívida (R\$)',
                  hint: 'Ex: 1500.00',
                  icon: Icons.attach_money,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0
                          ? 'Valor inválido'
                          : null),
              
              _buildEducationalTip("Este é o valor total que você deve hoje, por exemplo, a fatura completa do seu cartão."),

              _buildInputField(
                  controller: _interestRateController,
                  label: 'Taxa de Juros ANUAL (%)',
                  hint: 'Ex: 300 (para cartão de crédito)',
                  icon: Icons.percent,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0
                          ? 'Taxa inválida'
                          : null),
              
              _buildEducationalTip("Taxas altas são o que tornam as dívidas uma bola de neve perigosa! A do rotativo do cartão costuma ser uma das mais altas."),

              // --- Campo de Período/Tempo com label dinâmica ---
              // (Escondido se estiver calculando tempo e pagando o mínimo)
              if (isCalculateTimeMode)
                Column(
                  children: [
                    _buildInputField(
                        controller: _minPaymentPercentController,
                        label: 'Pagamento Mínimo (%)',
                        hint: 'Ex: 15 (veja na sua fatura)',
                        icon: Icons.payment_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) =>
                            (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0
                                ? '% inválido'
                                : null),
                     _buildEducationalTip("Pagar só o mínimo é uma armadilha! A maior parte do seu dinheiro vai para os juros e a dívida quase não diminui."),
                  ],
                ),
                
              
              if (!isCalculateTimeMode)
                 Column(
                   children: [
                     _buildInputField(
                        controller: _periodMonthsController,
                        label: periodLabel,
                        hint: 'Ex: 12',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) =>
                            (int.tryParse(value ?? '0') ?? 0) <= 0
                                ? 'Período inválido'
                                : null,
                      ),
                     _buildEducationalTip("Defina uma meta realista de tempo para se livrar da dívida. Isso te dará um plano claro."),
                   ],
                 ),


              _buildInputField(
                  controller: _customPaymentController,
                  label: paymentLabel,
                  hint: isCalculateTimeMode ? 'Quanto você pode pagar por mês?' : '',
                  readOnly: !isCalculateTimeMode, // --- MODIFICADO ---
                  icon: Icons.savings_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  // Validador só é necessário no modo de calcular tempo
                  validator: isCalculateTimeMode ? (value) =>
                      (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0
                          ? 'Valor inválido'
                          : null : null, 
                ),
              
              _buildEducationalTip(isCalculateTimeMode 
                  ? "Qualquer valor acima do mínimo já faz uma enorme diferença. Veja o impacto de pagar um pouco a mais."
                  : "Este é o valor que você precisará pagar todo mês para quitar sua dívida no tempo desejado."),


              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: _isLoading
                    ? Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.calculate),
                label: Text(_isLoading ? 'Calculando...' : buttonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: AppTextStyles.mediumText18
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _startCalculation,
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

  // --- NOVO: Helper para criar os cards de dicas ---
  Widget _buildEducationalTip(String text) {
    return Visibility(
      visible: _modoAulaAtivo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(top: 4, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade100)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
      bool readOnly = false, // --- NOVO ---
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0), // Espaçamento entre o campo e a dica acima
      child: TextFormField(
        controller: controller,
        readOnly: readOnly, // --- NOVO ---
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: readOnly, // --- NOVO ---
          fillColor: Colors.grey.shade200, // --- NOVO ---
          prefixIcon: Icon(icon, color: AppColors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.green, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters ??
            [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')),
            ],
        validator: validator,
      ),
    );
  }

  Widget _buildResultsSection() {
    // Lógica condicional para mostrar o resultado correto
    if (_calculatorMode == CalculatorMode.calculateTime) {
      if (_minPayoffMonths == null && _customPayoffMonths == null) {
        return const Card(
          color: Colors.amberAccent,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
                'Não foi possível calcular com os valores fornecidos. A dívida pode não ser quitada em 50 anos com estes pagamentos.',
                textAlign: TextAlign.center),
          ),
        );
      }
      return _modoAulaAtivo ? _buildEducationalResultsTime() : _buildSimpleResultsTime();
    } else { // Modo calculatePayment
      if (_calculatedMonthlyPayment == null) {
         return const Card(
          color: Colors.amberAccent,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
                'Não foi possível calcular. Verifique os valores.',
                textAlign: TextAlign.center),
          ),
        );
      }
      return _modoAulaAtivo ? _buildEducationalResultsPayment() : _buildSimpleResultsPayment();
    }
  }

  // --- RESULTADOS PARA MODO "CALCULAR TEMPO" ---
  Widget _buildSimpleResultsTime() {
    return Column(
      children: [
        Text("Resultados da Simulação",
            style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildResultCard(
                title: 'Pagando o MÍNIMO (${_minPaymentPercentController.text}%)',
                payoffMonths: _minPayoffMonths,
                totalPaid: _minTotalPaid,
                totalInterest: _minTotalInterest,
                isMinimum: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                title:
                    'Pagando ${_currencyFormatter.format(double.tryParse(_customPaymentController.text.replaceAll(',', '.')) ?? 0)}/mês',
                payoffMonths: _customPayoffMonths,
                totalPaid: _customTotalPaid,
                totalInterest: _customTotalInterest,
                isMinimum: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_minTotalInterest != null &&
            _customTotalInterest != null &&
            _minTotalInterest! > _customTotalInterest!)
          Card(
            color: AppColors.income.withAlpha(30),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Pagando um valor maior por mês, você economizaria aproximadamente ${_currencyFormatter.format(_minTotalInterest! - _customTotalInterest!)} só em juros e quitaria a dívida muito mais rápido!',
                style: AppTextStyles.smallText
                    .copyWith(color: AppColors.darkGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEducationalResultsTime() {
    String minPayoffText = _minPayoffMonths == null ? "mais de 50 anos" : "${_minPayoffMonths!} meses";
    String customPayoffText = _customPayoffMonths == null ? "mais de 50 anos" : "${_customPayoffMonths!} meses";
    double savedInterest = (_minTotalInterest ?? 0) - (_customTotalInterest ?? 0);

    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey, height: 1.5),
            children: <TextSpan>[
              const TextSpan(text: 'Pagando só o mínimo, sua dívida levaria '),
              TextSpan(text: minPayoffText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.outcome)),
              const TextSpan(text: ' para ser paga e você gastaria um total de '),
              TextSpan(text: _currencyFormatter.format(_minTotalInterest ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' só em juros.\n\nMas, pagando '),
              TextSpan(text: _currencyFormatter.format(double.tryParse(_customPaymentController.text.replaceAll(',', '.')) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' por mês, você quita em apenas '),
              TextSpan(text: customPayoffText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
              if (savedInterest > 0)
                ...[
                  const TextSpan(text: ' e '),
                  TextSpan(
                      text: 'economiza ${_currencyFormatter.format(savedInterest)}',
                      style: AppTextStyles.mediumText16w600.copyWith(color: AppColors.income, backgroundColor: AppColors.income.withOpacity(0.1))),
                  const TextSpan(text: ' só de juros!'),
                ],
              const TextSpan(text: ' Essa é a diferença que um pagamento maior faz no seu bolso. 💪'),
            ],
          ),
        ),
      ),
    );
  }
  
  // --- RESULTADOS PARA MODO "CALCULAR PARCELA" ---
  Widget _buildSimpleResultsPayment() {
    return Column(
      children: [
         _buildResultRow('Parcela Mensal Necessária:', _currencyFormatter.format(_calculatedMonthlyPayment ?? 0), isInterest: false, valueColor: AppColors.green),
         const Divider(height: 16, thickness: 0.5),
         _buildResultRow('Tempo para Quitar:', "${_customPayoffMonths ?? 0} meses", isInterest: false),
         _buildResultRow('Total Pago ao Final:', _currencyFormatter.format(_customTotalPaid ?? 0), isInterest: false),
         _buildResultRow('Total de Juros Pagos:', _currencyFormatter.format(_customTotalInterest ?? 0), isInterest: true),
      ],
    );
  }

  Widget _buildEducationalResultsPayment() {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey, height: 1.5),
            children: <TextSpan>[
              const TextSpan(text: 'Para quitar sua dívida de '),
              TextSpan(text: _currencyFormatter.format(double.tryParse(_debtAmountController.text.replaceAll(',', '.')) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' em '),
              TextSpan(text: '${_customPayoffMonths ?? 0} meses', style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ', você precisará pagar:\n'),
              TextSpan(
                text: _currencyFormatter.format(_calculatedMonthlyPayment ?? 0),
                style: AppTextStyles.bigText50.copyWith(color: AppColors.green, fontSize: 28),
              ),
              const TextSpan(text: '\npor mês. Ao final, o custo total dos juros será de '),
              TextSpan(
                text: _currencyFormatter.format(_customTotalInterest ?? 0),
                style: AppTextStyles.mediumText16w600.copyWith(color: AppColors.outcome, backgroundColor: AppColors.outcome.withOpacity(0.1)),
              ),
              const TextSpan(text: '. Ter um plano claro é o primeiro passo para a liberdade financeira!'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
      {required String title,
      required int? payoffMonths,
      required double? totalPaid,
      required double? totalInterest,
      required bool isMinimum}) {
    final Color titleColor = isMinimum ? AppColors.outcome : AppColors.green;
    final String timeText =
        payoffMonths == null ? '> 50 anos (!)' : '$payoffMonths meses';
    final String paidText =
        totalPaid == null ? 'N/A' : _currencyFormatter.format(totalPaid);
    final String interestText = totalInterest == null
        ? 'N/A'
        : _currencyFormatter.format(totalInterest);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: titleColor.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.mediumText16w600
                    .copyWith(color: titleColor)),
            const Divider(height: 16),
            _buildResultRow('Tempo:', timeText, valueColor: AppColors.darkGrey),
            _buildResultRow('Total Pago:', paidText, valueColor: AppColors.darkGrey),
            _buildResultRow('Total Juros:', interestText, isInterest: true),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isInterest = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTextStyles.smallText.copyWith(color: AppColors.darkGrey)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.mediumText16w500.copyWith(
                color: valueColor ?? (isInterest ? AppColors.outcome : AppColors.darkGrey),
                fontWeight: isInterest ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

