// lib/features/stats/stats_page.dart

import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Imports
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/common/constants/routes.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/common/widgets/custom_circular_progress_indicator.dart';
import 'package:tcc_3/common/widgets/primary_button.dart';
import 'package:tcc_3/common/widgets/custom_bottom_sheet.dart';
import 'package:tcc_3/common/widgets/custom_snackbar.dart';
import 'package:tcc_3/common/models/transaction_model.dart';
import 'package:tcc_3/common/features/transaction/transaction_controller.dart';
import 'package:tcc_3/common/features/balance_controller.dart';
import 'stats_controller.dart';
import 'stats_state.dart';

// Enum e Extensão (Remova se já definidos globalmente)
enum StatPeriod { day, week, month, year }
extension StatPeriodExtension on StatPeriod {
  StatsPeriod get controllerPeriod { /* ... */ switch (this) { case StatPeriod.day: return StatsPeriod.day; case StatPeriod.week: return StatsPeriod.week; case StatPeriod.month: return StatsPeriod.month; case StatPeriod.year: return StatsPeriod.year; } }
  static StatPeriod fromControllerPeriod(StatsPeriod controllerPeriod) { /* ... */ switch (controllerPeriod) { case StatsPeriod.day: return StatPeriod.day; case StatsPeriod.week: return StatPeriod.week; case StatsPeriod.month: return StatPeriod.month; case StatsPeriod.year: return StatPeriod.year; } }
   String get capitalizedName { /* ... */ String name; switch (this) { case StatPeriod.day: name = 'Day'; break; case StatPeriod.week: name = 'Week'; break; case StatPeriod.month: name = 'Month'; break; case StatPeriod.year: name = 'Year'; break; } if (name.isEmpty) return name; return "${name[0].toUpperCase()}${name.substring(1).toLowerCase()}"; }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with CustomModalSheetMixin, CustomSnackBar {
  // Controllers, Formatters, etc.
  final _statsController = locator.get<StatsController>();
  final _transactionController = locator.get<TransactionController>();
  final _balanceController = locator.get<BalanceController>();
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _compactDateFormatter = DateFormat('dd/MM', 'pt_BR');
  final _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  int? _detailedPieTouchedIndex;
  late StatPeriod _selectedPeriod;

  // Cores (Ajuste conforme necessário)
  final Color appBarColor = AppColors.green;
  final Color selectedButtonColor = const Color(0xFF1B8C6B); // Cor estimada da referência, ajuste!
  final Color selectedTextColor = AppColors.white;
  final Color unselectedTextColor = AppColors.white.withOpacity(0.7);

  @override
  void initState() {
    super.initState();
    _selectedPeriod = StatPeriodExtension.fromControllerPeriod(_statsController.selectedPeriod);
    if(_statsController.state is StatsStateInitial) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { _statsController.getTrasactionsByPeriod(); }
       });
    }
  }

  @override
  void dispose() { super.dispose(); }

  // Métodos de Exclusão e DatePicker (sem alteração)
  Future<bool> _confirmDeleteTransaction(TransactionModel item) async { /* ... */ final confirm = await showCustomModalBottomSheet( context: context, content: 'Deseja realmente excluir a transação "${item.description.isNotEmpty ? item.description : "sem descrição"}"?', actions: [ Expanded( child: OutlinedButton( onPressed: () => Navigator.pop(context, false), style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[700], side: BorderSide(color: Colors.grey[400]!)), child: const Text('Cancelar'), ), ), const SizedBox(width: 16.0), Expanded( child: PrimaryButton( text: 'Confirmar', onPressed: () => Navigator.pop(context, true), ), ), ], ); return confirm == true; }
  Future<void> _deleteTransaction(TransactionModel item) async { /* ... */ try { await _transactionController.deleteTransaction(item); await _balanceController.updateBalance( oldTransaction: item, newTransaction: item.copyWith(value: 0), ); await _statsController.getTrasactionsByPeriod(period: _statsController.selectedPeriod); await _statsController.getDetailedReportData(startDate: _statsController.reportStartDate, endDate: _statsController.reportEndDate); if(mounted){ showCustomSnackBar(context: context, text: 'Transação excluída.', type: SnackBarType.success); } } catch(e) { print("Erro no _deleteTransaction (StatsPage): $e"); if(mounted){ showCustomSnackBar(context: context, text: 'Erro ao excluir: ${e.toString()}', type: SnackBarType.error); } } }
  Future<void> _showDateRangePicker() async { /* ... */ DateTimeRange? pickedRange = await showDateRangePicker( context: context, initialDateRange: DateTimeRange( start: _statsController.reportStartDate, end: _statsController.reportEndDate, ), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)), locale: const Locale('pt', 'BR'), helpText: 'SELECIONE O INTERVALO', cancelText: 'CANCELAR', confirmText: 'OK', ); if (pickedRange != null) { await _statsController.selectCustomDateRange(pickedRange); } }

  @override
  Widget build(BuildContext context) {
    final chartHeight = MediaQuery.of(context).size.height * 0.25;

    return Scaffold(
      // Garantindo fundo branco no Scaffold
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Estatísticas', style: AppTextStyles.mediumText18),
        backgroundColor: appBarColor,
        foregroundColor: selectedTextColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true, // Título centralizado
      ),
      body: Column(
        children: [
          // --- Seção de Botões de Período ---
          Container(
            width: double.infinity,
            color: appBarColor,
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 16.0, right: 16.0), // Padding vertical reduzido
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Tentando spaceEvenly
              children: StatPeriod.values.map((period) {
                return _buildPeriodButton(
                  period: period,
                  text: period.capitalizedName,
                  isSelected: _selectedPeriod == period,
                );
              }).toList(),
            ),
          ),
          // --- Fim da Seção de Botões ---

          // --- Conteúdo Principal Rolável ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _statsController.getTrasactionsByPeriod(
                period: _statsController.selectedPeriod
              ),
              color: AppColors.green,
              child: AnimatedBuilder(
                animation: _statsController,
                builder: (context, child) {
                  final state = _statsController.state;

                  if (state is StatsStateLoading && _statsController.transactions.isEmpty && _statsController.isDetailedReportLoading) {
                     return const Center(child: CustomCircularProgressIndicator(color: AppColors.green));
                  }
                  if (state is StatsStateError && _statsController.transactions.isEmpty) {
                     return Container( // <<< Adicionado Container branco aqui em caso de erro inicial
                       color: Colors.white,
                       child: Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text('Erro ao carregar dados: ${state.message}', textAlign: TextAlign.center), ))
                     );
                  }

                  // <<< AJUSTADO: Envolver ListView com Container branco >>>
                  // Isso força o fundo da área rolável a ser branco, caso algo
                  // esteja interferindo com a cor do Scaffold.
                  return Container(
                    color: Colors.white, // Garante fundo branco para a lista
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        // Seção Resumo Rápido e Gráfico Principal
                        Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildSummarySection(), const SizedBox(height: 24.0), Text( _statsController.selectedPeriod == StatsPeriod.day || _statsController.selectedPeriod == StatsPeriod.week ? 'Receitas x Despesas (${_selectedPeriod.capitalizedName})' : 'Evolução do Saldo (${_selectedPeriod.capitalizedName})', style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold) ), const SizedBox(height: 16.0), SizedBox( height: chartHeight, child: _statsController.barGroups.isNotEmpty || _statsController.balanceSpots.isNotEmpty ? (_statsController.selectedPeriod == StatsPeriod.day || _statsController.selectedPeriod == StatsPeriod.week ? BarChart(_buildBarChartData()) : LineChart(_buildLineChartData())) : Container( height: chartHeight, alignment: Alignment.center, child: const Text("Sem dados para gráfico.", style: TextStyle(color: Colors.grey)) ), ), ], ), ),
                        const SizedBox(height: 16.0), const Divider(height: 1, thickness: 1), const SizedBox(height: 16.0),

                        // Seção Relatório Detalhado
                        Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text('Relatório Detalhado', style: AppTextStyles.mediumText18), const SizedBox(height: 16.0), Row( children: [ Expanded( child: ToggleButtons( isSelected: [ _statsController.selectedReportPreset == ReportPresetType.weekly, _statsController.selectedReportPreset == ReportPresetType.monthly, _statsController.selectedReportPreset == ReportPresetType.annual, ], onPressed: (int index) { _statsController.selectReportPreset(ReportPresetType.values[index]); }, borderRadius: BorderRadius.circular(8.0), constraints: const BoxConstraints(minHeight: 40.0), fillColor: AppColors.green.withAlpha(40), selectedColor: AppColors.green, color: AppColors.darkGrey, selectedBorderColor: AppColors.green, children: const <Widget>[ Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Semanal')), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Mensal')), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Anual')), ], ), ), const SizedBox(width: 8), IconButton( icon: const Icon(Icons.calendar_month_outlined, color: AppColors.green), tooltip: 'Selecionar intervalo', onPressed: _showDateRangePicker, ), ], ), const SizedBox(height: 8), Center( child: Text( "${_compactDateFormatter.format(_statsController.reportStartDate)} - ${_compactDateFormatter.format(_statsController.reportEndDate)}", style: AppTextStyles.smallText.copyWith(color: AppColors.grey), ), ), const SizedBox(height: 16.0), _statsController.isDetailedReportLoading ? const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 40.0), child: CustomCircularProgressIndicator(), )) : Column( children: _statsController.state is StatsStateError && !_statsController.isDetailedReportLoading ? [ Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text('Erro ao carregar relatório: ${(_statsController.state as StatsStateError).message}', textAlign: TextAlign.center), )) ] : [ _buildDetailedSummaryCard(), const SizedBox(height: 24), _buildDetailedExpenseBreakdownCard(), const SizedBox(height: 24), _buildFinancialTipCard(_statsController.getFinancialTip()), ], ) ], ), ),
                        const SizedBox(height: 24.0), const Divider(height: 1, thickness: 1), const SizedBox(height: 16.0),

                         // Seção de Transações
                         Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column( children: [ Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Transações do Período', style: AppTextStyles.mediumText18), GestureDetector( onTap: () => setState(() => _statsController.sortTransactions()), child: Icon( _statsController.sorted ? Icons.arrow_downward : Icons.arrow_upward, color: AppColors.green, size: 20), ), ], ), const SizedBox(height: 8.0), _buildTransactionList(), ], ), ),
                      ],
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir cada botão de período (sem alterações nesta versão)
  Widget _buildPeriodButton({
    required StatPeriod period,
    required String text,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        final controllerPeriod = period.controllerPeriod;
        if (_statsController.selectedPeriod != controllerPeriod) {
          setState(() { _selectedPeriod = period; });
          _statsController.getTrasactionsByPeriod(period: controllerPeriod);
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? selectedButtonColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // --- Todos os seus outros métodos _build* aqui (sem alterações internas necessárias) ---
  Widget _buildTransactionList() { /* Seu código aqui... */ final transactions = _statsController.transactions; if (transactions.isEmpty) { return const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0), child: Text( 'Nenhuma transação registrada neste período.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15), ),),); } return Column( children: transactions.map((item) { final bool isIncome = item.value >= 0; final Color itemColor = isIncome ? AppColors.income : AppColors.outcome; final IconData itemIcon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded; final valueString = _currencyFormatter.format(item.value); String formattedDate = 'Data inválida'; try { final date = DateTime.fromMillisecondsSinceEpoch(item.date); formattedDate = _dateFormatter.format(date); } catch (e) { print("Erro formatar data: $e"); } return Dismissible( key: ValueKey(item.id), direction: DismissDirection.endToStart, background: Container( color: AppColors.error.withOpacity(0.85), padding: const EdgeInsets.symmetric(horizontal: 20.0), alignment: Alignment.centerRight, child: const Icon(Icons.delete_outline, color: Colors.white, size: 28), ), confirmDismiss: (direction) => _confirmDeleteTransaction(item), onDismissed: (direction) => _deleteTransaction(item), child: ListTile( onTap: () async { final result = await Navigator.pushNamed(context, NamedRoute.transaction, arguments: item); if (result == true && mounted) { await _statsController.getTrasactionsByPeriod(period: _statsController.selectedPeriod); await _statsController.getDetailedReportData(startDate: _statsController.reportStartDate, endDate: _statsController.reportEndDate); } }, contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), leading: CircleAvatar( radius: 22, backgroundColor: itemColor.withAlpha(30), foregroundColor: itemColor, child: Icon(itemIcon, size: 20), ), title: Text( item.description.isNotEmpty ? item.description : (item.category ?? 'Sem Categoria'), style: AppTextStyles.mediumText16w500, maxLines: 1, overflow: TextOverflow.ellipsis, ), subtitle: Text( formattedDate, style: AppTextStyles.smallText13.copyWith(color: AppColors.lightGrey), ), trailing: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [ Text( valueString, style: AppTextStyles.mediumText16w600.copyWith(color: itemColor)), const SizedBox(height: 2), Text( item.status ? 'Pago' : 'Pendente', style: AppTextStyles.smallText13.copyWith( color: item.status ? AppColors.income.withAlpha(230) : AppColors.notification.withAlpha(230), fontSize: (AppTextStyles.smallText13.fontSize ?? 13) * 0.95, fontWeight: item.status ? FontWeight.normal : FontWeight.w500, ), ), ], ), ), ); }).toList(), ); }
  Widget _buildSummarySection() { /* Seu código aqui... */ Color netBalanceColor = _statsController.netBalance >= 0 ? AppColors.income : AppColors.outcome; return Container( padding: const EdgeInsets.all(16.0), decoration: BoxDecoration( color: AppColors.green.withAlpha((255 * 0.05).round()), borderRadius: BorderRadius.circular(12.0), ), child: Row( mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ _buildSummaryItem('Receitas', _statsController.totalIncome, AppColors.income), _buildSummaryItem('Despesas', _statsController.totalExpense, AppColors.outcome), _buildSummaryItem('Saldo', _statsController.netBalance, netBalanceColor), ], ), ); }
  Widget _buildSummaryItem(String label, double value, Color color) { /* Seu código aqui... */ return Column( children: [ Text( label, style: AppTextStyles.smallText.copyWith(color: AppColors.grey, fontSize: 13)), const SizedBox(height: 4), Text( _currencyFormatter.format(value), style: AppTextStyles.mediumText16w600.copyWith(color: color, fontSize: 17)), ], ); }
  Widget _buildDetailedSummaryCard() { /* Seu código aqui... */ final double income = _statsController.detailedReportIncome; final double expense = _statsController.detailedReportExpense; final double netBalance = _statsController.detailedReportNetBalance; final Color netColor = netBalance >= 0 ? AppColors.income : AppColors.outcome; final String netPrefix = netBalance >= 0 ? "Economia no período:" : "Déficit no período:"; final IconData netIcon = netBalance >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded; return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [  Text("Resumo do Período Selecionado", style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), _buildSummaryRow("Receitas:", income, AppColors.income), const SizedBox(height: 8), _buildSummaryRow("Despesas:", expense, AppColors.outcome), const Divider(height: 24, thickness: 0.5), Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Row( mainAxisSize: MainAxisSize.min, children: [ Icon(netIcon, color: netColor, size: 18), const SizedBox(width: 8), Text(netPrefix, style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey)), ], ), Text( _currencyFormatter.format(netBalance.abs()), style: AppTextStyles.mediumText18.copyWith(color: netColor, fontWeight: FontWeight.bold) ), ], ), ], ), ), ); }
  Widget _buildDetailedExpenseBreakdownCard() { /* Seu código aqui... */ final List<PieChartSectionData> pieSections = _statsController.detailedPieChartSections; final List<LegendData> legendItems = _statsController.detailedLegendData; bool hasExpenseData = legendItems.isNotEmpty; bool hasPieChartData = pieSections.isNotEmpty && !(pieSections.length == 1 && pieSections.first.value == 1 && pieSections.first.color == AppColors.grey.withOpacity(0.5)); return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding( padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [  Text("Gastos por Categoria no Período", style: AppTextStyles.mediumText18.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16), SizedBox( height: 180, child: hasPieChartData ? PieChart( PieChartData( sectionsSpace: 2, centerSpaceRadius: 45, startDegreeOffset: -90, sections: pieSections.map((section) { final isTouched = pieSections.indexOf(section) == _detailedPieTouchedIndex; final double radius = isTouched ? 65.0 : 55.0; final double fontSize = isTouched ? 11 : 10; return section.copyWith( radius: radius, titleStyle: TextStyle( fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: const [Shadow(color: Colors.black54, blurRadius: 2)] ), ); }).toList(), pieTouchData: PieTouchData( touchCallback: (FlTouchEvent event, pieTouchResponse) { setState(() { if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) { _detailedPieTouchedIndex = -1; return; } _detailedPieTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex; }); }, ), ), swapAnimationDuration: const Duration(milliseconds: 150), swapAnimationCurve: Curves.linear, ) : Center(child: Text("Nenhuma despesa registrada neste período.", style: TextStyle(color: AppColors.grey))) ), const SizedBox(height: 20), if(hasExpenseData) Wrap( spacing: 16.0, runSpacing: 8.0, children: legendItems.map((item) => _buildLegendItem(item.color, item.name)).toList(), ), ], ), ), ); }
  Widget _buildFinancialTipCard(String tip) { /* Seu código aqui... */ if (tip.isEmpty) { return const SizedBox.shrink(); } return Card( elevation: 1, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.green.withOpacity(0.5), width: 1), ), color: AppColors.white, child: Padding( padding: const EdgeInsets.all(16.0), child: Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Icon( Icons.lightbulb_outline_rounded, color: AppColors.green, size: 28, ), const SizedBox(width: 12), Expanded( child: Text( tip, style: AppTextStyles.smallText.copyWith( color: AppColors.darkGrey, fontSize: 14, height: 1.4 ), ), ), ], ), ), ); }
  Widget _buildLegendItem(Color color, String name) { /* Seu código aqui... */ return Row( mainAxisSize: MainAxisSize.min, children: [ Container( width: 12, height: 12, decoration: BoxDecoration( color: color, borderRadius: BorderRadius.circular(3), ), ), const SizedBox(width: 6), Text( name, style: AppTextStyles.smallText.copyWith(color: AppColors.darkGrey), ), ], ); }
  Widget _buildSummaryRow(String label, double value, Color valueColor) { /* Seu código aqui... */ return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(label, style: AppTextStyles.mediumText16w500.copyWith(color: AppColors.darkGrey)), Text( _currencyFormatter.format(value), style: AppTextStyles.mediumText16w600.copyWith(color: valueColor) ), ], ); }
  LineChartData _buildLineChartData() { /* Seu código aqui... */ Color balanceLineColor = _statsController.netBalance >= 0 ? AppColors.income : AppColors.outcome; return LineChartData( lineTouchData: LineTouchData( touchTooltipData: LineTouchTooltipData( getTooltipItems: (touchedSpots) { return touchedSpots.map((LineBarSpot touchedSpot) { return LineTooltipItem( 'Saldo: ${_currencyFormatter.format(touchedSpot.y)}', const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12,), ); }).toList(); }, ), handleBuiltInTouches: true, getTouchedSpotIndicator:(LineChartBarData barData, List<int> spotIndexes) { return spotIndexes.map((spotIndex) { return TouchedSpotIndicatorData( FlLine(color: balanceLineColor.withAlpha(150), strokeWidth: 2), FlDotData( show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: Colors.white, strokeWidth: 2, strokeColor: balanceLineColor), ), ); }).toList(); }, ), gridData: FlGridData( show: true, drawVerticalLine: false, horizontalInterval: _statsController.maxYValueForCharts > 0 ? (_statsController.maxYValueForCharts - _statsController.minYValueForBalanceChart).abs() / 4 : 1, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.lightGrey.withOpacity(0.1), strokeWidth: 1), ), titlesData: FlTitlesData( show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 30, interval: _statsController.interval, getTitlesWidget: (double value, TitleMeta meta) { String text; switch (_statsController.selectedPeriod) { case StatsPeriod.month: text = 'S${(value + 1).toInt()}'; break; case StatsPeriod.year: text = _statsController.monthName(value); break; default: text = ''; } return Text(text, style: AppTextStyles.smallText.copyWith(fontSize: 11, color: AppColors.grey)); }, ), ), leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 50, getTitlesWidget: (double value, TitleMeta meta) { if (value == meta.min || value == meta.max || (value > -0.01 && value < 0.01) ) { final String formattedValue = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0).format(value); return Text(formattedValue, style: AppTextStyles.smallText.copyWith(fontSize: 10, color: AppColors.grey)); } return const SizedBox.shrink(); }, ), ), ), borderData: FlBorderData(show: true, border: Border.all(color: AppColors.lightGrey.withOpacity(0.2), width: 1)), minX: _statsController.minX, maxX: _statsController.maxX, minY: _statsController.minYValueForBalanceChart, maxY: _statsController.maxYValueForCharts, lineBarsData: [ LineChartBarData( spots: _statsController.balanceSpots, isCurved: true, color: balanceLineColor, barWidth: 3.5, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData( show: true, gradient: LinearGradient( colors: [balanceLineColor.withAlpha(70), balanceLineColor.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter ) ), ), ], ); }
  BarChartData _buildBarChartData() { /* Seu código aqui... */ return BarChartData( alignment: BarChartAlignment.spaceAround, groupsSpace: 8, barTouchData: BarTouchData( touchTooltipData: BarTouchTooltipData( tooltipPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), tooltipMargin: 8, getTooltipItem: (group, groupIndex, rod, rodIndex) { String type = rodIndex == 0 ? 'Receita' : 'Despesa'; return BarTooltipItem( '$type\n', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), children: <TextSpan>[ TextSpan( text: _currencyFormatter.format(rod.toY), style: TextStyle( color: rod.color, fontSize: 13, fontWeight: FontWeight.w500,), ), ], ); }, ), touchCallback: (FlTouchEvent event, BarTouchResponse? response) {}, ), titlesData: FlTitlesData( show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 28, getTitlesWidget: (double value, TitleMeta meta) { String text; int index = value.toInt(); if (index < 0 || index >= _statsController.barGroups.length) return const SizedBox.shrink(); switch (_statsController.selectedPeriod) { case StatsPeriod.day: text = (index % 6 == 0) ? '${index}h' : ''; break; case StatsPeriod.week: text = _statsController.dayName(value); break; default: text = ''; } return Text(text, style: AppTextStyles.smallText.copyWith(fontSize: 10, color: AppColors.grey)); }, ), ), leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 40, getTitlesWidget: (double value, TitleMeta meta) { if (value == 0 || value == meta.max) { final String formattedValue = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0).format(value); return Text(formattedValue, style: AppTextStyles.smallText.copyWith(fontSize: 9, color: AppColors.grey)); } return const SizedBox.shrink(); }, ), ), ), gridData: FlGridData( show: true, drawVerticalLine: false, horizontalInterval: _statsController.maxYValueForCharts > 0 ? _statsController.maxYValueForCharts / 4 : 1, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.lightGrey.withOpacity(0.1), strokeWidth: 1), ), borderData: FlBorderData(show: false), barGroups: _statsController.barGroups, maxY: _statsController.maxYValueForCharts, minY: 0, ); }

} // Fim da classe _StatsPageState