// lib/features/metas/widgets/goal_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/features/metas/goal_model.dart';
import 'package:tcc_3/common/constants/routes.dart'; // <<< IMPORTAR NamedRoute

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  // Removido onTap daqui, a ação será definida diretamente no ListTile

  const GoalCard({
    super.key,
    required this.goal,
    // this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final progress = goal.progressPercentage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile( // Usando ListTile diretamente para facilitar o onTap
        // +++ AÇÃO onTap ADICIONADA +++
        onTap: () {
          // Navega para a tela de edição, passando a meta atual como argumento
          Navigator.pushNamed(context, NamedRoute.addEditGoal, arguments: goal);
        },
        // +++++++++++++++++++++++++++++
        contentPadding: const EdgeInsets.all(16.0), // Padding interno do ListTile
        title: Padding( // Adiciona padding abaixo do título apenas
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text( goal.name, style: AppTextStyles.mediumText16w600.copyWith(color: AppColors.darkGrey), maxLines: 1, overflow: TextOverflow.ellipsis, ), ),
        subtitle: Column( // Usa Column para barra e valores/percentual
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               LinearProgressIndicator( value: progress, backgroundColor: AppColors.lightGrey.withOpacity(0.3), valueColor: AlwaysStoppedAnimation<Color>( progress < 0.3 ? AppColors.outcome : (progress < 0.7 ? Colors.orange.shade600 : AppColors.income) ), minHeight: 8, borderRadius: BorderRadius.circular(4), ),
               const SizedBox(height: 8),
               Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                   Text.rich( TextSpan( children: [ TextSpan( text: currencyFormatter.format(goal.currentAmount), style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey), ), TextSpan( text: ' / ${currencyFormatter.format(goal.targetAmount)}', style: AppTextStyles.smallText13.copyWith(color: AppColors.grey), ), ] ), ),
                   Text( '${(progress * 100).toStringAsFixed(0)}%', style: AppTextStyles.mediumText16w600.copyWith(color: AppColors.green), ), ], ),
             ],
           ),
           // Ícone indicando que é clicável (opcional)
           // trailing: const Icon(Icons.edit_outlined, color: AppColors.lightGrey, size: 20),
      ),
    );
  }
}