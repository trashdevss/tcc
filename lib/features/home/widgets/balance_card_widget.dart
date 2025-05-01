// lib/features/home/widgets/balance_card_widget.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importado para TransactionValueWidget
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/features/balance_state.dart';

import '../../../common/constants/constants.dart'; // Para AppColors, AppTextStyles
import '../../../common/extensions/extensions.dart'; // Para .w, .h (se estiver usando)

// Adicionado o enum TransactionType aqui ou importe de onde estiver definido
enum TransactionType { income, outcome }

class BalanceCardWidget extends StatefulWidget {
  const BalanceCardWidget({
    super.key,
    required this.controller,
  });

  final BalanceController controller;

  @override
  State<BalanceCardWidget> createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget> {
 final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$'); // Formatter usado abaixo

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleBalanceStateChange);
  }

  void _handleBalanceStateChange() {
    // Apenas chama setState para reconstruir com novos dados do controller
    if (mounted) {
       setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleBalanceStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ajuste de escala de texto para telas menores (opcional)
    double textScaleFactor = MediaQuery.of(context).size.width <= 360 ? 0.8 : 1.0;

    // *** CORREÇÃO PRINCIPAL: Retorna o Container diretamente ***
    return Container(
      // A margem horizontal agora será controlada na HomePage com Padding
      // margin: EdgeInsets.symmetric(horizontal: 24.w), // Removido daqui

      // Padding interno do card
      padding: EdgeInsets.symmetric(
        horizontal: 24.0, // Usando valor fixo (ou 24.w se ScreenUtil configurado)
        vertical: 32.0,  // Usando valor fixo (ou 32.h se ScreenUtil configurado)
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkGreen, // Cor de fundo do card
        borderRadius: BorderRadius.all(
          Radius.circular(16.0), // Bordas arredondadas
        ),
      ),
      child: Column( // Conteúdo do card
        mainAxisSize: MainAxisSize.min, // Encolhe para caber o conteúdo
        children: [
          Row( // Linha superior: Título, Saldo e Menu
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column( // Coluna para Título e Valor do Saldo
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Total', // Corrigido para Português
                    textScaleFactor: textScaleFactor,
                    style: AppTextStyles.mediumText16w600.apply(color: AppColors.white),
                  ),
                  AnimatedBuilder( // Mostra valor ou loading
                      animation: widget.controller,
                      builder: (context, _) {
                        if (widget.controller.state is BalanceStateLoading) {
                          // Placeholder simples durante o loading
                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            color: AppColors.white.withOpacity(0.2),
                            width: 150, // Largura fixa para placeholder
                            height: 36, // Altura do texto aproximada
                          );
                        }
                        // Exibe o saldo formatado
                        return ConstrainedBox(
                          // Limita a largura máxima do texto do saldo
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5), // Ex: Max 50% da largura
                          child: Text(
                            // Usa o formatador definido no State
                            _currencyFormatter.format(widget.controller.balances.totalBalance),
                            textScaleFactor: textScaleFactor,
                            style: AppTextStyles.mediumText30.apply(color: AppColors.white),
                            overflow: TextOverflow.ellipsis, // Evita quebra se muito grande
                            maxLines: 1,
                          ),
                        );
                      })
                ],
              ),
              // Ícone de Menu (Popup) - Mantenha ou remova se não usar
              GestureDetector(
                onTap: () => log('options'), // Ação do menu
                child: PopupMenuButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz, color: AppColors.white), // Ícone do menu
                  itemBuilder: (context) => [
                    const PopupMenuItem( height: 24.0, value: 'opt1', child: Text("Opção 1"), ), // Exemplo
                    const PopupMenuItem( height: 24.0, value: 'opt2', child: Text("Opção 2"), ), // Exemplo
                  ],
                  onSelected: (value) { // Lógica para quando um item é selecionado
                     log('Selected: $value');
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 36.0), // Espaçamento vertical (ou 36.h)
          Row( // Linha inferior: Receitas e Despesas
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Receitas
              AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  return TransactionValueWidget(
                    amount: widget.controller.balances.totalIncome,
                    // controller: widget.controller, // Passar controller se TransactionValueWidget precisar dele
                    type: TransactionType.income,
                  );
                },
              ),
              // Despesas
              AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  return TransactionValueWidget(
                    amount: widget.controller.balances.totalOutcome,
                    // controller: widget.controller, // Passar controller se TransactionValueWidget precisar dele
                    type: TransactionType.outcome,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
    // *** FIM DA CORREÇÃO ***
  }
}


// Widget auxiliar para exibir valores de Receita/Despesa (SE ESTIVER NESTE ARQUIVO)
// Se TransactionValueWidget estiver em outro local, remova daqui e importe.
class TransactionValueWidget extends StatelessWidget {
  const TransactionValueWidget({
    super.key,
    required this.amount,
    // required this.controller, // Removido se não for usado diretamente aqui
    this.type = TransactionType.income,
  });
  // final BalanceController controller; // Removido se não for usado
  final double amount;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ '); // Formatter local
    double textScaleFactor = MediaQuery.of(context).size.width <= 360 ? 0.8 : 1.0;
    double iconSize = MediaQuery.of(context).size.width <= 360 ? 16.0 : 24.0;
    final Color valueColor = type == TransactionType.income ? AppColors.income : AppColors.outcome;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container( // Ícone Arredondado
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration( color: AppColors.white.withOpacity(0.06), borderRadius: const BorderRadius.all( Radius.circular(16.0), ), ),
          child: Icon( type == TransactionType.income ? Icons.arrow_upward : Icons.arrow_downward, color: valueColor, size: iconSize, ), // Usa valueColor para o ícone também
        ),
        const SizedBox(width: 8.0), // Espaço aumentado
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text( type == TransactionType.income ? 'Receitas' : 'Despesas', // Corrigido para Português
              textScaleFactor: textScaleFactor,
              style: AppTextStyles.mediumText16w500.apply(color: AppColors.white.withOpacity(0.8)), // Cor ligeiramente diferente do saldo
            ),
             // Usando AnimatedBuilder aqui apenas se precisar de placeholder de loading
             // Se BalanceController já notifica e o pai reconstrói, pode ser só o Text
            // AnimatedBuilder(
            //    animation: controller, // Precisa do controller se usar AnimatedBuilder
            //    builder: (context, _) {
            //       if (controller.state is BalanceStateLoading) { // Precisa do controller
            //          return Container( color: AppColors.white.withOpacity(0.2), constraints: BoxConstraints.tightFor(width: 80.0), height: 24.0, );
            //       }
                  // Exibe o valor diretamente se não precisar de loading aqui
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3), // Limita largura
                    child: Text( _currencyFormatter.format(amount), // Usa formatador local
                      textScaleFactor: textScaleFactor,
                      style: AppTextStyles.mediumText16w600.apply(color: AppColors.white), // Fonte um pouco menor que o saldo
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
            //    }),
          ],
        )
      ],
    );
  }
}