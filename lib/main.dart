import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Imports para inicializações adicionais
import 'package:graphql_flutter/graphql_flutter.dart'; // Para initHiveForFlutter
import 'package:intl/date_symbol_data_local.dart'; // Para initializeDateFormatting

import 'app.dart'; // Seu widget App principal
import 'firebase_options.dart'; // Opções do Firebase geradas
import 'locator.dart'; // Configuração do GetIt

// +++ IMPORT DO SERVIÇO DE NOTIFICAÇÃO +++
import 'package:tcc_3/services/data_service/jove_notification_service.dart'; // Ajuste o caminho se necessário
// ++++++++++++++++++++++++++++++++++++++++

void main() async {
  // Garante que os bindings do Flutter estejam inicializados antes de qualquer chamada a plugins/Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa a formatação de datas para o local 'pt_BR'.
  // Necessário para que DateFormat funcione corretamente com 'pt_BR'.
  await initializeDateFormatting('pt_BR', null);

  // Inicializa o Hive para o cache do graphql_flutter, se você estiver usando.
  await initHiveForFlutter();

  // Configura suas dependências usando GetIt (locator).
  setupDependencies();

  // Espera que todas as dependências assíncronas registradas no GetIt
  // (como GraphQLService e DatabaseService) estejam prontas.
  await locator.allReady();

  // +++ INICIALIZA O SERVIÇO DE NOTIFICAÇÃO +++
  // Obtém a instância Singleton e chama o método de inicialização.
  // Isso deve ser feito após setupDependencies e allReady se o serviço
  // depender de algo registrado no locator, ou antes se for independente.
  // No nosso caso, JoveNotificationService usa o locator internamente,
  // então é seguro chamar após locator.allReady().
  // Se JoveNotificationService.initialize() não depender de nada do locator
  // que é async, poderia ser movido para antes de locator.allReady().
  // Para garantir, chamamos aqui.
  try {
    await JoveNotificationService().initialize();
    debugPrint("[main.dart] JoveNotificationService inicializado.");
    // Opcional: Iniciar o serviço de escuta aqui se a permissão já tiver sido dada
    // ou se você quiser que ele tente iniciar automaticamente.
    // bool hasPermission = await JoveNotificationService()._checkPermission(); // Se _checkPermission fosse público
    // if (hasPermission) {
    //   await JoveNotificationService().startService();
    // }
  } catch (e) {
    debugPrint("[main.dart] Erro ao inicializar JoveNotificationService: $e");
  }
  // +++++++++++++++++++++++++++++++++++++++++++++

  // Executa o seu widget App principal.
  runApp(const App());
}