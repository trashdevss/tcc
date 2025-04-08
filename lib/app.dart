import 'package:flutter/material.dart';
import 'package:tcc_3/profile/profile_page.dart';
import 'package:tcc_3/wallet/wallet_page.dart';

import 'common/constants/routes.dart';
import 'common/models/transaction_model.dart';
import 'common/themes/default_theme.dart';
import 'features/home/home_page_view.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/sign_in/sign_in_page.dart';
import 'features/sign_up/sign_up_page.dart';
import 'features/splash/splash_page.dart';
import 'features/stats/stats_page.dart';
import 'features/transactions/transaction_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CustomTheme().defaultTheme,
      initialRoute: NamedRoute.splash,
      routes: {
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
          return TransactionPage(
            transaction: args != null ? args as TransactionModel : null,
          );
        },
      },
    );
  }
}