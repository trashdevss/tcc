// lib/features/tools/view/budget_calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';

// --- NOME DA CLASSE CORRIGIDO ---
class BudgetCalculatorPage extends StatefulWidget {
  const BudgetCalculatorPage({super.key});

  @override
  // --- NOME DO STATE CORRIGIDO ---
  State<BudgetCalculatorPage> createState() => _BudgetCalculatorPageState();
}

class _BudgetCalculatorPageState extends State<BudgetCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double? _essentialsAmount;
  double? _nonEssentialsAmount;
  double? _savingsAmount;
  bool _showResults = false;
  bool _isLoading = false;

  // --- NOVO: Variável de estado para o Modo Aula ---
  bool _modoAulaAtivo = false;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _calculateBudget() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _showResults = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        final double monthlyIncome =
            double.tryParse(_incomeController.text.replaceAll(',', '.')) ?? 0.0;
        if (monthlyIncome <= 0) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Informe um valor de renda válido.'),
              backgroundColor: Colors.red));
          return;
        }
        setState(() {
          _essentialsAmount = monthlyIncome * 0.50;
          _nonEssentialsAmount = monthlyIncome * 0.30;
          _savingsAmount = monthlyIncome * 0.20;
          _showResults = true;
          _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Orçamento 50/30/20'),
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
                'Divida sua renda mensal de forma inteligente com a regra 50/30/20.',
                style: AppTextStyles.mediumText16w500
                    .copyWith(color: AppColors.darkGrey),
                textAlign: TextAlign.center,
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

              _buildInputField(
                  controller: _incomeController,
                  label: 'Renda Líquida Mensal (R\$)',
                  hint: 'Ex: 2500.00',
                  icon: Icons.wallet_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      (double.tryParse(value?.replaceAll(',', '.') ?? '0') ?? 0) <= 0
                          ? 'Valor inválido'
                          : null),
              
              // --- NOVO: Dica educacional ---
              _buildEducationalTip("É o dinheiro que realmente cai na sua conta, já com os descontos (INSS, imposto de renda, etc.). É com base nele que você deve se planejar."),
              
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isLoading
                    ? Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.calculate_outlined),
                label: Text(_isLoading ? 'Calculando...' : 'Calcular Divisão'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: AppTextStyles.mediumText18
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _calculateBudget,
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

  // --- NOVO: Helper para criar os cards de dicas, evitando repetição e corrigindo layout ---
  Widget _buildEducationalTip(String text) {
    return Visibility(
      visible: _modoAulaAtivo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(top: 4, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade100)
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue.shade800),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.black54))),
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
      List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
    );
  }

  Widget _buildResultsSection() {
    if (_essentialsAmount == null ||
        _nonEssentialsAmount == null ||
        _savingsAmount == null) {
      return const Center(child: Text("Erro ao calcular resultados."));
    }
    
    // --- MODIFICADO: Define as descrições com base no Modo Aula ---
    final String essentialsDescription = _modoAulaAtivo
        ? "Use esta parte para o que é essencial para viver: moradia, contas de luz/água, comida de mercado e transporte para o trabalho. É a base da sua pirâmide financeira."
        : "Moradia, alimentação, transporte, contas básicas, saúde.";
    
    final String nonEssentialsDescription = _modoAulaAtivo
        ? "Dinheiro também é para ser aproveitado! Use para lazer, compras que te deixam feliz, assinaturas e restaurantes. É o seu 'respiro' financeiro."
        : "Lazer, compras, assinaturas, restaurantes, viagens.";
        
    final String savingsDescription = _modoAulaAtivo
        ? "Esta é a fatia mais importante para seus sonhos! Use para quitar dívidas (além do mínimo), criar sua reserva de emergência e investir nas suas metas de longo prazo."
        : "Guardar para objetivos, investir, pagar dívidas.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Sugestão de Orçamento",
            style:
                AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),

        // --- NOVO: Texto introdutório para o Modo Aula ---
        Visibility(
          visible: _modoAulaAtivo,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              "A regra 50/30/20 é um guia para te ajudar a encontrar um equilíbrio. Veja como sua renda seria dividida:",
              style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        _buildBudgetCategoryCard(
          title: "Gastos Essenciais (50%)",
          amount: _essentialsAmount!,
          description: essentialsDescription,
          color: Colors.orange.shade700,
        ),
        const SizedBox(height: 12),
        _buildBudgetCategoryCard(
          title: "Gastos Pessoais (30%)", // Nome ajustado de 'Não Essenciais'
          amount: _nonEssentialsAmount!,
          description: nonEssentialsDescription,
          color: Colors.blue.shade700,
        ),
        const SizedBox(height: 12),
        _buildBudgetCategoryCard(
          title: "Futuro e Metas (20%)", // Nome ajustado de 'Poupança'
          amount: _savingsAmount!,
          description: savingsDescription,
          color: AppColors.green,
        ),
      ],
    );
  }

  Widget _buildBudgetCategoryCard({
    required String title,
    required double amount,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.7), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.mediumText16w600.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormatter.format(amount),
              style: AppTextStyles.mediumText18
                  .copyWith(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTextStyles.smallText.copyWith(color: AppColors.grey, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}