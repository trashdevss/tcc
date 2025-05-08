import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para MethodChannel e PlatformException
// Certifique-se de que este caminho está correto e que NotificationEvent está definido aqui.
import 'package:tcc_3/common/models/notification_listener.dart';
// Certifique-se de que este caminho está correto para o seu JoveNotificationService.
import 'package:tcc_3/services/data_service/jove_notification_service.dart';


// Classe utilitária para interagir com o código nativo de permissões
class NotificationUtils {
  static const MethodChannel _methodChannel =
      MethodChannel('dev.gab.tcc/notifications_utils');

  static Future<bool> isNotificationServiceEnabled() async {
    try {
      final bool? isEnabled =
          await _methodChannel.invokeMethod('isNotificationServiceEnabled');
      return isEnabled ?? false;
    } on PlatformException catch (e) {
      print(
          "Erro ao verificar se o serviço de notificação está habilitado: ${e.message}");
      return false;
    }
  }

  static Future<void> requestNotificationPermissionScreen() async {
    try {
      await _methodChannel
          .invokeMethod('requestNotificationPermissionScreen');
    } on PlatformException catch (e) {
      print("Erro ao solicitar a tela de permissão de notificação: ${e.message}");
    }
  }
}

class NotificationDemoPage extends StatefulWidget {
  const NotificationDemoPage({super.key});

  @override
  State<NotificationDemoPage> createState() => _NotificationDemoPageState();
}

class _NotificationDemoPageState extends State<NotificationDemoPage> {
  List<NotificationEvent> _notifications = [];
  bool _isPermissionBeingChecked = false;
  String _permissionStatusMessage = "Verificando permissão...";

  @override
  void initState() {
    super.initState();
    _initializeServiceAndPermissions();

    JoveNotificationService.notificationStream.listen((event) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, event);
        });
      }
    }).onError((error) {
      print("Erro no stream de notificações: $error");
      if (mounted) {
        setState(() {
          _permissionStatusMessage = "Erro no stream: $error";
        });
      }
    });
  }

  Future<void> _initializeServiceAndPermissions() async {
    await _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!mounted) return;
    setState(() {
      _isPermissionBeingChecked = true;
      _permissionStatusMessage = "Verificando permissão de notificação...";
    });

    bool isEnabled = await NotificationUtils.isNotificationServiceEnabled();

    if (!mounted) return;

    if (isEnabled) {
      setState(() {
        _permissionStatusMessage = "Permissão de notificação concedida.";
        _isPermissionBeingChecked = false;
      });
      print("Serviço de notificação já está habilitado.");
    } else {
      setState(() {
        _permissionStatusMessage =
            "Permissão de notificação NÃO concedida. Clique no botão para solicitar.";
        _isPermissionBeingChecked = false;
      });
      print(
          "Serviço de notificação não está habilitado.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações Recebidas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Verificar Permissão Novamente",
            onPressed: _isPermissionBeingChecked ? null : _checkAndRequestPermissions,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(_permissionStatusMessage, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings_applications),
                  label: const Text('Abrir Config. de Permissão'),
                  onPressed: _isPermissionBeingChecked
                      ? null
                      : () async {
                          setState(() {
                            _permissionStatusMessage = "Abrindo tela de permissão...";
                          });
                          await NotificationUtils.requestNotificationPermissionScreen();
                          Future.delayed(const Duration(seconds: 2), () {
                            if(mounted) _checkAndRequestPermissions();
                          });
                        },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Text(
                      _isPermissionBeingChecked
                          ? "Aguardando status da permissão..."
                          : "Nenhuma notificação recebida ainda.\nVerifique as permissões e envie uma notificação de teste.",
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final event = _notifications[index];
                      return ListTile(
                        leading: const Icon(Icons.message),
                        title: Text(event.title), // Seu modelo tem 'title'
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.text), // Seu modelo tem 'text'
                            Text(
                              "Pacote: ${event.package}", // AJUSTADO: Usando event.package
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            // REMOVIDO: Exibição do timestamp, pois não está no seu modelo
                          ],
                        ),
                        // Ajustar isThreeLine se necessário, agora que uma linha foi removida
                        isThreeLine: false, // Pode ser false ou true dependendo do conteúdo
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
