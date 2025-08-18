// lib/features/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Imports para a funcionalidade de PDF
import 'package:tcc_3/common/widgets/custom_snackbar.dart';
import 'package:tcc_3/features/stats/stats_controller.dart';
import 'package:open_file/open_file.dart';

// Imports do seu projeto
import 'package:tcc_3/common/features/balance_controller.dart';
import 'package:tcc_3/common/widgets/custom_circular_progress_indicator.dart';
import 'package:tcc_3/common/widgets/custom_bottom_sheet.dart';
import 'package:tcc_3/common/widgets/tip_card.dart';
import '../../common/constants/constants.dart';
import '../../common/extensions/extensions.dart';
import '../../common/widgets/transaction_listview.dart';
import '../../locator.dart';
import 'home_controller.dart';
import 'home_state.dart';
import 'widgets/balance_card_widget.dart';
import 'models/tip_model.dart';

// --- Widget AppHeader ---
class AppHeader extends StatelessWidget {
  final bool isGeneratingPdf;
  final VoidCallback onNotificationPressed;

  const AppHeader({
    Key? key,
    required this.isGeneratingPdf,
    required this.onNotificationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeController = locator.get<HomeController>();
    final Color headerTextColor = AppColors.white;

    return AnimatedBuilder(
      animation: homeController,
      builder: (context, _) {
        if (homeController.state is HomeStateSuccess) {
          final userName = StringExtension(homeController.userData.name)?.capitalize() ?? '';
          String greeting = 'Olá';
          int hour = DateTime.now().hour;
          if (hour < 12) {
            greeting = 'Bom dia';
          } else if (hour < 18) {
            greeting = 'Boa tarde';
          } else {
            greeting = 'Boa noite';
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$greeting,\n$userName',
                style: AppTextStyles.mediumText18.copyWith(color: headerTextColor),
              ),
              isGeneratingPdf
                ? const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                  )
                : IconButton(
                    onPressed: onNotificationPressed,
                    icon: Icon(Icons.description_outlined, color: headerTextColor),
                    iconSize: 28.0,
                    tooltip: 'Baixar relatório do mês anterior',
                  ),
            ],
          );
        }
        return const SizedBox(height: 56);
      },
    );
  }
}

// --- HomePage Principal ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with CustomModalSheetMixin, CustomSnackBar {
  final homePageController = locator.get<HomeController>();
  final balanceController = locator.get<BalanceController>();
  final _statsController = locator.get<StatsController>();
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    homePageController.getUserData();
    homePageController.getLatestTransactions();
    balanceController.getBalances();
    homePageController.loadTips();
    homePageController.addListener(_handleHomeStateChange);
  }

  @override
  void dispose() {
    homePageController.removeListener(_handleHomeStateChange);
    super.dispose();
  }

  void _handleHomeStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  // COLE ESTES DOIS MÉTODOS NO LUGAR DO _handleExportPdfPressed

// Método 1: Mostra o diálogo para o usuário escolher o mês
Future<void> _showMonthPickerAndGenerateReport() async {
  final now = DateTime.now();
  // Gera uma lista dos últimos 12 meses para o usuário escolher
  final List<DateTime> months = List.generate(12, (index) {
    return DateTime(now.year, now.month - index, 1);
  });

  // Mostra o diálogo
  final DateTime? selectedMonth = await showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('Selecione o mês do relatório'),
        children: months.map((month) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, month);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(StringExtension(DateFormat.yMMMM('pt_BR').format(month)).capitalize()),
            ),
          );
        }).toList(),
      );
    },
  );

  // Se o usuário escolheu um mês, chama o método para gerar o PDF
  if (selectedMonth != null) {
    await _generatePdfForSelectedMonth(selectedMonth);
  }
}

// Método 2: Lida com o loading e a chamada ao controller
Future<void> _generatePdfForSelectedMonth(DateTime month) async {
  setState(() => _isGeneratingPdf = true);

  // Chama o novo método correto: generateMonthlyPdfReport
  final filePath = await _statsController.generateMonthlyPdfReport(targetMonth: month);

  setState(() => _isGeneratingPdf = false);

  if (!mounted) return;

  if (filePath == "NO_DATA") {
    showCustomSnackBar(
      context: context,
      text: 'Não há dados para o mês selecionado.',
      type: SnackBarType.success, // Ou o tipo que você tiver, como .notification
    );
    return;
  }

  if (filePath != null) {
    OpenFile.open(filePath);
    showCustomSnackBar(
      context: context,
      text: 'Relatório gerado com sucesso!',
      type: SnackBarType.success,
    );
  } else {
    showCustomSnackBar(
      context: context,
      text: 'Erro ao gerar o relatório PDF.',
      type: SnackBarType.error,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    double headerBackgroundHeight = 260.h;
    double balanceCardTop = 130.h;
    double balanceCardHeightEstimate = 190.h;
    double spacingAfterCard = 40.h;
    double tipsSectionHeight = 180;
    double spacingAfterTips = 40.h;
    double topNovoDicas = balanceCardTop + balanceCardHeightEstimate + spacingAfterCard;
    double topNovoHistory = topNovoDicas + tipsSectionHeight + spacingAfterTips;

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerBackgroundHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18.0),
                  bottomRight: Radius.circular(18.0),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60.h,
            left: 16.w,
            right: 16.w,
            child: AppHeader(
              isGeneratingPdf: _isGeneratingPdf,
              onNotificationPressed: _showMonthPickerAndGenerateReport,
            ),
          ),
          Positioned(
            top: balanceCardTop,
            left: 16.w,
            right: 16.w,
            child: BalanceCardWidget(
              controller: balanceController,
              drawBackground: true,
            ),
          ),
          Positioned(
            top: topNovoDicas,
            left: 0,
            right: 0,
            height: tipsSectionHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                  child: Text('Dicas pra você', style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: homePageController,
                    builder: (context, _) {
                      if (homePageController.isLoadingTips) {
                        return const Center(child: CustomCircularProgressIndicator());
                      }
                      if (homePageController.tips.isEmpty) {
                        return const Center(child: Text("Nenhuma dica disponível."));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: homePageController.tips.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(right: index == homePageController.tips.length - 1 ? 0 : 12.0),
                            child: TipCard(tip: homePageController.tips[index]),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topNovoHistory,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Histórico de Transações',
                        style: AppTextStyles.mediumText18.copyWith(color: AppColors.darkGrey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: homePageController,
                    builder: (context, _) {
                      if (homePageController.transactions.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text('Nenhuma transação encontrada.'),
                          ),
                        );
                      }
                      return TransactionListView(
                        transactionList: homePageController.transactions,
                        onChange: () {
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}