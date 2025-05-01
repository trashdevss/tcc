// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// +++ IMPORTS ADICIONADOS +++
import 'package:graphql_flutter/graphql_flutter.dart'; // Para initHiveForFlutter
import 'package:intl/date_symbol_data_local.dart'; // Para initializeDateFormatting
// +++++++++++++++++++++++++++

import 'app.dart';
import 'firebase_options.dart';
import 'locator.dart';

void main() async {
  // Garante inicialização do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // +++ INICIALIZAÇÃO DA FORMATAÇÃO DE DATAS (PT_BR) +++
  // (Necessário para DateFormat funcionar com 'pt_BR')
  await initializeDateFormatting('pt_BR', null);
  // ++++++++++++++++++++++++++++++++++++++++++++++++++++

  // +++ INICIALIZAÇÃO DO HIVE (Para GraphQL Cache) +++
  // (Se você usa graphql_flutter com cache Hive)
  await initHiveForFlutter();
  // ++++++++++++++++++++++++++++++++++++++++++++++++++

  // Configura suas dependências com GetIt
  setupDependencies();

  // Espera o GetIt ficar pronto (se tiver inicializações async nele)
  await locator.allReady();

  // Executa o App
  runApp(const App());
}