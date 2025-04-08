import 'package:flutter/material.dart';
import '../constants/constants.dart';

class GreetingsWidget extends StatelessWidget {
  const GreetingsWidget({
    super.key,
  });

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Bom dia,';
    } else if (hour < 18) {
      return 'Boa Tarde,';
    } else {
      return 'Boa noite,';
    }
  }

  @override
  Widget build(BuildContext context) {
    double textScaleFactor = MediaQuery.sizeOf(context).width < 360 ? 0.7 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          textScaler: TextScaler.linear(textScaleFactor),
          style: AppTextStyles.smallText.apply(color: AppColors.white),
        ),
      ],
    );
  }
}