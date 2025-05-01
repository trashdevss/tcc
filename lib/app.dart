// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tcc_3/features/ferramentas/budget_calculator_page.dart';
import 'package:tcc_3/features/ferramentas/compound_interest_calculator_page.dart';
import 'package:tcc_3/features/ferramentas/debt_impact_calculator_page.dart';
import 'package:tcc_3/features/ferramentas/tools_page.dart';
import 'package:tcc_3/features/metas/add_edit_goal_page.dart';
import 'package:tcc_3/features/metas/goal_model.dart';
import 'package:tcc_3/features/metas/goals_screen.dart';

// Imports principais de features (verifique os caminhos)
import 'package:tcc_3/features/transactions/transaction_page.dart';
import 'common/constants/constants.dart';
import 'common/models/models.dart';
import 'common/themes/default_theme.dart';
import 'features/home/home.dart';
import 'features/onboarding/onboarding.dart';
import 'features/profile/profile.dart';
import 'features/sign_in/sign_in.dart';
import 'features/sign_up/sign_up.dart';
import 'features/splash/splash.dart';
import 'features/stats/stats.dart';
import 'features/wallet/wallet.dart';

// Imports da Feature Tools

// +++ IMPORTS ADICIONADOS PARA METAS +++
// ++++++++++++++++++++++++++++++++++++++


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CustomTheme().defaultTheme,
      initialRoute: NamedRoute.splash, // Rota inicial

      // Configurações de Localização (Já ok)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', ''),
      ],
      // locale: const Locale('pt', 'BR'),

      // --- Mapa de Rotas Nomeadas ATUALIZADO ---
      routes: {
        // Rotas Auth/Onboarding
        NamedRoute.initial: (context) => const OnboardingPage(),
        NamedRoute.splash: (context) => const SplashPage(),
        NamedRoute.signUp: (context) => const SignUpPage(),
        NamedRoute.signIn: (context) => const SignInPage(),
        // NamedRoute.forgotPassword: (context) => const ForgotPasswordPage(),
        // NamedRoute.checkYourEmail: (context) => const CheckYourEmailPage(),

        // Rotas Principais (Abas)
        NamedRoute.home: (context) => const HomePageView(),
        NamedRoute.stats: (context) => const StatsPage(),
        NamedRoute.wallet: (context) => const WalletPage(),
        NamedRoute.profile: (context) => const ProfilePage(),
        NamedRoute.metas: (context) => const GoalsScreen(), // Rota para Tela de Metas

        // Rota de Transação
        NamedRoute.transaction: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final transactionData = args is TransactionModel ? args : null;
          return TransactionPage( transaction: transactionData, );
        },

        // Rotas de Ferramentas
        NamedRoute.tools: (context) => const ToolsPage(),
        NamedRoute.debtCalculator: (context) => const DebtImpactCalculatorPage(),
        NamedRoute.compoundInterestCalculator: (context) => const CompoundInterestCalculatorPage(),
        NamedRoute.budgetCalculator: (context) => const BudgetCalculatorPage(),

        // +++ ROTA ADICIONADA/CORRIGIDA PARA ADD/EDIT META +++
        NamedRoute.addEditGoal: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final goalToEdit = args is GoalModel ? args : null; // Verifica se recebeu uma meta para editar
          return AddEditGoalPage(goalToEdit: goalToEdit); // Passa a meta (ou null)
        },
        // ++++++++++++++++++++++++++++++++++++++++++++++++++

        // NamedRoute.graficos: (context) => const GraficosPage(), // Rota comentada pois não usamos
      },
    );
  }
}