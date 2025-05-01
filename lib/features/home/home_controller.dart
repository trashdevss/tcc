import 'dart:convert'; // Para jsonDecode
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para rootBundle

// Seus imports existentes...
import '../../common/models/models.dart';
import '../../repositories/repositories.dart';
import '../../services/services.dart';
import 'home_state.dart';
import 'models/tip_model.dart'; // <<< IMPORTE O MODELO DA DICA

class HomeController extends ChangeNotifier {
  HomeController({
    required TransactionRepository transactionRepository,
    required UserDataService userDataService,
  })  : _userDataService = userDataService,
        _transactionRepository = transactionRepository;

  final TransactionRepository _transactionRepository;
  final UserDataService _userDataService;

  HomeState _state = HomeStateInitial();
  HomeState get state => _state;

  UserModel get userData => _userDataService.userData;

  late PageController _pageController;
  PageController get pageController => _pageController;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  // --- ADIÇÕES PARA AS DICAS ---
  List<TipModel> _tips = [];
  List<TipModel> get tips => _tips; // Getter para a View acessar

  bool _isLoadingTips = true;
  bool get isLoadingTips => _isLoadingTips; // Getter para a View acessar
  // -----------------------------

  set setPageController(PageController newPageController) {
    _pageController = newPageController;
  }

  void _changeState(HomeState newState) {
    // Apenas muda o estado principal se necessário,
    // a mudança das dicas pode notificar separadamente ou junto.
    if (_state != newState) {
        _state = newState;
    }
    notifyListeners(); // Notifica sobre qualquer mudança (estado principal ou dicas)
  }

  // --- MÉTODO PARA CARREGAR DICAS ---
  Future<void> loadTips() async {
    // Evita recarregar se já tiver carregado (opcional)
    // if (_tips.isNotEmpty) return;

    _isLoadingTips = true;
    notifyListeners(); // Notifica que o loading das dicas começou

    try {
      final String jsonString = await rootBundle.loadString('assets/json/tips.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<TipModel> loadedTips = jsonList
          .map((jsonItem) => TipModel.fromJson(jsonItem as Map<String, dynamic>))
          .toList();

       _tips = loadedTips;


    } catch (e) {
      print("Erro ao carregar dicas do asset: $e");
      _tips = []; // Limpa dicas em caso de erro
      // Você pode querer definir um estado de erro específico para as dicas aqui
      // ou apenas deixar a lista vazia.
    } finally {
       _isLoadingTips = false;
       notifyListeners(); // Notifica que o loading das dicas terminou (com sucesso ou erro)
    }
  }
  // ---------------------------------


  Future<void> getLatestTransactions() async {
    _changeState(HomeStateLoading()); // Pode manter o loading principal aqui
    // ... restante do método ...
     final result = await _transactionRepository.getLatestTransactions();
     result.fold(
       (error) => _changeState(HomeStateError(message: error.message)),
       (data) {
         _transactions = data;
         _changeState(HomeStateSuccess()); // Muda estado principal para sucesso
       },
     );
  }

  Future<void> getUserData() async {
     _changeState(HomeStateLoading());
     // ... restante do método ...
     final result = await _userDataService.getUserData();
     result.fold(
       (error) => _changeState(HomeStateError(message: error.message)),
       (data) => _changeState(HomeStateSuccess()),
     );
  }
}