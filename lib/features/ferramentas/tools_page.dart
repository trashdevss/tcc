// lib/features/tools/view/tools_page.dart

import 'package:flutter/material.dart';
// Garanta que seus imports de constantes e widgets estejam corretos
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/common/constants/routes.dart'; // Verifique seu caminho para NamedRoute

// Import das páginas das calculadoras

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferramentas Financeiras'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.iceWhite,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Card Impacto da Dívida
          _buildToolCard(
            context: context,
            icon: Icons.credit_card_off_outlined,
            title: 'Impacto da Dívida',
            subtitle: 'Veja o custo real de pagar o mínimo do cartão.',
            routeName: NamedRoute.debtCalculator,
            iconColor: AppColors.outcome,
            disabled: false, // Habilitado
          ),
          const SizedBox(height: 16),

          // Card Juros Compostos
          _buildToolCard(
            context: context,
            icon: Icons.savings_outlined,
            title: 'Juros Compostos',
            subtitle: 'Simule o crescimento da sua poupança ou investimento.',
            routeName: NamedRoute.compoundInterestCalculator,
            disabled: false, // Habilitado
            iconColor: AppColors.income,
          ),
          const SizedBox(height: 16),

          // Card Orçamento 50/30/20
           _buildToolCard(
            context: context,
            icon: Icons.pie_chart_outline,
            title: 'Orçamento 50/30/20',
            subtitle: 'Sugestão para dividir sua renda mensal.',
            routeName: NamedRoute.budgetCalculator,
            disabled: false, // Habilitado
            iconColor: Colors.blue.shade600,
          ),
          ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, NamedRoute.notificationDemo);
  },
  child: Text('Teste Captura Notificação'),
)
        ],
      ),
    );
  }

  // Widget auxiliar para criar os cards de cada ferramenta
  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String? routeName,
    Color iconColor = AppColors.darkGrey,
    bool disabled = false,
  }) {
    final double opacity = disabled ? 0.5 : 1.0;
    final Color textColor = disabled ? AppColors.grey : AppColors.darkGrey;
    final Color subtitleColor = disabled ? AppColors.lightGrey : AppColors.grey;
    final Color effectiveIconColor = disabled ? AppColors.grey : iconColor;

    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: disabled ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, size: 40, color: effectiveIconColor),
          title: Text(title, style: AppTextStyles.mediumText16w600.copyWith(color: textColor)),
          subtitle: Text(subtitle, style: AppTextStyles.smallText.copyWith(color: subtitleColor)),
          trailing: disabled ? null : const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.grey),
          enabled: !disabled,
          onTap: disabled || routeName == null
              ? null
              : () {
                  Navigator.pushNamed(context, routeName);
                },
                
        ),
      ),
    );
  }
}
