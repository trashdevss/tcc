import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
// Seus imports
import 'package:tcc_3/common/models/transaction_model.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/repositories/transaction_repository.dart';
import 'package:tcc_3/services/auth_service/auth_service.dart';

@pragma('vm:entry-point')
class JoveNotificationService {
  static final JoveNotificationService _instance = JoveNotificationService._internal();
  
  @pragma('vm:entry-point')
  factory JoveNotificationService() => _instance;
  
  @pragma('vm:entry-point')
  JoveNotificationService._internal();

  final StreamController<AppNotificationEvent> _notificationController = 
      StreamController<AppNotificationEvent>.broadcast();
  final StreamController<ParsedFinancialTransaction> _transactionController =
      StreamController<ParsedFinancialTransaction>.broadcast();

  @pragma('vm:entry-point')
  Stream<AppNotificationEvent> get notificationStream => _notificationController.stream;
  
  @pragma('vm:entry-point')
  Stream<ParsedFinancialTransaction> get transactionStream => _transactionController.stream;

  bool _isRunning = false;
  bool _isInitialized = false;
  ReceivePort? _receivePort;
  static const String _picpayPackageName = "com.picpay";
  static const String _nubankPackageName = "com.nu.production";
  static const String _interPackageName = "br.com.intermedium";
  // static const String _btgPackageName = "com.btgpactual.banking"; 

  final TransactionRepository _transactionRepo = locator<TransactionRepository>();
  final AuthService _authService = locator<AuthService>();

  @pragma('vm:entry-point')
  static void _notificationCallback(NotificationEvent event) {
    debugPrint("[Plugin Raw Event] Pkg: ${event.packageName}, Title: ${event.title}, Text: ${event.text}, CreateAt: ${event.createAt}, ID: ${event.id}");
    final SendPort? send = IsolateNameServer.lookupPortByName("_jove_notification_listener_");
    send?.send(event);
  }

  @pragma('vm:entry-point')
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      NotificationsListener.initialize(callbackHandle: _notificationCallback);
      _receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping("_jove_notification_listener_");
      IsolateNameServer.registerPortWithName(_receivePort!.sendPort, "_jove_notification_listener_");
      _receivePort?.listen((message) {
        if (message is NotificationEvent) {
          _handleNotification(message);
        }
      });
      _isInitialized = true;
      debugPrint("[JoveNotificationService] Initialized successfully");
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Initialization error: $e\n$stack");
      _isInitialized = false;
    }
  }

  @pragma('vm:entry-point')
  void _handleNotification(NotificationEvent event) {
    debugPrint("[_handleNotification] Handling Plugin Event: Pkg='${event.packageName}', Title='${event.title}', Text='${event.text}'");
    try {
      final appEvent = AppNotificationEvent.fromPluginEvent(event);
      if (!_notificationController.isClosed) _notificationController.add(appEvent);
      
      if (event.packageName == _picpayPackageName || 
          event.packageName == _nubankPackageName ||
          event.packageName == _interPackageName) {
        _processFinancialNotification(appEvent);
      }
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error handling notification: $e\n$stack");
    }
  }

  @pragma('vm:entry-point')
  Future<void> startService() async {
    if (_isRunning) return;
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        debugPrint("[JoveNotificationService] No notification permission");
        await requestPermission();
        return;
      }
      await NotificationsListener.startService(
        foreground: true,
        title: "Monitor de Finanças Jove",
        description: "Analisando transações financeiras",
      );
      _isRunning = true;
      debugPrint("[JoveNotificationService] Service started");
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error starting service: $e\n$stack");
      _isRunning = false;
    }
  }

  @pragma('vm:entry-point')
  Future<void> stopService() async {
    if (!_isRunning) return;
    try {
      await NotificationsListener.stopService();
      _isRunning = false;
      debugPrint("[JoveNotificationService] Service stopped");
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error stopping service: $e\n$stack");
    }
  }

  @pragma('vm:entry-point')
  Future<bool> _checkPermission() async {
    try {
      final hasPermission = await NotificationsListener.hasPermission;
      return hasPermission ?? false;
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Permission check error: $e\n$stack");
      return false;
    }
  }

  @pragma('vm:entry-point')
  Future<void> requestPermission() async {
    try {
      await NotificationsListener.openPermissionSettings();
      debugPrint("[JoveNotificationService] Opened permission settings");
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error opening settings: $e\n$stack");
    }
  }

  @pragma('vm:entry-point')
  void _processFinancialNotification(AppNotificationEvent event) {
    debugPrint("[_processFinancialNotification] Processing: Pkg='${event.packageName}', Title='${event.title}', Text='${event.text}'");
    try {
      final parsed = _parseTransaction(event);
      if (parsed == null) {
        debugPrint("[_processFinancialNotification] Failed to parse: Title='${event.title}', Text='${event.text}'");
        return;
      }
      debugPrint("[_processFinancialNotification] Parsed: Amount=${parsed.amount}, Type=${parsed.type}, Desc=${parsed.description}, Cat=${parsed.category}");

      final userId = _authService.currentUserId;
      if (userId == null || userId.isEmpty) {
        debugPrint("[JoveNotificationService] User not authenticated");
        return;
      }

      final transaction = TransactionModel(
        description: parsed.description,
        value: parsed.type == TransactionType.income ? parsed.amount : -parsed.amount,
        category: parsed.category,
        date: parsed.originalNotificationTimestamp,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: true,
        userId: userId,
      );

      _transactionRepo.addTransaction(
        transaction: transaction,
        userId: userId,
      ).then((result) { 
        debugPrint("[JoveNotificationService THEN] Callback do addTransaction alcançado.");
        debugPrint("[JoveNotificationService THEN] Objeto result completo: ${result.toString()}");
        debugPrint("[JoveNotificationService THEN] result.isSuccess: ${result.isSuccess}"); 
        debugPrint("[JoveNotificationService THEN] _transactionController.isClosed: ${_transactionController.isClosed}");
        
        if (result.isSuccess && !_transactionController.isClosed) { 
          _transactionController.add(parsed);
          debugPrint("[JoveNotificationService] Transaction EMITTED to stream: ${parsed.description}");
        } else {
          String reason = "";
          if (!result.isSuccess) {
            reason += "Condição de sucesso NÃO atendida (result.isSuccess era false). ";
            reason += "Erro reportado (se houver): ${result.error?.toString()}. "; 
          }
          if (_transactionController.isClosed) {
            reason += "_transactionController estava fechado.";
          }
          debugPrint("[JoveNotificationService] FALHA ao emitir transação para o stream. Razão: $reason");
        }
      }).catchError((e, stack) {
        debugPrint("[JoveNotificationService] EXCEÇÃO no _transactionRepo.addTransaction: $e\n$stack");
      });
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error processing financial notification: $e\n$stack");
    }
  }

  @pragma('vm:entry-point')
  ParsedFinancialTransaction? _parseTransaction(AppNotificationEvent event) {
    // ... (código _parseTransaction mantido como na última versão) ...
    try {
      final fullText = "${event.title ?? ''} ${event.text ?? ''}".trim();
      if (fullText.isEmpty) {
        debugPrint("[_parseTransaction] fullText is empty.");
        return null;
      }
      debugPrint("[_parseTransaction] fullText for parsing: $fullText");

      final amount = _parseAmount(fullText);
      debugPrint("[_parseTransaction] Parsed Amount: $amount");
      if (amount == null || amount == 0) return null;

      final type = _determineType(fullText, event.packageName);
      debugPrint("[_parseTransaction] Determined Type: $type");
      if (type == TransactionType.unknown) return null;

      final description = _extractDescription(fullText, type, event.packageName);
      debugPrint("[_parseTransaction] Extracted Description: $description");
      
      final category = _determineCategory(fullText, type, event.packageName);
      debugPrint("[_parseTransaction] Determined Category: $category");

      return ParsedFinancialTransaction(
        amount: amount,
        type: type,
        description: description,
        originalNotificationTimestamp: event.timestamp.millisecondsSinceEpoch,
        originalPackageName: event.packageName ?? _picpayPackageName,
        originalTitle: event.title,
        originalText: event.text,
        category: category,
      );
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error parsing transaction: $e\n$stack");
      return null;
    }
  }

  @pragma('vm:entry-point')
  double? _parseAmount(String text) {
    // ... (código _parseAmount mantido) ...
    try {
      final match = RegExp(r"(?:R\$\s?)?(\d{1,3}(?:\.\d{3})*,\d{2})").firstMatch(text);
      if (match == null) return null;
      final value = match.group(1)?.replaceAll(".", "").replaceAll(",", ".");
      return double.tryParse(value ?? "0");
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error parsing amount from '$text': $e\n$stack");
      return null;
    }
  }

  @pragma('vm:entry-point')
  TransactionType _determineType(String text, String? packageName) {
    // ... (código _determineType com lógica para Inter, Nubank, PicPay mantido) ...
    try {
      final lowerText = text.toLowerCase();
      debugPrint("[_determineType] Text: '$lowerText', Pkg: '$packageName'");

      if (packageName == _nubankPackageName) {
        if (lowerText.contains('transferência recebida') ||       
            lowerText.contains('recebemos sua transferência de') ||
            lowerText.contains('recebeu uma transferência de') || 
            lowerText.contains('pix recebido') ||                   
            lowerText.contains("você recebeu de")) {                
          return TransactionType.income;
        } else if (lowerText.contains('compra aprovada') || 
                   lowerText.contains('transferência enviada') ||
                   lowerText.contains("pagamento de boleto efetuado")) { 
          return TransactionType.expense;
        }
      } else if (packageName == _picpayPackageName) {
        if (lowerText.contains("você recebeu um pix de") || lowerText.contains("você recebeu de")) {
          return TransactionType.income;
        } else if (lowerText.contains("você pagou a") || lowerText.contains("pix enviado para")) {
          return TransactionType.expense;
        }
      } else if (packageName == _interPackageName) { 
        if (lowerText.contains("pix enviado") ||
            lowerText.contains("você fez um pix") ||
            lowerText.contains("pagamento realizado") ||
            lowerText.contains("compra aprovada")) { 
          debugPrint("[_determineType] Determined as EXPENSE (Inter)");
          return TransactionType.expense;
        } else if (lowerText.startsWith("pix recebido") || 
                   lowerText.contains("crédito em conta") ||
                   lowerText.contains("você recebeu um pix")) { 
          debugPrint("[_determineType] Determined as INCOME (Inter)");
          return TransactionType.income;
        }
      }

      if (lowerText.contains("pagamento realizado") || 
          lowerText.contains("você pagou") ||
          lowerText.contains("compra aprovada")) {
        return TransactionType.expense;
      } else if (lowerText.contains("você recebeu") || 
                 lowerText.contains("recebeu um pix") ||
                 lowerText.contains("transferência recebida")) { 
        return TransactionType.income;
      }
      debugPrint("[_determineType] Type UNKNOWN for text: '$lowerText'");
      return TransactionType.unknown;
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error determining type: $e\n$stack");
      return TransactionType.unknown;
    }
  }

  @pragma('vm:entry-point')
  String _extractDescription(String text, TransactionType type, String? packageName) {
    // ... (código _extractDescription com lógica para Inter, Nubank, PicPay mantido) ...
    try {
      final lowerText = text.toLowerCase();
      
      if (packageName == _nubankPackageName) {
        if (type == TransactionType.income) {
          if (lowerText.contains("você recebeu de ")) {
            final senderName = _extractBetween(text, "você recebeu de ", ".")
              .split(' via ')[0].split(' pelo ')[0].trim();
            return "Pix recebido de $senderName";
          } else if (lowerText.startsWith("transferência recebida")) { 
            return "Transferência recebida"; 
          }
          return "Entrada Nubank"; 
        } else if (type == TransactionType.expense) {
          if (lowerText.contains("compra aprovada em ")) {
             final storeMatch = RegExp(r'compra aprovada em\s*(.+?)\.', caseSensitive: false).firstMatch(text);
             if (storeMatch != null && storeMatch.group(1) != null) {
                return 'Compra em ${storeMatch.group(1)!.trim()}';
             }
            return "Compra aprovada";
          } else if (lowerText.contains("você pagou a conta de ")) { 
             return _extractBetween(text, "Você pagou a conta de ", " no valor de");
          } else if (lowerText.contains("transferência enviada para ")) {
             final recipientMatch = RegExp(r'transferência enviada para\s*(.+?)\.', caseSensitive: false).firstMatch(text);
             if (recipientMatch != null && recipientMatch.group(1) != null) {
                return 'Transferência enviada para ${recipientMatch.group(1)!.trim()}';
             }
             return "Transferência enviada";
          }
          return "Saída Nubank"; 
        }
      } else if (packageName == _picpayPackageName) {
        if (type == TransactionType.income && (lowerText.contains("você recebeu um pix") || lowerText.contains("você recebeu de"))) {
            final match = RegExp(r'(?:você recebeu um pix de|você recebeu de)\s*(.*?)(?:\.|$|,| no valor)', caseSensitive: false).firstMatch(text);
            if (match != null && match.group(1) != null && match.group(1)!.isNotEmpty) {
                return "Pix recebido de ${match.group(1)!.trim()}";
            }
          return "Pix recebido (PicPay)";
        } else if (type == TransactionType.expense && lowerText.contains("você pagou a ")) {
          return _extractBetween(text, "você pagou a ", " no valor");
        } else if (type == TransactionType.expense && lowerText.contains("pix enviado para")) {
           final recipientMatch = RegExp(r'Pix enviado para\s*(.*?)(?:\s*no valor de|\.|$)', caseSensitive: false).firstMatch(text);
           if (recipientMatch != null && recipientMatch.group(1) != null) {
              return "Pix enviado para ${recipientMatch.group(1)!.trim()}";
           }
           return "Pix enviado (PicPay)";
        }
      } else if (packageName == _interPackageName) {
        if (type == TransactionType.expense) {
          if (lowerText.contains("você fez um pix") && lowerText.contains("para ")) {
            final recipientMatch = RegExp(r'para\s+(.*?)\.', caseSensitive: false).firstMatch(text);
            if (recipientMatch != null && recipientMatch.group(1) != null) {
              return "Pix para ${recipientMatch.group(1)!.trim()}";
            }
            return "Pix enviado (Inter)";
          }
        } else if (type == TransactionType.income) {
          if (lowerText.startsWith("pix recebido") && lowerText.contains("te enviou um pix")) {
            final senderMatch = RegExp(r'pix recebido\s+(.*?)\s+te enviou um pix', caseSensitive: false).firstMatch(text);
            if (senderMatch != null && senderMatch.group(1) != null && senderMatch.group(1)!.isNotEmpty) {
              return "Pix de ${senderMatch.group(1)!.trim()}";
            }
            return "Pix recebido (Inter)"; 
          }
        }
      }
      
      if (type == TransactionType.expense) {
        if (lowerText.contains("você pagou a ")) {
          return _extractBetween(text, "você pagou a ", " no valor");
        } else if (lowerText.contains("compra aprovada em ")) {
          return _extractBetween(text, "compra aprovada em ", " no valor");
        }
      } else if (type == TransactionType.income) {
        if (lowerText.contains("você recebeu de ")) {
          final senderName = _extractBetween(text, "você recebeu de ", ".");
          return "Recebido de $senderName";
        } else if (lowerText.contains("você recebeu")) {
          return "Valor recebido";
        }
      }
      return text.length > 50 ? "${text.substring(0, 50)}..." : text;
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error extracting description: $e\n$stack");
      return text;
    }
  }

  @pragma('vm:entry-point')
  String _extractBetween(String text, String start, String end) {
    // ... (código _extractBetween mantido) ...
    try {
      final lowerText = text.toLowerCase();
      final lowerStart = start.toLowerCase();
      final lowerEnd = end.toLowerCase();
      final startIndexActual = lowerText.indexOf(lowerStart);
      if (startIndexActual == -1) return text; 
      final startIndexContent = startIndexActual + lowerStart.length;
      final endIndexActual = lowerText.indexOf(lowerEnd, startIndexContent);
      if (endIndexActual == -1) { 
        return text.substring(startIndexContent).trim();
      }
      return text.substring(startIndexContent, endIndexActual).trim();
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error extracting between '$start' and '$end' from '$text': $e\n$stack");
      return text;
    }
  }

  @pragma('vm:entry-point')
  String _determineCategory(String text, TransactionType type, String? packageName) {
    // ... (código _determineCategory com lógica para Inter, Nubank, PicPay mantido) ...
    try {
      final lowerText = text.toLowerCase();
      debugPrint("[_determineCategory] Text: '$lowerText', Pkg: '$packageName', Type: '$type'");

      if (packageName == _nubankPackageName) {
        if (lowerText.contains("pix")) return "Transferencia Pix"; 
        if (lowerText.contains("transferência recebida")) return "Receita";
        if (lowerText.contains("transferência enviada")) return "Transferência Enviada";
        if (lowerText.contains("compra aprovada")) {
            if (lowerText.contains("ifood")) return "Alimentação";
            if (lowerText.contains("uber")) return "Transporte";
            return "Compra Cartão";
        }
        if (lowerText.contains("pagamento de boleto")) return "Pagamento de Contas";
      } else if (packageName == _picpayPackageName) {
        if (lowerText.contains("pix")) return "Transferencia Pix";
      } else if (packageName == _interPackageName) { 
        if (lowerText.contains("pix enviado") || lowerText.contains("você fez um pix")) {
          return "Transferencia Pix"; 
        }
        if (lowerText.contains("pix recebido")) { 
          return "Transferencia Pix"; 
        }
      }

      const categories = {
        'ifood': 'Alimentação', 'restaurante': 'Alimentação', 'mercado': 'Supermercado',
        'uber': 'Transporte', '99': 'Transporte', 'gasolina': 'Transporte', 'táxi': 'Transporte',
        'farmácia': 'Saúde', 'drogaria': 'Saúde', 'padaria': 'Alimentação',
        'aluguel': 'Moradia', 'condomínio': 'Moradia',
        'salário': 'Salário', 'rendimento': 'Rendimentos',
      };
      for (final entry in categories.entries) {
        if (lowerText.contains(entry.key)) return entry.value;
      }

      if (type == TransactionType.income) return "Outras Receitas";
      if (type == TransactionType.expense) return "Outras Despesas";
      
      return "Outros";
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error determining category: $e\n$stack");
      return "Outros";
    }
  }

  @pragma('vm:entry-point')
  Future<void> dispose() async {
    // ... (código do dispose mantido) ...
    try {
      await stopService();
      _receivePort?.close();
      IsolateNameServer.removePortNameMapping("_jove_notification_listener_");
      if (!_notificationController.isClosed) _notificationController.close();
      if (!_transactionController.isClosed) _transactionController.close();
      _isInitialized = false;
      _isRunning = false;
      debugPrint("[JoveNotificationService] Disposed successfully");
    } catch (e, stack) {
      debugPrint("[JoveNotificationService] Error disposing: $e\n$stack");
    }
  }

  // --- MÉTODOS DE TESTE ADICIONADOS ---
  void processSimulatedAppEventForTesting(AppNotificationEvent appEvent) {
    debugPrint("[SIMULATION] processSimulatedAppEventForTesting called with Pkg: ${appEvent.packageName}, Title: ${appEvent.title}, Text: ${appEvent.text}");
    if (appEvent.packageName == _picpayPackageName ||
        appEvent.packageName == _nubankPackageName ||
        appEvent.packageName == _interPackageName) {
      _processFinancialNotification(appEvent);
    } else {
      debugPrint("[SIMULATION] Package ${appEvent.packageName} is not targeted for financial processing.");
    }
  }

  void testParseInterPixEnviado() {
    debugPrint("--- SIMULANDO NOTIFICAÇÃO INTER: PIX ENVIADO ---");
    final simulatedAppEvent = AppNotificationEvent(
      packageName: _interPackageName,
      title: "Pix enviado",
      text: "Você fez um Pix no valor de R\$ 1,00 para Gabriel Vinicius Antunes.",
      id: 77701, 
      timestamp: DateTime.now(),
    );
    processSimulatedAppEventForTesting(simulatedAppEvent);
    debugPrint("--- FIM DA SIMULAÇÃO INTER: PIX ENVIADO ---");
  }

  void testParseInterPixRecebido() {
    debugPrint("--- SIMULANDO NOTIFICAÇÃO INTER: PIX RECEBIDO ---");
    final simulatedAppEvent = AppNotificationEvent(
      packageName: _interPackageName,
      title: "Pix recebido",
      text: "Gabriel Vinicius Antunes te enviou um Pix de R\$ 1,00 creditado na sua conta final ***23241-3.",
      id: 77702,
      timestamp: DateTime.now(),
    );
    processSimulatedAppEventForTesting(simulatedAppEvent);
    debugPrint("--- FIM DA SIMULAÇÃO INTER: PIX RECEBIDO ---");
  }
  // --- FIM DOS MÉTODOS DE TESTE ---

} // Fim da classe JoveNotificationService

// --- Classes AppNotificationEvent, TransactionType, ParsedFinancialTransaction mantidas como estavam ---
@pragma('vm:entry-point')
class AppNotificationEvent {
  final String? title;
  final String? text;
  final String? packageName;
  final int? id;
  final DateTime timestamp;

  @pragma('vm:entry-point')
  AppNotificationEvent({
    this.title,
    this.text,
    this.packageName,
    this.id,
    required this.timestamp,
  });

  @pragma('vm:entry-point')
  factory AppNotificationEvent.fromPluginEvent(NotificationEvent event) {
    try {
      return AppNotificationEvent(
        title: event.title,
        text: event.text,
        packageName: event.packageName,
        id: event.id,
        timestamp: event.createAt ?? DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint("[AppNotificationEvent] Error creating from plugin event: $e\n$stack");
      return AppNotificationEvent( 
        title: event.title,
        text: event.text,
        packageName: event.packageName,
        id: event.id,
        timestamp: DateTime.now(),
      );
    }
  }
}

@pragma('vm:entry-point')
enum TransactionType { income, expense, unknown }

@pragma('vm:entry-point')
class ParsedFinancialTransaction {
  final double amount;
  final TransactionType type;
  final String description;
  final int originalNotificationTimestamp; 
  final String originalPackageName;
  final String? originalTitle;
  final String? originalText;
  final String category;

  @pragma('vm:entry-point')
  ParsedFinancialTransaction({
    required this.amount,
    required this.type,
    required this.description,
    required this.originalNotificationTimestamp,
    required this.originalPackageName,
    this.originalTitle,
    this.originalText,
    this.category = "Outros",
  });

  @pragma('vm:entry-point')
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(originalNotificationTimestamp);
}

enum SyncStatus { initial, create, update, delete, synced, error }

// Lembre-se da sua classe Result e Failure
/*
abstract class Result<T> {
  bool get isSuccess; 
  Failure? get error; // Supondo que Failure seja sua classe de erro
  T? get data;
}
// ... e suas implementações SuccessResult e ErrorResult ...
// class Failure { ... }
*/