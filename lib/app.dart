// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import necessário
// Seus imports (VERIFIQUE OS CAMINHOS):
import 'package:tcc_3/common/themes/default_theme.dart';
import 'package:tcc_3/features/home/home_page_view.dart';
import 'package:tcc_3/features/profile/profile_page.dart';
import 'package:tcc_3/features/sign_in/sign_in_page.dart';
import 'package:tcc_3/features/sign_up/sign_up_page.dart';
import 'package:tcc_3/features/splash/splash_page.dart';
import 'package:tcc_3/features/stats/stats_page.dart';
import 'package:tcc_3/features/transactions/transaction_page.dart'; // Import da TransactionPage
import 'package:tcc_3/common/models/models.dart'; // Para TransactionModel
import 'package:tcc_3/features/tools/view/budget_calculator_page.dart';
import 'package:tcc_3/features/tools/view/compound_interest_calculator_page.dart';
import 'package:tcc_3/features/tools/view/debt_impact_calculator_page.dart';
import 'package:tcc_3/features/tools/view/tools_page.dart';
import 'package:tcc_3/features/wallet/wallet_page.dart';
import 'common/constants/routes.dart'; // Seus nomes de rota (VERIFIQUE CAMINHO)
import 'features/onboarding/onboarding_page.dart'; // Sua OnboardingPage (VERIFIQUE CAMINHO)
// Remova o import do AuthWrapper se não estiver usando
// import 'auth_wrapper.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Configuração do GraphQLProvider (se era feita aqui originalmente)
    // final graphQLService = locator.get<GraphQLService>();
    // ValueNotifier<GraphQLClient> clientNotifier = ValueNotifier(graphQLService.client);

    return /* GraphQLProvider( // Descomente se usava aqui
      client: clientNotifier,
      child: */ MaterialApp(
        theme: CustomTheme().defaultTheme,
        // Versão "original" usava initialRoute:
        initialRoute: NamedRoute.splash,
        // e NÃO usava home: const AuthWrapper(),

        // Configurações de Localização
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'), // Português (Brasil)
          Locale('en', ''),    // Inglês
        ],

        // Mapa de Rotas original
        routes: {
          // Se tinha a rota initial aqui, mantenha como estava
          NamedRoute.initial: (context) => const OnboardingPage(),
          NamedRoute.splash: (context) => const SplashPage(),
          NamedRoute.signUp: (context) => const SignUpPage(),
          NamedRoute.signIn: (context) => const SignInPage(),
          NamedRoute.home: (context) => const HomePageView(),
          NamedRoute.stats: (context) => const StatsPage(),
          NamedRoute.wallet: (context) => const WalletPage(),
          NamedRoute.profile: (context) => const ProfilePage(),
          NamedRoute.transaction: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final transactionData = args is TransactionModel ? args : null;
            return TransactionPage(
              transaction: transactionData,
            );
          },
          NamedRoute.tools: (context) => const ToolsPage(),
          NamedRoute.debtCalculator: (context) => const DebtImpactCalculatorPage(),
          NamedRoute.compoundInterestCalculator: (context) => const CompoundInterestCalculatorPage(),
          NamedRoute.budgetCalculator: (context) => const BudgetCalculatorPage(),
        },
      // ), // Fecha GraphQLProvider se usava
    );
  }
}