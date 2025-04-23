import 'package:flutter/material.dart';
import 'package:tcc_3/locator.dart';
import 'package:tcc_3/services/user_data_service/user_data_service.dart';

import '../constants/constants.dart';
import '../extensions/extensions.dart';

class GreetingsWidget extends StatelessWidget {
  const GreetingsWidget({
    super.key,
  });

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 18) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    double textScaleFactor =
        MediaQuery.of(context).size.width < 360 ? 0.7 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          textScaleFactor: textScaleFactor,
          style: AppTextStyles.smallText.apply(color: AppColors.white),
        ),
        Text(
          (locator.get<UserDataService>().userData.name ?? '')
              .capitalize()
              .firstWord,
          textScaleFactor: textScaleFactor,
          style: AppTextStyles.mediumText20.apply(color: AppColors.white),
        ),
      ],
    );
  }
}