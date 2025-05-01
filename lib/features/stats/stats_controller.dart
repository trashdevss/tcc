// lib/features/stats/stats_controller.dart

import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tcc_3/common/extensions/date_formatter.dart';
import 'package:tcc_3/common/models/transaction_model.dart';
import 'package:tcc_3/repositories/transaction_repository.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'stats_state.dart';

// Enum para controlar o período principal da StatsPage (gráficos e lista)
enum StatsPeriod { day, week, month, year }

// +++ Enum para os presets do Relatório Detalhado +++
enum ReportPresetType { weekly, monthly, annual }

class LegendData {
  final String name;
  final double value;
  final double percentage;
  final Color color;
  LegendData({ required this.name, required this.value, required this.percentage, required this.color });
}

class StatsController extends ChangeNotifier {
  StatsController({ required TransactionRepository transactionRepository, }) : _transactionRepository = transactionRepository {
    // +++ Inicializa com o relatório mensal padrão +++
    _initializeDefaultReport();
  }
  final TransactionRepository _transactionRepository;

  // Formatadores
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _compactCurrencyFormatter = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

  // --- Estados e Dados Gerais da StatsPage (Gráficos Principais e Lista) ---
  // (Esta parte permanece a mesma, controlada pelas abas Day/Week/Month/Year)
  StatsState _state = StatsStateInitial();
  StatsState get state => _state;
  DateTime? _currentSummaryWeekStartDate;
  DateTime? get currentSummaryWeekStart => _currentSummaryWeekStartDate;
  List<StatsPeriod> get periods => StatsPeriod.values;
  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;
  List<BarChartGroupData> _barGroups = [];
  List<BarChartGroupData> get barGroups => _barGroups;
  List<FlSpot> _balanceSpots = [];
  List<FlSpot> get balanceSpots => _balanceSpots;
  double _maxYValueForCharts = 10.0;
  double get maxYValueForCharts => _maxYValueForCharts;
  double _minYValueForBalanceChart = 0.0;
  double get minYValueForBalanceChart => _minYValueForBalanceChart;
  double _totalIncome = 0.0;
  double get totalIncome => _totalIncome;
  double _totalExpense = 0.0;
  double get totalExpense => _totalExpense;
  double get netBalance => _totalIncome - _totalExpense;
  bool _sorted = false;
  bool get sorted => _sorted;
  StatsPeriod _selectedPeriod = StatsPeriod.month;
  StatsPeriod get selectedPeriod => _selectedPeriod;
  // ========================================================================

  // +++ ESTADO PARA O RELATÓRIO DETALHADO (Exibido na StatsPage) +++
  ReportPresetType? _selectedReportPreset = ReportPresetType.monthly; // Preset ativo (ou null se custom)
  ReportPresetType? get selectedReportPreset => _selectedReportPreset;

  DateTime _reportStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1); // Início do mês atual por padrão
  DateTime get reportStartDate => _reportStartDate;

  DateTime _reportEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59, 999); // Fim do mês atual por padrão
  DateTime get reportEndDate => _reportEndDate;

  // Dados UNIFICADOS para o relatório detalhado
  double _detailedReportIncome = 0.0;
  double get detailedReportIncome => _detailedReportIncome;
  double _detailedReportExpense = 0.0;
  double get detailedReportExpense => _detailedReportExpense;
  double get detailedReportNetBalance => _detailedReportIncome - _detailedReportExpense;
  Map<String, double> _detailedSpendingByCategory = {};
  Map<String, double> get detailedSpendingByCategoryRaw => _detailedSpendingByCategory;
  // Flag para indicar se os dados detalhados estão carregando/prontos
  bool _isDetailedReportLoading = true;
  bool get isDetailedReportLoading => _isDetailedReportLoading;
  // =================================================================

  // --- Métodos ---
  void _changeState(StatsState newState, {bool detailedLoading = false}) {
     _isDetailedReportLoading = detailedLoading; // Atualiza flag de loading detalhado
     if (_state.runtimeType != newState.runtimeType || _state != newState) {
        _state = newState;
        notifyListeners();
      } else {
        // Mesmo se o estado for o mesmo (ex: Success -> Success), notifica para atualizar a UI
        notifyListeners();
      }
  }

  // Ordena a lista de transações da StatsPage (não afeta relatório detalhado)
  void sortTransactions() {
     if (_state is StatsStateLoading) return; _sorted = !_sorted; if (_sorted) { _transactions.sort((a, b) => a.value.compareTo(b.value)); } else { _transactions.sort((a, b) => b.date.compareTo(a.date)); } if (_state is StatsStateSuccess) { notifyListeners(); }
   }

  // Busca dados para os GRÁFICOS PRINCIPAIS e LISTA da StatsPage
  Future<void> getTrasactionsByPeriod({ StatsPeriod? period, DateTime? referenceDate }) async {
    // ... (lógica existente SEM ALTERAÇÕES, continua atualizando _totalIncome, _totalExpense, _barGroups, _balanceSpots, _transactions) ...
     print("DEBUG CTL: getTrasactionsByPeriod INICIOU. Periodo: $period, Data Ref: $referenceDate"); _selectedPeriod = period ?? selectedPeriod; _changeState(StatsStateLoading()); DateTime baseDate = referenceDate ?? DateTime.now(); print("DEBUG CTL: Data base para cálculo: $baseDate"); DateTime start; DateTime end; _currentSummaryWeekStartDate = null; switch (selectedPeriod) { case StatsPeriod.day: start = DateTime(baseDate.year, baseDate.month, baseDate.day); end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); break; case StatsPeriod.week: int daysToSubtract = baseDate.weekday - DateTime.monday; if (daysToSubtract < 0) daysToSubtract += 7; start = baseDate.subtract(Duration(days: daysToSubtract)); start = DateTime(start.year, start.month, start.day); end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1)); _currentSummaryWeekStartDate = start; print("DEBUG CTL: Calculou intervalo da semana: $start até $end"); break; case StatsPeriod.month: start = DateTime(baseDate.year, baseDate.month, 1); end = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999); break; case StatsPeriod.year: start = DateTime(baseDate.year, 1, 1); end = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999); break; } if (kDebugMode) { print("[StatsController] Date Range: $start to $end"); } final result = await _transactionRepository.getTransactionsByDateRange(startDate: start, endDate: end); result.fold( (error) { print("DEBUG CTL: ERRO ao buscar transações: ${error.message}"); _transactions = []; _barGroups = []; _balanceSpots = []; _totalIncome = 0.0; _totalExpense = 0.0; _maxYValueForCharts = 10.0; _minYValueForBalanceChart = 0.0; _changeState(StatsStateError(error.message)); }, (data) { print("DEBUG CTL: SUCESSO ao buscar transações. ${data.length} itens encontrados."); data.sort((a, b) => a.date.compareTo(b.date)); List<TransactionModel> sortedForCalc = List.from(data); _transactions = List.from(data); _sorted = false; _totalIncome = data.where((t) => t.value >= 0).fold(0.0, (sum, t) => sum + t.value); _totalExpense = data.where((t) => t.value < 0).fold(0.0, (sum, t) => sum + t.value).abs(); _generateChartData(sortedForCalc); _transactions.sort((a, b) => b.date.compareTo(a.date)); _changeState(StatsStateSuccess()); }, ); print("DEBUG CTL: getTrasactionsByPeriod FIM.");
  }

  // +++ MÉTODO UNIFICADO PARA BUSCAR DADOS DO RELATÓRIO DETALHADO +++
  Future<void> getDetailedReportData({required DateTime startDate, required DateTime endDate}) async {
    print("DEBUG CTL: getDetailedReportData INICIOU for $startDate to $endDate");
    // Indica que os dados detalhados estão carregando, mas mantém o estado geral (Success)
    // para não exibir loading na tela inteira, apenas na seção do relatório.
    _changeState(_state, detailedLoading: true); // Mantém estado atual, mas ativa loading detalhado

    // Atualiza as datas no estado (importante para a UI exibir o range correto)
    _reportStartDate = startDate;
    _reportEndDate = endDate;

    final result = await _transactionRepository.getTransactionsByDateRange(startDate: startDate, endDate: endDate);

    result.fold(
      (error) {
        print("DEBUG CTL: ERRO ao buscar dados do relatório detalhado: ${error.message}");
        // Limpa os dados detalhados em caso de erro
        _detailedReportIncome = 0.0;
        _detailedReportExpense = 0.0;
        _detailedSpendingByCategory = {};
        // TODO: Considerar um estado de erro específico para o relatório detalhado?
        // Por ora, apenas paramos o loading detalhado e mantemos o estado geral.
         _changeState(StatsStateError("Erro ao carregar relatório detalhado: ${error.message}"), detailedLoading: false); // Sinaliza erro e para loading
      },
      (data) {
        print("DEBUG CTL: SUCESSO ao buscar dados do relatório detalhado. ${data.length} itens.");
        // Calcula os dados UNIFICADOS
        _detailedReportIncome = data.where((t) => t.value >= 0).fold(0.0, (sum, t) => sum + t.value);
        _detailedReportExpense = data.where((t) => t.value < 0).fold(0.0, (sum, t) => sum + t.value).abs();
        _detailedSpendingByCategory = {};
        final expenses = data.where((t) => t.value < 0).toList();
        if (expenses.isNotEmpty) {
          for (var exp in expenses) {
            String categoryName = exp.category ?? 'Sem Categoria';
            _detailedSpendingByCategory[categoryName] = (_detailedSpendingByCategory[categoryName] ?? 0.0) + exp.value.abs();
          }
        }
        // Mantém o estado geral (provavelmente Success) e indica que o loading detalhado acabou
        _changeState(_state, detailedLoading: false);
      },
    );
    print("DEBUG CTL: getDetailedReportData FIM.");
  }
  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // --- Métodos para Seleção de Período do Relatório Detalhado ---

  // Chamado pelos botões Semanal/Mensal/Anual
  Future<void> selectReportPreset(ReportPresetType preset) async {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (preset) {
      case ReportPresetType.weekly:
        int daysToSubtract = now.weekday - DateTime.monday;
        if (daysToSubtract < 0) daysToSubtract += 7;
        start = DateTime(now.year, now.month, now.day - daysToSubtract);
        end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        break;
      case ReportPresetType.monthly:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        break;
      case ReportPresetType.annual:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        break;
    }

    _selectedReportPreset = preset; // Atualiza o preset selecionado
    // Chama o método unificado de busca
    await getDetailedReportData(startDate: start, endDate: end);
  }

  // Chamado pelo seletor de intervalo de datas
  Future<void> selectCustomDateRange(DateTimeRange range) async {
    _selectedReportPreset = null; // Indica que não é mais um preset
    // Ajusta endDate para incluir o dia inteiro
    DateTime endDateAdjusted = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);
    // Chama o método unificado de busca
    await getDetailedReportData(startDate: range.start, endDate: endDateAdjusted);
  }

  // Método para inicialização padrão (chamado no construtor)
  void _initializeDefaultReport() {
    // Seleciona o preset mensal ao iniciar
    selectReportPreset(ReportPresetType.monthly);
  }
  // -------------------------------------------------------------

  // --- Getters para dados de Gráficos/Legendas do RELATÓRIO DETALHADO ---
  // (Usam as variáveis unificadas _detailed...)

  List<PieChartSectionData> get detailedPieChartSections {
    List<PieChartSectionData> sections = [];
    double totalSpent = _detailedReportExpense; // Usa dado unificado
    if (_detailedSpendingByCategory.isEmpty || totalSpent == 0) {
      return [ PieChartSectionData(value: 1, color: AppColors.grey.withOpacity(0.5), title: '', radius: 40)];
    }
    final sortedEntries = _detailedSpendingByCategory.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)); // Usa dado unificado
    int maxSectionsToShow = 5; double otherValue = 0; int sectionsCount = 0;
    final List<Color> pieColors = [ AppColors.outcome, Colors.orange.shade600, Colors.blue.shade600, Colors.purple.shade600, Colors.green.shade600, Colors.grey.shade600 ];

    for (var entry in sortedEntries) {
      if (sectionsCount < maxSectionsToShow) {
        final percentage = (entry.value / totalSpent) * 100;
        final String formattedValue = _compactCurrencyFormatter.format(entry.value);
        sections.add(PieChartSectionData(
          color: pieColors[sectionsCount % pieColors.length], value: entry.value,
          title: '${percentage.toStringAsFixed(0)}%\n$formattedValue', radius: 55,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]), ));
        sectionsCount++;
      } else { otherValue += entry.value; }
    }
    if (otherValue > 0.01) {
      final percentage = (otherValue / totalSpent) * 100;
      final String formattedOtherValue = _compactCurrencyFormatter.format(otherValue);
      sections.add(PieChartSectionData( color: pieColors.last, value: otherValue,
        title: '${percentage.toStringAsFixed(0)}%\n$formattedOtherValue', radius: 55,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]), ));
    } else if (sections.isEmpty && totalSpent > 0) {
       final String formattedTotalValue = _compactCurrencyFormatter.format(totalSpent);
       sections.add(PieChartSectionData(color: pieColors.last, value: totalSpent, title: '100%\n$formattedTotalValue', radius: 55, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]),));
    }
    return sections;
  }

  List<LegendData> get detailedLegendData {
     List<LegendData> legendItems = [];
     double totalSpent = _detailedReportExpense; // Usa dado unificado
     if (_detailedSpendingByCategory.isEmpty || totalSpent == 0) { return legendItems; }
     final sortedEntries = _detailedSpendingByCategory.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)); // Usa dado unificado
     int maxItemsToShow = 5; double otherValue = 0; int itemsCount = 0;
     final List<Color> pieColors = [ AppColors.outcome, Colors.orange.shade600, Colors.blue.shade600, Colors.purple.shade600, Colors.green.shade600, Colors.grey.shade600 ];
     for (var entry in sortedEntries) { if (itemsCount < maxItemsToShow) { final percentage = (entry.value / totalSpent) * 100; legendItems.add(LegendData( name: entry.key, value: entry.value, percentage: percentage, color: pieColors[itemsCount % pieColors.length] )); itemsCount++; } else { otherValue += entry.value; } } if (otherValue > 0.01) { final percentage = (otherValue / totalSpent) * 100; legendItems.add(LegendData( name: "Outros", value: otherValue, percentage: percentage, color: pieColors.last )); } else if (legendItems.isEmpty && totalSpent > 0) { legendItems.add(LegendData( name: "Outros", value: totalSpent, percentage: 100.0, color: pieColors.last)); } return legendItems;
  }

  // Getter de Dicas Financeiras (Usa dados unificados _detailed...)
  String getFinancialTip() { // Não precisa mais do parâmetro 'periodo'
    double netBalance = detailedReportNetBalance;
    double totalExpense = _detailedReportExpense;
    double totalIncomeValue = _detailedReportIncome;
    Map<String, double> spendingByCategory = _detailedSpendingByCategory;

    // Usa _currencyFormatter normal para as dicas
    final currencyFormat = _currencyFormatter;

    if (totalExpense <= 0 && totalIncomeValue <= 0) { return "Não houve movimentação no período selecionado para gerar dicas."; }
    if (netBalance < 0) { return "Atenção! Seu saldo ficou negativo em ${currencyFormat.format(netBalance.abs())} neste período. É um bom momento para rever seus gastos."; }
    if (totalExpense > 0 && spendingByCategory.isNotEmpty) {
      final sortedCategories = spendingByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)); final topCategory = sortedCategories.first; final topCategoryPercentage = totalExpense > 0 ? (topCategory.value / totalExpense) * 100 : 0;
      if (topCategoryPercentage > 35) { return "Seu maior gasto no período foi com ${topCategory.key} (${topCategoryPercentage.toStringAsFixed(0)}% do total). Fique de olho nessa categoria para possíveis otimizações!"; }
    }
    if (netBalance > 0) { return "Parabéns! Você economizou ${currencyFormat.format(netBalance)} neste período. Continue assim! Que tal definir uma meta para essa economia?"; }
    if (netBalance == 0 && totalExpense > 0) { return("Seu saldo ficou zerado neste período. Você conseguiu equilibrar as contas!"); }
    return "Continue acompanhando suas finanças! Analisar seus hábitos regularmente ajuda a manter o controle."; // Dica genérica
  }

  // --- Funções Helper e de Geração de Gráfico para StatsPage (Gráficos Principais) ---
  // (Estes métodos permanecem os mesmos, controlados por _selectedPeriod das ABAS)
  double get minX => 0; double get maxX { switch (selectedPeriod) { case StatsPeriod.day: return 23; case StatsPeriod.week: return 6; case StatsPeriod.month: try { return (DateTime.now().weeksInMonth - 1).toDouble(); } catch (_) { return 4; } case StatsPeriod.year: return 11; } } double get interval { switch (selectedPeriod) { case StatsPeriod.day: return 6; case StatsPeriod.week: return 1; case StatsPeriod.month: return 1; case StatsPeriod.year: return 2; } } String dayName(double day) { switch (day.toInt()) { case 0: return 'Seg'; case 1: return 'Ter'; case 2: return 'Qua'; case 3: return 'Qui'; case 4: return 'Sex'; case 5: return 'Sáb'; case 6: return 'Dom'; default: return ''; } } String monthName(double month) { switch (month.toInt()) { case 0: return 'Jan'; case 1: return 'Fev'; case 2: return 'Mar'; case 3: return 'Abr'; case 4: return 'Mai'; case 5: return 'Jun'; case 6: return 'Jul'; case 7: return 'Ago'; case 8: return 'Set'; case 9: return 'Out'; case 10: return 'Nov'; case 11: return 'Dez'; default: return ''; } } void _generateChartData(List<TransactionModel> sortedTransactions) { int groupingCount; bool Function(int, TransactionModel) groupingFunction; _maxYValueForCharts = 10.0; _minYValueForBalanceChart = 0.0; switch (selectedPeriod) { case StatsPeriod.day: groupingCount = 24; groupingFunction = _groupByHour; break; case StatsPeriod.week: groupingCount = 7; groupingFunction = _groupByDayOfWeek; break; case StatsPeriod.month: try { groupingCount = DateTime.now().weeksInMonth; } catch (_) { groupingCount = 5;} groupingFunction = _groupByWeekOfMonth; break; case StatsPeriod.year: groupingCount = 12; groupingFunction = _groupByMonth; break; } List<FlSpot> periodSpots = List.generate(groupingCount, (i) => FlSpot(i.toDouble(), 0)); final barData = <BarChartGroupData>[]; final balanceData = <FlSpot>[]; double currentRunningBalance = 0.0; if (kDebugMode) { print("[StatsController] Generating chart data for $groupingCount groups (Period: $selectedPeriod)..."); } for (int i = 0; i < groupingCount; i++) { final List<TransactionModel> transactionsInGroup = sortedTransactions.where((t) => groupingFunction(i, t)).toList(); final double totalIncomeGroup = transactionsInGroup.where((t) => t.value >= 0).fold(0.0, (prev, t) => prev + t.value); final double totalExpenseGroup = transactionsInGroup.where((t) => t.value < 0).fold(0.0, (prev, t) => prev + t.value).abs(); final double netChangeInGroup = totalIncomeGroup - totalExpenseGroup; currentRunningBalance += netChangeInGroup; balanceData.add(FlSpot(i.toDouble(), currentRunningBalance)); double maxAbsValueInPoint = max(totalIncomeGroup, totalExpenseGroup); if (currentRunningBalance.abs() > maxAbsValueInPoint) maxAbsValueInPoint = currentRunningBalance.abs(); if (maxAbsValueInPoint > _maxYValueForCharts) _maxYValueForCharts = maxAbsValueInPoint; if (currentRunningBalance < _minYValueForBalanceChart) _minYValueForBalanceChart = currentRunningBalance; barData.add( BarChartGroupData( x: i, barRods: [ BarChartRodData(toY: totalIncomeGroup, color: AppColors.income, width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))), BarChartRodData(toY: totalExpenseGroup, color: AppColors.outcome, width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))), ],),); } _barGroups = barData; _balanceSpots = balanceData; _maxYValueForCharts = _maxYValueForCharts > 0 ? _maxYValueForCharts * 1.15 : 10.0; _minYValueForBalanceChart = _minYValueForBalanceChart < -0.01 ? _minYValueForBalanceChart * 1.15 : (_maxYValueForCharts > 10 ? -_maxYValueForCharts * 0.05 : -1.0); if (kDebugMode) { print("[StatsController] Chart Data Generated: BarGroups=${_barGroups.length}, BalanceSpots=${_balanceSpots.length}, MaxY=$_maxYValueForCharts, MinYBalance=$_minYValueForBalanceChart"); } }
  bool _groupByHour(int hourIndex, TransactionModel t) { final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date); DateTime comparisonDate = _currentSummaryWeekStartDate ?? DateTime.now(); return transactionDate.year == comparisonDate.year && transactionDate.month == comparisonDate.month && transactionDate.day == comparisonDate.day && transactionDate.hour == hourIndex;} bool _groupByDayOfWeek(int dayIndex, TransactionModel t) { final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date); if (_currentSummaryWeekStartDate == null) return false; final weekEnd = _currentSummaryWeekStartDate!.add(const Duration(days: 7)); return (transactionDate.isAtSameMomentAs(_currentSummaryWeekStartDate!) || transactionDate.isAfter(_currentSummaryWeekStartDate!)) && transactionDate.isBefore(weekEnd) && transactionDate.weekday == (dayIndex + 1);} bool _groupByWeekOfMonth(int weekIndex, TransactionModel t) { final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date); DateTime comparisonDate = _currentSummaryWeekStartDate ?? DateTime.now(); if(transactionDate.month != comparisonDate.month || transactionDate.year != comparisonDate.year) { return false; } try { int weekInMonth = transactionDate.week; return (weekInMonth - 1) == weekIndex; } catch (e) { final dayOfMonth = transactionDate.day; int calculatedWeekIndex = (dayOfMonth - 1) ~/ 7; if (calculatedWeekIndex > 4) calculatedWeekIndex = 4; return calculatedWeekIndex == weekIndex; } } bool _groupByMonth(int monthIndex, TransactionModel t) { final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date); DateTime comparisonDate = _currentSummaryWeekStartDate ?? DateTime.now(); return transactionDate.year == comparisonDate.year && transactionDate.month == (monthIndex + 1);}

} // Fim da classe StatsController