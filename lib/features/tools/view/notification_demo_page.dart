import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para MethodChannel e PlatformException
import 'dart:async'; // Para StreamSubscription e Future.delayed

// Importa AppNotificationEvent e ParsedFinancialTransaction, que são definidos
// dentro do arquivo jove_notification_service.dart (artefato jove_notification_service_corrected_for_user_v3)
import 'package:tcc_3/services/data_service/jove_notification_service.dart';


// Classe utilitária para interagir com o código nativo de permissões
class NotificationUtils {
  static const MethodChannel _methodChannel =
      MethodChannel('dev.gab.tcc/notifications_utils');

  static Future<bool> isNotificationServiceEnabled() async {
    try {
      final bool? isEnabled =
          await _methodChannel.invokeMethod('isNotificationServiceEnabled');
      debugPrint("NotificationUtils: isNotificationServiceEnabled retornou $isEnabled");
      return isEnabled ?? false;
    } on PlatformException catch (e) {
      debugPrint(
          "NotificationUtils Erro ao verificar se o serviço de notificação está habilitado: ${e.message}");
      return false;
    }
  }

  static Future<void> requestNotificationPermissionScreen() async {
    try {
      debugPrint("NotificationUtils: Enviando chamada requestNotificationPermissionScreen para o nativo...");
      await _methodChannel
          .invokeMethod('requestNotificationPermissionScreen');
      debugPrint("NotificationUtils: Chamada para requestNotificationPermissionScreen enviada.");
    } on PlatformException catch (e) {
      debugPrint("NotificationUtils Erro ao solicitar a tela de permissão de notificação: ${e.message}");
    }
  }
}

class NotificationDemoPage extends StatefulWidget {
  const NotificationDemoPage({super.key});

  @override
  State<NotificationDemoPage> createState() => _NotificationDemoPageState();
}

class _NotificationDemoPageState extends State<NotificationDemoPage> with WidgetsBindingObserver {
  // Obtém a instância Singleton do JoveNotificationService
  final JoveNotificationService _joveNotificationService = JoveNotificationService();

  // Lista para notificações brutas (AppNotificationEvent)
  final List<AppNotificationEvent> _rawNotifications = [];
  // Lista para transações financeiras parseadas (ParsedFinancialTransaction)
  final List<ParsedFinancialTransaction> _financialTransactions = [];

  StreamSubscription? _rawNotificationSubscription;
  StreamSubscription? _financialTransactionSubscription;

  bool _isPermissionBeingChecked = true;
  String _permissionStatusMessage = "Verificando permissão...";
  bool _hasServiceBeenInitialized = false;


  @override
  void initState() {
    super.initState();
    debugPrint("NotificationDemoPage: initState()");
    WidgetsBinding.instance.addObserver(this);

    // CORRIGIDO: Usa a instância _joveNotificationService para chamar initialize()
    _joveNotificationService.initialize().then((_) {
      debugPrint("NotificationDemoPage: JoveNotificationService.initialize() completado.");
      if (mounted) {
        setState(() {
          _hasServiceBeenInitialized = true;
        });
        // Após a inicialização do serviço, verifica e solicita permissões
        _checkAndRequestPermissions();
        // E também tenta iniciar o serviço de escuta do plugin
        // (startService tem sua própria verificação de permissão interna)
        _joveNotificationService.startService();
      }
    });

    // CORRIGIDO: Usa a instância _joveNotificationService para aceder ao stream
    _rawNotificationSubscription =
        _joveNotificationService.notificationStream.listen((event) { // event é AppNotificationEvent
      debugPrint("NotificationDemoPage: Evento BRUTO recebido: Titulo='${event.title}', Pacote='${event.packageName}'");
      if (mounted) {
        setState(() {
          _rawNotifications.insert(0, event);
        });
      }
    }, onError: (error) {
      debugPrint("NotificationDemoPage: Erro no stream de notificações BRUTAS: $error");
      if (mounted) {
        setState(() {
          _permissionStatusMessage = "Erro no stream de notificações brutas: $error";
        });
      }
    });

    // CORRIGIDO: Usa a instância _joveNotificationService para aceder ao stream
    _financialTransactionSubscription =
        _joveNotificationService.transactionStream.listen((transaction) { // transaction é ParsedFinancialTransaction
      debugPrint("NotificationDemoPage: Transação FINANCEIRA recebida: ${transaction.description} - ${transaction.amount}");
      if (mounted) {
        setState(() {
          _financialTransactions.insert(0, transaction);
        });
      }
    }, onError: (error) {
      debugPrint("NotificationDemoPage: Erro no stream de transações FINANCEIRAS: $error");
       if (mounted) {
        setState(() {
          _permissionStatusMessage = "Erro no stream de transações: $error";
        });
      }
    });
  }

  @override
  void dispose() {
    debugPrint("NotificationDemoPage: dispose()");
    WidgetsBinding.instance.removeObserver(this);
    _rawNotificationSubscription?.cancel();
    _financialTransactionSubscription?.cancel();
    // Chama o dispose do serviço para limpar recursos como ReceivePort e parar o serviço
    _joveNotificationService.dispose();
    super.dispose();
  }

  // Este método é chamado quando o estado do ciclo de vida do app muda
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint("NotificationDemoPage: didChangeAppLifecycleState - $state");
    if (state == AppLifecycleState.resumed) {
      debugPrint("NotificationDemoPage: App voltou ao primeiro plano (resumed). Re-verificando permissão e estado do serviço...");
      if (_hasServiceBeenInitialized) {
         _checkAndRequestPermissions(showRequestMessage: false);
         // Também é útil tentar iniciar o serviço novamente, pois ele pode ter sido parado
         _joveNotificationService.startService();
      }
    }
  }

  Future<void> _checkAndRequestPermissions({bool showRequestMessage = true}) async {
    if (!mounted || !_hasServiceBeenInitialized) {
      debugPrint("NotificationDemoPage: _checkAndRequestPermissions chamado mas widget não montado ou serviço não inicializado.");
      return;
    }

    debugPrint("NotificationDemoPage: Iniciando _checkAndRequestPermissions (showRequestMessage: $showRequestMessage)");
    setState(() {
      _isPermissionBeingChecked = true;
      _permissionStatusMessage = "Verificando permissão de notificação...";
    });

    // Usa NotificationUtils para verificar a permissão via MethodChannel (como no seu código original)
    bool isEnabled = await NotificationUtils.isNotificationServiceEnabled();
    debugPrint("NotificationDemoPage: Resultado de isNotificationServiceEnabled (via MethodChannel): $isEnabled");

    // Opcional: Pode também verificar usando o método do JoveNotificationService, que usa o plugin diretamente.
    // bool isEnabledByPlugin = await _joveNotificationService._checkPermission(); // Se _checkPermission fosse público
    // debugPrint("NotificationDemoPage: Permissão (Plugin): $isEnabledByPlugin");
    // bool finalIsEnabled = isEnabled && isEnabledByPlugin; // Ou apenas isEnabled se confiar no MethodChannel

    if (!mounted) return;

    if (isEnabled) {
      setState(() {
        _permissionStatusMessage = "Permissão de notificação CONCEDIDA.";
        _isPermissionBeingChecked = false;
      });
      debugPrint("NotificationDemoPage: Serviço de notificação está habilitado.");
      // Se a permissão está concedida, garante que o JoveNotificationService está a escutar
      _joveNotificationService.startService();
    } else {
      if (showRequestMessage) {
        setState(() {
          _permissionStatusMessage = "Permissão NÃO concedida. A solicitar...";
        });
        debugPrint("NotificationDemoPage: Serviço não habilitado. Solicitando permissão...");
        // Usa NotificationUtils para abrir a tela de permissões via MethodChannel
        await NotificationUtils.requestNotificationPermissionScreen();
         setState(() {
            _permissionStatusMessage = "Tentativa de abrir config. enviada. Verifique e retorne, ou clique 'Atualizar'.";
            _isPermissionBeingChecked = false;
        });
      } else {
         setState(() {
            _permissionStatusMessage = "Permissão NÃO concedida. Conceda nas config. ou clique 'Abrir Config.'";
            _isPermissionBeingChecked = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("NotificationDemoPage: build()");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações & Transações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Verificar Permissão Novamente",
            onPressed: (_isPermissionBeingChecked || !_hasServiceBeenInitialized)
                ? null
                : () => _checkAndRequestPermissions(showRequestMessage: true),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção de Status da Permissão e Botão
          if (!_hasServiceBeenInitialized)
            const Expanded(
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Inicializando serviço..."),
                ],
              )),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    _permissionStatusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: _permissionStatusMessage.contains("CONCEDIDA")
                            ? Colors.green.shade700
                            : Colors.orange.shade800),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings_applications),
                    label: const Text('Abrir Config. de Permissão'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                    onPressed: _isPermissionBeingChecked
                        ? null
                        : () async {
                            setState(() {
                              _isPermissionBeingChecked = true;
                              _permissionStatusMessage = "Abrindo tela de permissão...";
                            });
                            // Usa NotificationUtils para abrir a tela de permissões
                            await NotificationUtils.requestNotificationPermissionScreen();
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                setState(() {
                                  _permissionStatusMessage = "Verifique o status ou clique em Atualizar.";
                                  _isPermissionBeingChecked = false;
                                });
                              }
                            });
                          },
                  ),
                ],
              ),
            ),
          const Divider(thickness: 1),

          // Seção de Transações Financeiras Parseadas
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Transações Financeiras:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: _financialTransactions.isEmpty
                ? Center(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_isPermissionBeingChecked ? "Verificando..." : "Nenhuma transação financeira parseada ainda.", textAlign: TextAlign.center),
                ))
                : ListView.builder(
                    itemCount: _financialTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _financialTransactions[index]; // É ParsedFinancialTransaction
                      return Card(
                        color: transaction.type == TransactionType.income ? Colors.green.shade50 : Colors.red.shade50,
                        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(
                            transaction.type == TransactionType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: transaction.type == TransactionType.income ? Colors.green.shade700 : Colors.red.shade700,
                            size: 28,
                          ),
                          title: Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text("R\$ ${transaction.amount.toStringAsFixed(2)} (${transaction.originalPackageName.split('.').last}) - Cat: ${transaction.category}"),
                          trailing: Text(transaction.type.toString().split('.').last.capitalizeFirst()),
                        ),
                      );
                    },
                  ),
          ),

          // Seção de Todas as Notificações Recebidas (Brutas)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Todas Notificações (Brutas):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: _rawNotifications.isEmpty
                ? Center(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_isPermissionBeingChecked ? "Verificando..." : "Nenhuma notificação bruta recebida ainda.", textAlign: TextAlign.center),
                ))
                : ListView.builder(
                    itemCount: _rawNotifications.length,
                    itemBuilder: (context, index) {
                      final event = _rawNotifications[index]; // É AppNotificationEvent
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.notifications_none_outlined, color: Colors.blueGrey),
                          title: Text(event.title ?? "Sem Título"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.text ?? "Sem conteúdo"),
                              const SizedBox(height: 4),
                              Text("Pacote: ${event.packageName ?? "N/A"}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              Text("Recebida: ${event.timestamp.toLocal().toString().substring(0, 19)}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                           isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Simples extensão para capitalizar a primeira letra de uma string
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
