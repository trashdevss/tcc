// lib/features/goals/widgets/goal_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar moeda
import 'package:tcc_3/common/models/goal.dart';
import 'package:tcc_3/features/goals/views/add_edit_goal_screen.dart';

// Ajuste os caminhos conforme sua estrutura
import '../../../services/goal_service.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final GoalService goalService;
  final NumberFormat currencyFormatter;

  const GoalCard({
    super.key,
    required this.goal,
    required this.goalService,
    required this.currencyFormatter,
  });

  // Função interna para mostrar o diálogo de adicionar progresso
  void _showAddProgressDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Adicionar Progresso a "${goal.name}"', style: TextStyle(fontSize: 18)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor a adicionar',
                hintText: 'Ex: 20,50',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Insira um valor.';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Valor inválido.';
                }
                // Opcional: Validação para não deixar adicionar mais que o necessário
                // double remaining = goal.targetAmount - goal.currentAmount;
                // if (amount > remaining) {
                //   return 'Valor maior que o restante (R\$ ${remaining.toStringAsFixed(2)})';
                // }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Adicionar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text.replaceAll(',', '.'));
                  Navigator.of(dialogContext).pop(); // Fecha o diálogo ANTES de chamar o serviço
                  try {
                    await goalService.addProgress(goal.id, amount);
                    // Mostra feedback na tela principal (SnackBar)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('R\$ ${amount.toStringAsFixed(2)} adicionados a "${goal.name}"!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Erro ao adicionar progresso: $e'), backgroundColor: Colors.red),
                     );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Função interna para confirmar e deletar a meta
  void _showDeleteConfirmationDialog(BuildContext context) {
     showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir a meta "${goal.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () async {
                  Navigator.of(dialogContext).pop(); // Fecha o diálogo ANTES
                 try {
                    await goalService.deleteGoal(goal.id);
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Meta "${goal.name}" excluída.'), backgroundColor: Colors.orange),
                    );
                 } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Erro ao excluir meta: $e'), backgroundColor: Colors.red),
                     );
                 }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define a cor da barra de progresso e do texto de status dinamicamente
    Color progressColor = Theme.of(context).colorScheme.primary; // Cor primária do tema
    String statusText = '${goal.progressPercentage}% Completo';
    if (goal.isCompleted) {
      progressColor = Colors.green.shade600; // Verde quando completa
      statusText = 'Meta Atingida! 🎉';
    } else if (goal.progressPercentage > 75) {
       progressColor = Colors.orange.shade600; // Laranja quando perto
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1: Nome da meta e Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // Alinha ícones com topo do texto
              children: [
                Expanded( // Permite que o nome cresça mas não empurre os botões
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                    // softWrap: true, // Permite quebrar linha se necessário
                  ),
                ),
                // Botões ficam à direita
                Row(
                  mainAxisSize: MainAxisSize.min, // Ocupa só o espaço dos ícones
                  children: [
                    // Botão Editar
                    IconButton(
                      icon: Icon(Icons.edit_note, size: 22, color: Colors.blueGrey),
                      tooltip: 'Editar Meta',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero, // Remove padding extra
                      constraints: BoxConstraints(), // Remove constraints extras
                      onPressed: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => AddEditGoalScreen(
                               goalService: goalService,
                               goalToEdit: goal, // Passa a meta para edição
                            ),
                          ),
                        );
                      },
                    ),
                     SizedBox(width: 4), // Pequeno espaço
                    // Botão Excluir
                    IconButton(
                      icon: Icon(Icons.delete_sweep_outlined, size: 22, color: Colors.red.shade400),
                      tooltip: 'Excluir Meta',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () => _showDeleteConfirmationDialog(context),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10.0),

            // Linha 2: Valores (Atual / Meta)
            Text(
              '${currencyFormatter.format(goal.currentAmount)} / ${currencyFormatter.format(goal.targetAmount)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 8.0),

            // Linha 3: Barra de Progresso
            LinearProgressIndicator(
              value: goal.progressFraction,
              backgroundColor: progressColor.withOpacity(0.2), // Fundo com opacidade da cor
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 10, // Barra mais fina
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 10.0),

            // Linha 4: Status e Botão Adicionar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Texto de Status (Porcentagem ou Completo)
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13
                      ),
                ),
                // Botão "Adicionar Progresso" (só aparece se não concluída)
                if (!goal.isCompleted)
                  TextButton.icon(
                    icon: Icon(Icons.add_circle, size: 20),
                    label: const Text('Contribuir'),
                    style: TextButton.styleFrom(
                       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                       textStyle: TextStyle(fontSize: 13)
                    ),
                    onPressed: () => _showAddProgressDialog(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}