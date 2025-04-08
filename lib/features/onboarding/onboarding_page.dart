import 'package:flutter/material.dart';
import 'package:tcc_3/common/widgets/multi_text_button.dart';
import 'package:tcc_3/common/widgets/primary_button.dart';
 import '../../common/constants/constants.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      body: Column(
        children: [
          const SizedBox(height: 48.0),
          Expanded(
            child: Image.asset(
              'assets/images/onboarding_image.png',
            ),
          ),
          Text(
            'Gaste de Forma inteligente',
            textAlign: TextAlign.center,
            style: AppTextStyles.mediumText36.copyWith(
              color: AppColors.greenOne,
            ),
          ),
          Text(
            'Economize Mais',
            textAlign: TextAlign.center,
            style: AppTextStyles.mediumText36.copyWith(
              color: AppColors.greenOne,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: 16.0,
              bottom: 4.0,
            ),
            child: PrimaryButton(
              key: Keys.onboardingGetStartedButton,
              text: 'Comece Ja',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  NamedRoute.signUp,
                );
              },
            ),
          ),
          MultiTextButton(
            key: Keys.onboardingAlreadyHaveAccountButton,
            onPressed: () => Navigator.pushNamed(context, NamedRoute.signIn),
            children: [
              Text(
                'Ja tem uma conta ? ',
                style: AppTextStyles.smallText.copyWith(
                  color: AppColors.grey,
                ),
              ),
              Text(
                'Logue-se Agora ',
                style: AppTextStyles.smallText.copyWith(
                  color: AppColors.greenOne,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}
