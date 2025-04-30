// lib/features/stats/stats_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necessário para formatar datas

// Import da tela de relatório foi REMOVIDO pois não é mais usada
// import 'package:tcc_3/features/reports/view/monthly_report_screen.dart';

import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/common/widgets/app_header.dart';
import 'package:tcc_3/common/widgets/custom_circular_progress_indicator.dart';
import 'package:tcc_3/common/widgets/transaction_listview.dart';
import 'stats_controller.dart'; // Controller refatorado
import 'stats_state.dart';

// Extensão para capitalizar strings (mantida)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) { return this; }
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

// Classe auxiliar LegendData (necessária se _buildLegendItem for usado aqui, ou movida)
// Se _buildLegendItem for usado APENAS no Controller, pode remover daqui.
// Vamos assumir que _buildLegendItem é necessário aqui para _buildDetailedExpenseBreakdownCard


class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {

  final _statsController = locator.get<StatsController>();
  late final TabController _periodTabController; // Para as abas Day/Week/Month/Year

  // Formatadores
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR'); // Para exibir o range
  final _compactDateFormatter = DateFormat('dd/MM', 'pt_BR'); // Formato mais curto para range

  // Estado para o toque no gráfico de pizza detalhado
  int? _detailedPieTouchedIndex;

  @override
  void initState() {
    super.initState();
    // Inicializa o controller das abas principais (Day/Week/Month/Year)
    _statsController.getTrasactionsByPeriod(); // Busca dados para gráficos principais
    _periodTabController = TabController(
      // Usa o período do controller, que deve ser inicializado lá também
      initialIndex: _statsController.selectedPeriod.index,
      length: _statsController.periods.length,
      vsync: this,
    );
    _periodTabController.addListener(() {
      if (!_periodTabController.indexIsChanging &&
          _periodTabController.index != _statsController.selectedPeriod.index) {
          _statsController.getTrasactionsByPeriod(
            period: StatsPeriod.values[_periodTabController.index]);
      }
    });
    // A busca inicial do relatório DETALHADO é feita no construtor do StatsController.
  }

  @override
  void dispose() {
    _periodTabController.dispose();
    // Se o controller não for singleton e precisar ser descartado:
    // _statsController.dispose(); // Adicione se necessário
    super.dispose();
  }

  // Método para exibir o seletor de intervalo de datas
  Future<void> _showDateRangePicker() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _statsController.reportStartDate,
        end: _statsController.reportEndDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Permite selecionar até 1 ano no futuro
      locale: const Locale('pt', 'BR'),
      helpText: 'SELECIONE O INTERVALO',
      cancelText: 'CANCELAR',
      confirmText: 'OK',
      saveText: 'SALVAR', // Embora saveText não seja padrão, pode ser útil em alguns builders
      fieldStartHintText: 'Data inicial',
      fieldEndHintText: 'Data final',
      fieldStartLabelText: 'Início',
      fieldEndLabelText: 'Fim',
      // Estilização opcional com builder:
      // builder: (context, child) {
      //   return Theme(
      //     data: Theme.of(context).copyWith(
      //       colorScheme: Theme.of(context).colorScheme.copyWith(
      //             primary: AppColors.green, // Cor principal
      //             onPrimary: AppColors.white, // Cor do texto sobre a principal
      //           ),
      //     ),
      //     child: child!,
      //   );
      // },
    );

    if (pickedRange != null) {
      // Chama o método do controller para atualizar com o intervalo customizado
      await _statsController.selectCustomDateRange(pickedRange);
      // setState(() {}); // O AnimatedBuilder já deve ouvir o controller
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appHeaderHeight = screenHeight * 0.15;
    final chartHeight = screenHeight * 0.25;

    return Scaffold(
      // Define a cor de fundo aqui para evitar problemas com transparência de cards
      backgroundColor: AppColors.iceWhite, // Ou a cor de fundo desejada
      body: Stack(
        children: [
          const AppHeader.noBackground(title: 'Estatísticas'),
          Positioned(
            top: appHeaderHeight, left: 0, right: 0, bottom: 0,
            child: Column(
              children: [
                // --- Abas Principais (Day/Week/Month/Year) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TabBar(
                    controller: _periodTabController,
                    indicator: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: AppColors.green,),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.green,
                    splashBorderRadius: BorderRadius.circular(8.0),
                    tabs: _statsController.periods.map((period) => Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(StringExtension(period.name).capitalize(), textAlign: TextAlign.center, style: AppTextStyles.smallText13.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16.0),

                // --- Conteúdo Principal da Página (Controlado pelo AnimatedBuilder) ---
                Expanded(
                  child: AnimatedBuilder(
                    animation: _statsController,
                    builder: (context, child) {
                      final state = _statsController.state;

                      // Tratamento de Loading/Erro inicial (antes de qualquer dado ser carregado)
                      if (state is StatsStateLoading && _statsController.transactions.isEmpty && _statsController.isDetailedReportLoading) {
                          return const Center(child: CustomCircularProgressIndicator(color: AppColors.green));
                      }
                      // Mostra erro apenas se AMBAS as buscas falharem inicialmente? Ou só a principal? Ajustar conforme necessidade.
                      if (state is StatsStateError && _statsController.transactions.isEmpty) {
                          return Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text('Erro ao carregar dados iniciais: ${state.message}', textAlign: TextAlign.center), ));
                      }

                      // Se chegou aqui, pelo menos a busca principal (abas) já rodou ou está rodando.
                      // O conteúdo detalhado tem seu próprio controle de loading (_isDetailedReportLoading).
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80), // Espaço para scroll total
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Seção de Resumo e Gráfico Principal (Controlada pelas Abas) ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mostra resumo principal mesmo se relatório detalhado estiver carregando
                                  _buildSummarySection(),
                                  const SizedBox(height: 24.0),
                                  Text(
                                      _statsController.selectedPeriod == StatsPeriod.day || _statsController.selectedPeriod == StatsPeriod.week
                                          ? 'Receitas x Despesas (${StringExtension(_statsController.selectedPeriod.name).capitalize()})'
                                          : 'Evolução do Saldo (${StringExtension(_statsController.selectedPeriod.name).capitalize()})',
                                      style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold)
                                    ),
                                  const SizedBox(height: 16.0),
                                  SizedBox(
                                      height: chartHeight,
                                      // Mostra gráfico principal ou placeholder
                                      child: _statsController.barGroups.isNotEmpty || _statsController.balanceSpots.isNotEmpty
                                        ? (_statsController.selectedPeriod == StatsPeriod.day || _statsController.selectedPeriod == StatsPeriod.week
                                            ? BarChart(_buildBarChartData())
                                            : LineChart(_buildLineChartData()))
                                        : Container( height: chartHeight, alignment: Alignment.center, child: const Text("Sem dados para gráfico.", style: TextStyle(color: Colors.grey)) ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            const Divider(height: 1, thickness: 1),
                            const SizedBox(height: 16.0),

                            // --- Seção: RELATÓRIO DETALHADO ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Relatório Detalhado', style: AppTextStyles.mediumText18),
                                  const SizedBox(height: 16.0),
                                  // Controles (Botões de Preset + Seletor de Data)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ToggleButtons(
                                          isSelected: [
                                            _statsController.selectedReportPreset == ReportPresetType.weekly,
                                            _statsController.selectedReportPreset == ReportPresetType.monthly,
                                            _statsController.selectedReportPreset == ReportPresetType.annual,
                                          ],
                                          onPressed: (int index) {
                                            _statsController.selectReportPreset(ReportPresetType.values[index]);
                                          },
                                          borderRadius: BorderRadius.circular(8.0), constraints: const BoxConstraints(minHeight: 40.0), fillColor: AppColors.green.withAlpha(40), selectedColor: AppColors.green, color: AppColors.darkGrey, selectedBorderColor: AppColors.green,
                                          children: const <Widget>[ Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Semanal')), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Mensal')), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Anual')), ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton( icon: const Icon(Icons.calendar_month_outlined, color: AppColors.green), tooltip: 'Selecionar intervalo', onPressed: _showDateRangePicker, ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Center( child: Text( "${_compactDateFormatter.format(_statsController.reportStartDate)} - ${_compactDateFormatter.format(_statsController.reportEndDate)}", style: AppTextStyles.smallText.copyWith(color: AppColors.grey), ), ),
                                  const SizedBox(height: 16.0),

                                  // Conteúdo do Relatório Detalhado (com indicador de loading)
                                  _statsController.isDetailedReportLoading
                                    ? const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 40.0),
                                       // CORRIGIDO: Removido 'size: 30'
                                       child: CustomCircularProgressIndicator(),
                                      ))
                                    // CORRIGIDO: Removido 'const' antes de Column
                                    : Column(
                                        // Verifica se houve erro específico no carregamento DETALHADO
                                        // (Considerando que o estado geral pode ser Success)
                                        children: _statsController.state is StatsStateError
                                        ? [ Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text('Erro ao carregar relatório: ${(_statsController.state as StatsStateError).message}', textAlign: TextAlign.center), )) ]
                                        : [
                                            _buildDetailedSummaryCard(),
                                            const SizedBox(height: 24),
                                            _buildDetailedExpenseBreakdownCard(),
                                            const SizedBox(height: 24),
                                            _buildFinancialTipCard(_statsController.getFinancialTip()),
                                          ],
                                      )
                                ],
                              ),
                            ),
                            // --- Fim da Seção Relatório Detalhado ---

                            const SizedBox(height: 24.0),
                            const Divider(height: 1, thickness: 1),
                            const SizedBox(height: 16.0),

                            // --- Seção de Transações (Controlada pelas Abas Principais) ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                   Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Transações do Período (Aba)', style: AppTextStyles.mediumText18), GestureDetector( onTap: () => setState(() => _statsController.sortTransactions()), child: Icon( _statsController.sorted ? Icons.arrow_downward : Icons.arrow_upward, color: AppColors.green, size: 20), ), ], ),
                                  const SizedBox(height: 8.0),
                                  // Exibe a lista de transações do período da ABA
                                  _statsController.transactions.isEmpty
                                    ? const Padding( padding: EdgeInsets.symmetric(vertical: 32.0), child: Center(child: Text("Nenhuma transação encontrada para este período.", style: TextStyle(color: AppColors.grey))), )
                                    : TransactionListView( transactionList: _statsController.transactions, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), onChange: () => _statsController.getTrasactionsByPeriod(), ),
                                ],
                              ),
                            ),
                            // --- Fim da Seção de Transações ---
                          ],
                        ),
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

  // --- Widgets Auxiliares ---

  // Resumo Principal (Abas)
  Widget _buildSummarySection() { Color netBalanceColor = _statsController.netBalance >= 0 ? AppColors.income : AppColors.outcome; return Container( padding: const EdgeInsets.all(16.0), decoration: BoxDecoration( color: AppColors.green.withAlpha((255 * 0.05).round()), borderRadius: BorderRadius.circular(12.0), ), child: Row( mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ _buildSummaryItem('Receitas', _statsController.totalIncome, AppColors.income), _buildSummaryItem('Despesas', _statsController.totalExpense, AppColors.outcome), _buildSummaryItem('Saldo', _statsController.netBalance, netBalanceColor), ], ), ); }
  Widget _buildSummaryItem(String label, double value, Color color) { return Column( children: [ Text( label, style: AppTextStyles.smallText.copyWith(color: AppColors.grey, fontSize: 13)), const SizedBox(height: 4), Text( _currencyFormatter.format(value), style: AppTextStyles.mediumText16w600.copyWith(color: color, fontSize: 17)), ], ); }

  // Card de Resumo DETALHADO
   Widget _buildDetailedSummaryCard() { final double income = _statsController.detailedReportIncome; final double expense = _statsController.detailedReportExpense; final double netBalance = _statsController.detailedReportNetBalance; final Color netColor = netBalance >= 0 ? AppColors.income : AppColors.outcome; final String netPrefix = netBalance >= 0 ? "Economia no período:" : "Déficit no período:"; final IconData netIcon = netBalance >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded; return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [  Text("Resumo do Período Selecionado", style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), _buildSummaryRow("Receitas:", income, AppColors.income), const SizedBox(height: 8), _buildSummaryRow("Despesas:", expense, AppColors.outcome), const Divider(height: 24, thickness: 0.5), Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Row( mainAxisSize: MainAxisSize.min, children: [ Icon(netIcon, color: netColor, size: 18), const SizedBox(width: 8), Text(netPrefix, style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey)), ], ), Text( _currencyFormatter.format(netBalance.abs()), style: AppTextStyles.mediumText18.copyWith(color: netColor, fontWeight: FontWeight.bold) ), ], ), ], ), ), ); }

  // Card de Detalhamento de Despesas DETALHADO
  Widget _buildDetailedExpenseBreakdownCard() { final List<PieChartSectionData> pieSections = _statsController.detailedPieChartSections; final List<LegendData> legendItems = _statsController.detailedLegendData.cast<LegendData>(); bool hasExpenseData = legendItems.isNotEmpty; bool hasPieChartData = pieSections.isNotEmpty && !(pieSections.length == 1 && pieSections.first.value == 1 && pieSections.first.color == AppColors.grey.withOpacity(0.5)); return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [  Text("Gastos por Categoria no Período", style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), SizedBox( height: 180, child: hasPieChartData ? PieChart( PieChartData( sectionsSpace: 2, centerSpaceRadius: 45, startDegreeOffset: -90, sections: pieSections.map((section) { final isTouched = pieSections.indexOf(section) == _detailedPieTouchedIndex; final double radius = isTouched ? 65.0 : 55.0; final double fontSize = isTouched ? 11 : 10; return section.copyWith( radius: radius, titleStyle: TextStyle( fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: const [Shadow(color: Colors.black54, blurRadius: 2)] ), ); }).toList(), pieTouchData: PieTouchData( touchCallback: (FlTouchEvent event, pieTouchResponse) { setState(() { if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) { _detailedPieTouchedIndex = -1; return; } _detailedPieTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex; }); }, ), ), swapAnimationDuration: const Duration(milliseconds: 150), swapAnimationCurve: Curves.linear, ) : Center(child: Text("Nenhuma despesa registrada neste período.", style: TextStyle(color: AppColors.grey))) ), const SizedBox(height: 20), if(hasExpenseData) Wrap( spacing: 16.0, runSpacing: 8.0, children: legendItems.map((item) => _buildLegendItem(item.color, item.name)).toList(), ), ], ), ), ); }

  // Card de Dica Financeira
  Widget _buildFinancialTipCard(String tip) { if (tip.isEmpty) { return const SizedBox.shrink(); } return Card( elevation: 1, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.green.withOpacity(0.5), width: 1), ), color: AppColors.white, child: Padding( padding: const EdgeInsets.all(16.0), child: Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Icon( Icons.lightbulb_outline_rounded, color: AppColors.green, size: 28, ), const SizedBox(width: 12), Expanded( child: Text( tip, style: AppTextStyles.smallText.copyWith( color: AppColors.darkGrey, fontSize: 14, height: 1.4 ), ), ), ], ), ), ); }

  // Item da Legenda
  Widget _buildLegendItem(Color color, String name) { return Row( mainAxisSize: MainAxisSize.min, children: [ Container( width: 12, height: 12, decoration: BoxDecoration( color: color, borderRadius: BorderRadius.circular(3), ), ), const SizedBox(width: 6), Text( name, style: AppTextStyles.smallText.copyWith(color: AppColors.darkGrey), ), ], ); }

  // Linha do Resumo (Receita/Despesa)
  Widget _buildSummaryRow(String label, double value, Color valueColor) { return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(label, style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey)), Text( _currencyFormatter.format(value), style: AppTextStyles.mediumText16w600.copyWith(color: valueColor) ), ], ); }


  // --- Métodos para construir os Gráficos Principais (Controlados pelas Abas) ---
  LineChartData _buildLineChartData() { /* ... código sem alterações ... */ Color balanceLineColor = _statsController.netBalance >= 0 ? AppColors.income : AppColors.outcome; return LineChartData( lineTouchData: LineTouchData( touchTooltipData: LineTouchTooltipData( getTooltipItems: (touchedSpots) { return touchedSpots.map((LineBarSpot touchedSpot) { return LineTooltipItem( 'Saldo: ${_currencyFormatter.format(touchedSpot.y)}', const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12,), ); }).toList(); }, ), handleBuiltInTouches: true, getTouchedSpotIndicator:(LineChartBarData barData, List<int> spotIndexes) { return spotIndexes.map((spotIndex) { return TouchedSpotIndicatorData( FlLine(color: balanceLineColor.withAlpha(150), strokeWidth: 2), FlDotData( show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: Colors.white, strokeWidth: 2, strokeColor: balanceLineColor), ), ); }).toList(); }, ), gridData: FlGridData( show: true, drawVerticalLine: false, horizontalInterval: _statsController.maxYValueForCharts > 0 ? (_statsController.maxYValueForCharts - _statsController.minYValueForBalanceChart).abs() / 4 : 1, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.lightGrey.withOpacity(0.1), strokeWidth: 1), ), titlesData: FlTitlesData( show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 30, interval: _statsController.interval, getTitlesWidget: (double value, TitleMeta meta) { String text; switch (_statsController.selectedPeriod) { case StatsPeriod.month: text = 'S${(value + 1).toInt()}'; break; case StatsPeriod.year: text = _statsController.monthName(value); break; default: text = ''; } return Text(text, style: AppTextStyles.smallText.copyWith(fontSize: 11, color: AppColors.grey)); }, ), ), leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 50, getTitlesWidget: (double value, TitleMeta meta) { if (value == meta.min || value == meta.max || (value > -0.01 && value < 0.01) ) { final String formattedValue = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0).format(value); return Text(formattedValue, style: AppTextStyles.smallText.copyWith(fontSize: 10, color: AppColors.grey)); } return const SizedBox.shrink(); }, ), ), ), borderData: FlBorderData(show: true, border: Border.all(color: AppColors.lightGrey.withOpacity(0.2), width: 1)), minX: _statsController.minX, maxX: _statsController.maxX, minY: _statsController.minYValueForBalanceChart, maxY: _statsController.maxYValueForCharts, lineBarsData: [ LineChartBarData( spots: _statsController.balanceSpots, isCurved: true, color: balanceLineColor, barWidth: 3.5, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData( show: true, gradient: LinearGradient( colors: [balanceLineColor.withAlpha(70), balanceLineColor.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter ) ), ), ], ); }
  BarChartData _buildBarChartData() { /* ... código sem alterações ... */ return BarChartData( alignment: BarChartAlignment.spaceAround, groupsSpace: 8, barTouchData: BarTouchData( touchTooltipData: BarTouchTooltipData( tooltipPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), tooltipMargin: 8, getTooltipItem: (group, groupIndex, rod, rodIndex) { String type = rodIndex == 0 ? 'Receita' : 'Despesa'; return BarTooltipItem( '$type\n', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), children: <TextSpan>[ TextSpan( text: _currencyFormatter.format(rod.toY), style: TextStyle( color: rod.color, fontSize: 13, fontWeight: FontWeight.w500,), ), ], ); }, ), touchCallback: (FlTouchEvent event, BarTouchResponse? response) {}, ), titlesData: FlTitlesData( show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 28, getTitlesWidget: (double value, TitleMeta meta) { String text; int index = value.toInt(); if (index < 0 || index >= _statsController.barGroups.length) return const SizedBox.shrink(); switch (_statsController.selectedPeriod) { case StatsPeriod.day: text = (index % 6 == 0) ? '${index}h' : ''; break; case StatsPeriod.week: text = _statsController.dayName(value); break; default: text = ''; } return Text(text, style: AppTextStyles.smallText.copyWith(fontSize: 10, color: AppColors.grey)); }, ), ), leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 40, getTitlesWidget: (double value, TitleMeta meta) { if (value == 0 || value == meta.max) { final String formattedValue = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0).format(value); return Text(formattedValue, style: AppTextStyles.smallText.copyWith(fontSize: 9, color: AppColors.grey)); } return const SizedBox.shrink(); }, ), ), ), gridData: FlGridData( show: true, drawVerticalLine: false, horizontalInterval: _statsController.maxYValueForCharts > 0 ? _statsController.maxYValueForCharts / 4 : 1, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.lightGrey.withOpacity(0.1), strokeWidth: 1), ), borderData: FlBorderData(show: false), barGroups: _statsController.barGroups, maxY: _statsController.maxYValueForCharts, minY: 0, ); }

} // Fim da classe _StatsPageState