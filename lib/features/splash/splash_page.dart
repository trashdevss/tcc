import 'package:flutter/material.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/routes.dart';
import 'package:tcc_3/common/extensions/sizes.dart';
import 'package:tcc_3/features/splash/splash_controller.dart';
import 'package:tcc_3/features/splash/splash_state.dart';
import 'package:tcc_3/locator.dart';
 
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _splashController = locator.get<SplashController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_)=> Sizes.init(context));


    _splashController.isUserLogged();
    _splashController.addListener(() {
      if (_splashController.state is AuthenticatedUser) {
        Navigator.pushReplacementNamed(context, NamedRoute.home);
      } else {
        Navigator.pushReplacementNamed(context, NamedRoute.initial);
      }
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.greenGradient,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.monetization_on,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              'JoveMoney',
              style: AppTextStyles.bigText50.copyWith(
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
