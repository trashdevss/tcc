
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_3/common/constants/keys.dart';
import 'package:tcc_3/features/home/home_page_view.dart';
import 'package:tcc_3/features/onboarding/onboarding_page.dart';
import 'package:tcc_3/features/sign_in/sign_in_controller.dart';
import 'package:tcc_3/features/splash/splash_page.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/features/profile/profile_page.dart';

class LogoutRobot {
  const LogoutRobot({
    required this.email,
    required this.password,
  });
  // User email to inject before test
  final String email;

  // User password to inject before test
  final String password;

  Future<void> call(WidgetTester tester) async {
    await locator.get<SignInController>().signIn(
          email: email,
          password: password,
        );

    final splashPage = find.byType(SplashPage);
    await tester.pump();
    expect(splashPage, findsOneWidget);
    await tester.pumpAndSettle();

    final homePage = find.byType(HomePageView);
    expect(homePage, findsOneWidget);

    final profileButton = find.byKey(Keys.profilePageBottomAppBarItem);
    await tester.tap(profileButton);
    await tester.pumpAndSettle();

    final profilePage = find.byType(ProfilePage);
    expect(profilePage, findsOneWidget);

    final logoutButton = find.byKey(Keys.profilePagelogoutButton);
    expect(logoutButton, findsOneWidget);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    final signInPage = find.byType(OnboardingPage);
    expect(signInPage, findsOneWidget);
  }
}