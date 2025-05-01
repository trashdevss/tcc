// lib/features/stats/stats_controller.dart

import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Seus imports existentes (ajuste se necessário)
// Certifique-se que 'date_formatter.dart' existe e define 'weeksInMonth' e 'week'
// Se não existir, pode ser necessário remover ou reimplementar essa lógica.
import 'package:tcc_3/common/extensions/date_formatter.dart';
import 'package:tcc_3/common/models/transaction_model.dart';
import 'package:tcc_3/repositories/transaction_repository.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'stats_state.dart'; // Seu state (Initial, Loading, Success, Error)

// Enums e Classe LegendData (mantidos como na versão anterior)
enum StatsPeriod { day, week, month, year }
enum ReportPresetType { weekly, monthly, annual }
class LegendData {
  final String name; final double value; final double percentage; final Color color;
  LegendData({ required this.name, required this.value, required this.percentage, required this.color });
}

class StatsController extends ChangeNotifier {
  StatsController({ required TransactionRepository transactionRepository, })
      : _transactionRepository = transactionRepository {
    _initializeDefaultReport();
  }
  final TransactionRepository _transactionRepository;

  // Formatadores
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _compactCurrencyFormatter = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

  // === ESTADO E DADOS PARA A PARTE SUPERIOR DA STATSPAGE ===
  StatsState _state = StatsStateInitial();
  StatsState get state => _state;
  StatsPeriod _selectedPeriod = StatsPeriod.month;
  StatsPeriod get selectedPeriod => _selectedPeriod;
  List<StatsPeriod> get periods => StatsPeriod.values;
  DateTime? _currentSummaryWeekStartDate;
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
  // ===========================================================

  // +++ ESTADO E DADOS PARA A SEÇÃO DO RELATÓRIO DETALHADO +++
  ReportPresetType? _selectedReportPreset = ReportPresetType.monthly;
  ReportPresetType? get selectedReportPreset => _selectedReportPreset;
  DateTime _reportStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get reportStartDate => _reportStartDate;
  DateTime _reportEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59, 999);
  DateTime get reportEndDate => _reportEndDate;
  double _detailedReportIncome = 0.0;
  double get detailedReportIncome => _detailedReportIncome;
  double _detailedReportExpense = 0.0;
  double get detailedReportExpense => _detailedReportExpense;
  double get detailedReportNetBalance => _detailedReportIncome - _detailedReportExpense; // Getter calculado
  Map<String, double> _detailedSpendingByCategory = {};
  Map<String, double> get detailedSpendingByCategoryRaw => _detailedSpendingByCategory;
  bool _isDetailedReportLoading = true;
  bool get isDetailedReportLoading => _isDetailedReportLoading;
  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // --- MÉTODOS ---

  void _changeState(StatsState newState, {bool detailedLoading = false}) {
      _isDetailedReportLoading = detailedLoading;
      // Apenas notifica se o estado realmente mudou ou se é um sucesso (para garantir refresh da UI)
      if (_state.runtimeType != newState.runtimeType || _state != newState || newState is StatsStateSuccess) {
         _state = newState;
         notifyListeners();
      }
  }

  void sortTransactions() {
     if (_state is StatsStateLoading) return;
     _sorted = !_sorted;
     if (_sorted) {
       _transactions.sort((a, b) => a.value.compareTo(b.value));
     } else {
       // Ordenação padrão por data decrescente (mais recente primeiro)
       _transactions.sort((a, b) => b.date.compareTo(a.date));
     }
     // Apenas notifica, não muda o estado geral
     notifyListeners();
   }


  Future<void> getTrasactionsByPeriod({ StatsPeriod? period, DateTime? referenceDate }) async {
    _selectedPeriod = period ?? _selectedPeriod; // Usa o novo período ou mantém o atual
    // Limpa dados antigos ANTES de iniciar o loading para evitar mostrar dados incorretos brevemente
    _barGroups = [];
    _balanceSpots = [];
    _transactions = []; // Limpa transações também
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _maxYValueForCharts = 10.0;
    _minYValueForBalanceChart = 0.0;

    _changeState(StatsStateLoading(), detailedLoading: _isDetailedReportLoading);

    DateTime baseDate = referenceDate ?? DateTime.now();
    DateTime start;
    DateTime end;
    _currentSummaryWeekStartDate = null; // Reseta data de início da semana

    switch (_selectedPeriod) {
      case StatsPeriod.day:
        start = DateTime(baseDate.year, baseDate.month, baseDate.day);
        end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case StatsPeriod.week:
        int daysToSubtract = baseDate.weekday - DateTime.monday;
        if (daysToSubtract < 0) daysToSubtract += 7;
        start = baseDate.subtract(Duration(days: daysToSubtract));
        start = DateTime(start.year, start.month, start.day); // Zera hora/min/seg
        end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        _currentSummaryWeekStartDate = start; // Guarda para cálculo do gráfico semanal
        break;
      case StatsPeriod.month:
        start = DateTime(baseDate.year, baseDate.month, 1);
        // Último dia do mês com hora final
        end = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
        break;
      case StatsPeriod.year:
        start = DateTime(baseDate.year, 1, 1);
        end = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
        break;
    }

    print("[StatsController] Fetching transactions for period: $_selectedPeriod ($start to $end)");

    final result = await _transactionRepository.getTransactionsByDateRange(startDate: start, endDate: end);

    result.fold(
      (error) {
        print("[StatsController] Error fetching transactions: ${error.message}");
        _transactions = [];
        _barGroups = [];
        _balanceSpots = [];
        _totalIncome = 0.0;
        _totalExpense = 0.0;
        _maxYValueForCharts = 10.0;
        _minYValueForBalanceChart = 0.0;
        _changeState(StatsStateError(message: error.message), detailedLoading: _isDetailedReportLoading);
      },
      (data) {
        print("[StatsController] Fetched ${data.length} transactions.");
        // Ordena por data ASCENDENTE para calcular corretamente o saldo acumulado
        List<TransactionModel> sortedForCalc = List.from(data)..sort((a, b) => a.date.compareTo(b.date));

        // Guarda a lista ordenada por data DESCENDENTE para exibição
        _transactions = List.from(data)..sort((a, b) => b.date.compareTo(a.date));
        _sorted = false; // Reseta ordenação da lista exibida

        _totalIncome = data.where((t) => t.value >= 0).fold(0.0, (sum, t) => sum + t.value);
        _totalExpense = data.where((t) => t.value < 0).fold(0.0, (sum, t) => sum + t.value).abs();

        // Gera os dados para os gráficos (barras e linha)
        _generateChartData(sortedForCalc); // Passa a lista ordenada por data crescente

        // Mantém estado de loading detalhado se ainda estiver carregando essa parte
        _changeState(StatsStateSuccess(), detailedLoading: _isDetailedReportLoading);
      },
    );
  }

  Future<void> getDetailedReportData({required DateTime startDate, required DateTime endDate}) async {
    print("[StatsController] getDetailedReportData: $startDate to $endDate");
    _isDetailedReportLoading = true;
    // Notifica ANTES da busca para mostrar loading apenas na seção detalhada
    // O estado geral (_state) não muda aqui ainda
    notifyListeners();

    _reportStartDate = startDate;
    _reportEndDate = endDate;

    final result = await _transactionRepository.getTransactionsByDateRange(startDate: startDate, endDate: endDate);

    result.fold(
      (error) {
        print("[StatsController] ERROR getDetailedReportData: ${error.message}");
        _detailedReportIncome = 0.0;
        _detailedReportExpense = 0.0;
        _detailedSpendingByCategory = {};
        // Define loading detalhado como false e muda estado GERAL para erro
        _changeState(StatsStateError(message: "Erro relatório: ${error.message}"), detailedLoading: false);
      },
      (data) {
        print("[StatsController] SUCCESS getDetailedReportData: ${data.length} items");
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
        // Define loading detalhado como false e garante estado GERAL como Success
        _changeState(StatsStateSuccess(), detailedLoading: false);
      },
    );
  }


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
     _selectedReportPreset = preset; // Guarda o preset selecionado
     await getDetailedReportData(startDate: start, endDate: end);
   }

  Future<void> selectCustomDateRange(DateTimeRange range) async {
    _selectedReportPreset = null; // Desmarca preset ao selecionar customizado
    // Ajusta fim do dia para incluir todas as transações do último dia
    DateTime endDateAdjusted = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);
    await getDetailedReportData(startDate: range.start, endDate: endDateAdjusted);
  }

  // Inicializa o relatório detalhado com o mês atual por padrão
  void _initializeDefaultReport() {
    // Chama assincronamente para não bloquear a construção inicial do controller
    Future.microtask(() => selectReportPreset(ReportPresetType.monthly));
  }


  // --- Getters para dados de Gráficos/Legendas do RELATÓRIO DETALHADO ---
  List<PieChartSectionData> get detailedPieChartSections { /* ... código sem alterações ... */ List<PieChartSectionData> sections = []; double totalSpent = _detailedReportExpense; if (_detailedSpendingByCategory.isEmpty || totalSpent == 0) { return [ PieChartSectionData(value: 1, color: AppColors.grey.withOpacity(0.5), title: '', radius: 40)]; } final sortedEntries = _detailedSpendingByCategory.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)); int maxSectionsToShow = 5; double otherValue = 0; int sectionsCount = 0; final List<Color> pieColors = [ AppColors.outcome, Colors.orange.shade600, Colors.blue.shade600, Colors.purple.shade600, Colors.green.shade600, Colors.grey.shade600 ]; for (var entry in sortedEntries) { if (sectionsCount < maxSectionsToShow) { final percentage = (entry.value / totalSpent) * 100; final String formattedValue = _compactCurrencyFormatter.format(entry.value); sections.add(PieChartSectionData( color: pieColors[sectionsCount % pieColors.length], value: entry.value, title: '${percentage.toStringAsFixed(0)}%\n$formattedValue', radius: 55, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]), )); sectionsCount++; } else { otherValue += entry.value; } } if (otherValue > 0.01) { final percentage = (otherValue / totalSpent) * 100; final String formattedOtherValue = _compactCurrencyFormatter.format(otherValue); sections.add(PieChartSectionData( color: pieColors.last, value: otherValue, title: '${percentage.toStringAsFixed(0)}%\n$formattedOtherValue', radius: 55, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]), )); } else if (sections.isEmpty && totalSpent > 0) { final String formattedTotalValue = _compactCurrencyFormatter.format(totalSpent); sections.add(PieChartSectionData(color: pieColors.last, value: totalSpent, title: '100%\n$formattedTotalValue', radius: 55, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]),)); } return sections; }
  List<LegendData> get detailedLegendData { /* ... código sem alterações ... */ List<LegendData> legendItems = []; double totalSpent = _detailedReportExpense; if (_detailedSpendingByCategory.isEmpty || totalSpent == 0) { return legendItems; } final sortedEntries = _detailedSpendingByCategory.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)); int maxItemsToShow = 5; double otherValue = 0; int itemsCount = 0; final List<Color> pieColors = [ AppColors.outcome, Colors.orange.shade600, Colors.blue.shade600, Colors.purple.shade600, Colors.green.shade600, Colors.grey.shade600 ]; for (var entry in sortedEntries) { if (itemsCount < maxItemsToShow) { final percentage = (entry.value / totalSpent) * 100; legendItems.add(LegendData( name: entry.key, value: entry.value, percentage: percentage, color: pieColors[itemsCount % pieColors.length] )); itemsCount++; } else { otherValue += entry.value; } } if (otherValue > 0.01) { final percentage = (otherValue / totalSpent) * 100; legendItems.add(LegendData( name: "Outros", value: otherValue, percentage: percentage, color: pieColors.last )); } else if (legendItems.isEmpty && totalSpent > 0) { legendItems.add(LegendData( name: "Outros", value: totalSpent, percentage: 100.0, color: pieColors.last)); } return legendItems; }

  // Getter de Dicas Financeiras
  String getFinancialTip() {
    double netBalance = detailedReportNetBalance;
    double totalExpense = _detailedReportExpense;
    double totalIncomeValue = _detailedReportIncome;
    Map<String, double> spendingByCategory = _detailedSpendingByCategory;
    final currencyFormat = _currencyFormatter;

    if (totalExpense <= 0 && totalIncomeValue <= 0) { return "Não houve movimentação no período selecionado para gerar dicas."; }
    if (netBalance < 0) { return "Atenção! Seu saldo ficou negativo em ${currencyFormat.format(netBalance.abs())} neste período. É um bom momento para rever seus gastos."; }
    if (totalExpense > 0 && spendingByCategory.isNotEmpty) {
      try { // Adiciona try-catch para segurança na ordenação
          final sortedCategories = spendingByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          if (sortedCategories.isNotEmpty) {
             final topCategory = sortedCategories.first;
             final topCategoryPercentage = totalExpense > 0 ? (topCategory.value / totalExpense) * 100 : 0;
             if (topCategoryPercentage > 35) {
                return "Seu maior gasto no período foi com ${topCategory.key} (${topCategoryPercentage.toStringAsFixed(0)}% do total). Fique de olho nessa categoria para possíveis otimizações!";
             }
          }
      } catch (e) {
         print("Erro ao processar categorias para dica: $e");
      }
    }
    if (netBalance > 0) { return "Parabéns! Você economizou ${currencyFormat.format(netBalance)} neste período. Continue assim! Que tal definir uma meta para essa economia?"; }
    if (netBalance == 0 && totalExpense > 0) { return("Seu saldo ficou zerado neste período. Você conseguiu equilibrar as contas!"); }
    return "Continue acompanhando suas finanças! Analisar seus hábitos regularmente ajuda a manter o controle.";
  }

  // --- Funções Helper e de Geração de Gráfico para StatsPage (Gráficos Principais) ---
  double get minX => 0;
  double get maxX {
     switch (selectedPeriod) {
       case StatsPeriod.day: return 23; // 0 a 23 horas
       case StatsPeriod.week: return 6;  // 0 (Seg) a 6 (Dom)
       case StatsPeriod.month:
         try {
           // Calcula semanas baseado no início da semana atual (se disponível)
           // ou usa um valor padrão como 4 ou 5.
           // A lógica original com DateTime.now().weeksInMonth pode ser instável.
           // Uma abordagem mais segura seria calcular baseado nas datas start/end do mês.
           // Por simplicidade, vamos usar um valor fixo, ajuste se necessário.
           final endOfMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
           return (endOfMonth.day / 7).ceil().toDouble() - 1; // Estimativa de semanas (0 a N-1)

         } catch (_) { return 4; } // Fallback para 5 semanas (índice 0 a 4)
       case StatsPeriod.year: return 11; // 0 (Jan) a 11 (Dez)
     }
   }

  double get interval {
    switch (selectedPeriod) {
      case StatsPeriod.day: return 6;  // Marca a cada 6 horas
      case StatsPeriod.week: return 1;  // Marca todo dia
      case StatsPeriod.month: return 1; // Marca toda semana
      case StatsPeriod.year: return 2;  // Marca a cada 2 meses
    }
  }

  String dayName(double day) { /* ... */ switch (day.toInt()) { case 0: return 'Seg'; case 1: return 'Ter'; case 2: return 'Qua'; case 3: return 'Qui'; case 4: return 'Sex'; case 5: return 'Sáb'; case 6: return 'Dom'; default: return ''; } }
  String monthName(double month) { /* ... */ switch (month.toInt()) { case 0: return 'Jan'; case 1: return 'Fev'; case 2: return 'Mar'; case 3: return 'Abr'; case 4: return 'Mai'; case 5: return 'Jun'; case 6: return 'Jul'; case 7: return 'Ago'; case 8: return 'Set'; case 9: return 'Out'; case 10: return 'Nov'; case 11: return 'Dez'; default: return ''; } }

  // <<< FUNÇÃO COM PRINTS PARA DEBUG >>>
  void _generateChartData(List<TransactionModel> sortedTransactions) {
    int groupingCount;
    bool Function(int, TransactionModel) groupingFunction;
    // Zera os dados antes de calcular novamente (boa prática)
    _barGroups = [];
    _balanceSpots = [];
    _maxYValueForCharts = 10.0; // Reinicia max Y (considera zero se não houver transações)
    _minYValueForBalanceChart = 0.0; // Reinicia min Y

    switch (selectedPeriod) {
      case StatsPeriod.day: groupingCount = 24; groupingFunction = _groupByHour; break;
      case StatsPeriod.week: groupingCount = 7; groupingFunction = _groupByDayOfWeek; break;
      case StatsPeriod.month:
          final endOfMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
          groupingCount = (endOfMonth.day / 7).ceil(); // Calcula semanas no mês atual
          groupingFunction = _groupByWeekOfMonth;
          break;
      case StatsPeriod.year: groupingCount = 12; groupingFunction = _groupByMonth; break;
    }

    // Listas temporárias para construir os dados
    final barData = <BarChartGroupData>[];
    final balanceData = <FlSpot>[]; // << Usar esta lista temporária
    double currentRunningBalance = 0.0; // Saldo acumulado começa em zero

    // <<< PRINT 1: Verificando dados de entrada >>>
    print("[StatsController] Generating chart data for $groupingCount groups (Period: $selectedPeriod). Input transactions: ${sortedTransactions.length}");

    for (int i = 0; i < groupingCount; i++) {
      final List<TransactionModel> transactionsInGroup = sortedTransactions.where((t) => groupingFunction(i, t)).toList();
      final double totalIncomeGroup = transactionsInGroup.where((t) => t.value >= 0).fold(0.0, (prev, t) => prev + t.value);
      final double totalExpenseGroup = transactionsInGroup.where((t) => t.value < 0).fold(0.0, (prev, t) => prev + t.value).abs();
      final double netChangeInGroup = totalIncomeGroup - totalExpenseGroup;

      currentRunningBalance += netChangeInGroup; // Atualiza saldo acumulado

      // <<< PRINT 2: Verificando cálculo de cada ponto >>>
      print("  Group $i: Income=${totalIncomeGroup.toStringAsFixed(2)}, Expense=${totalExpenseGroup.toStringAsFixed(2)}, Net=${netChangeInGroup.toStringAsFixed(2)}, Balance=${currentRunningBalance.toStringAsFixed(2)}");

      balanceData.add(FlSpot(i.toDouble(), currentRunningBalance));
      // <<< PRINT 3: Verificando o ponto adicionado >>>
      print("    Added balance spot: ${balanceData.last}");

      // Cálculo de maxY/minY (ajustado para considerar saldo)
      double maxAbsValueInPoint = max(totalIncomeGroup, totalExpenseGroup);
      if (currentRunningBalance.abs() > maxAbsValueInPoint) maxAbsValueInPoint = currentRunningBalance.abs();

      // Atualiza o Máximo Y geral (para barras ou linha)
      if (maxAbsValueInPoint > _maxYValueForCharts) _maxYValueForCharts = maxAbsValueInPoint;
      // Atualiza o Mínimo Y apenas para o gráfico de linha (saldo)
      if (currentRunningBalance < _minYValueForBalanceChart) _minYValueForBalanceChart = currentRunningBalance;

      // Adiciona dados para gráfico de barras (mesmo que não seja usado, para consistência)
      barData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: totalIncomeGroup, color: AppColors.income, width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
            BarChartRodData(toY: totalExpenseGroup, color: AppColors.outcome, width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          ],
        ),
      );
    }

    // Atribui os resultados às variáveis do controller
    _barGroups = barData;
    _balanceSpots = balanceData; // <<< Atribui a lista construída

    // Ajusta limites do eixo Y para dar uma margem
    _maxYValueForCharts = _maxYValueForCharts > 0 ? _maxYValueForCharts * 1.15 : 10.0; // Margem superior ou 10 se for 0
    _minYValueForBalanceChart = _minYValueForBalanceChart < -0.01
        ? _minYValueForBalanceChart * 1.15 // Margem inferior se negativo
        : (_maxYValueForCharts > 10 ? -_maxYValueForCharts * 0.05 : -1.0); // Pequena margem negativa se saldo for sempre >= 0

    // <<< PRINT 4: Verificando dados finais >>>
    print("[StatsController] Chart Data Generated: BarGroups=${_barGroups.length}, BalanceSpots=${_balanceSpots.length}, MaxY=$_maxYValueForCharts, MinYBalance=$_minYValueForBalanceChart");
    print("[StatsController] Final Balance Spots: $_balanceSpots");
  }


  // Funções de agrupamento (sem alterações internas, apenas checando uso)
  bool _groupByHour(int hourIndex, TransactionModel t) {
     final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date);
     // Assume que getTransactionsByPeriod já filtrou pelo dia correto
     return transactionDate.hour == hourIndex;
  }

  bool _groupByDayOfWeek(int dayIndex, TransactionModel t) {
    final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date);
    // Note: DateTime.monday = 1, ..., DateTime.sunday = 7
    // dayIndex vai de 0 (Seg) a 6 (Dom)
    return transactionDate.weekday == (dayIndex + 1);
  }

  // Função _groupByWeekOfMonth precisa de cuidado especial ou uma biblioteca
  // A implementação anterior usando `date_formatter.dart` pode ser a fonte do erro
  // se essa extensão não estiver correta ou disponível.
  // Usando uma lógica mais simples baseada no dia do mês como fallback:
  bool _groupByWeekOfMonth(int weekIndex, TransactionModel t) {
    final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date);
    // Cálculo simples: divide o mês em semanas de 7 dias.
    // Dia 1-7 = Semana 0, Dia 8-14 = Semana 1, etc.
    int calculatedWeekIndex = (transactionDate.day - 1) ~/ 7;
    // Garante que não exceda o número máximo de grupos esperado (ex: 4 para um mês de 5 semanas no gráfico 0 a 4)
    int maxWeekIndex = 4; // Ajuste se seu groupingCount for diferente
    if (calculatedWeekIndex > maxWeekIndex) calculatedWeekIndex = maxWeekIndex;
    return calculatedWeekIndex == weekIndex;
    /*
    // Implementação anterior que dependia da extensão 'week'
    try {
       // Garanta que a extensão 'week' calcule a semana corretamente (1 a 5/6)
       int weekInMonth = transactionDate.week; // << PRECISA DESSA EXTENSÃO
       return (weekInMonth - 1) == weekIndex; // Ajusta para índice 0-based
    } catch (e) {
       print("Erro ao usar extensão 'week' em date_formatter: $e. Usando fallback.");
       // Fallback simples (pode não ser preciso para todos os meses)
       final dayOfMonth = transactionDate.day;
       int calculatedWeekIndex = (dayOfMonth - 1) ~/ 7;
       // Ajusta se o cálculo resultar em índice maior que o esperado (ex: 5 semanas)
       int maxExpectedIndex = 4; // Assumindo 5 semanas máx (índice 0-4)
       if (calculatedWeekIndex > maxExpectedIndex) calculatedWeekIndex = maxExpectedIndex;
       return calculatedWeekIndex == weekIndex;
    }
    */
  }

  bool _groupByMonth(int monthIndex, TransactionModel t) {
    final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date);
    // monthIndex vai de 0 (Jan) a 11 (Dez)
    // transactionDate.month vai de 1 (Jan) a 12 (Dez)
    return transactionDate.month == (monthIndex + 1);
  }

} // Fim da classe StatsController