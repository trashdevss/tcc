import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class CategoryIconHelper {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'house':
        return FontAwesomeIcons.house;
      case 'grocery':
        return FontAwesomeIcons.cartShopping;
      case 'services':
        return FontAwesomeIcons.briefcase;
      case 'investment':
        return FontAwesomeIcons.chartLine;
      case 'other':
        return FontAwesomeIcons.ellipsis;
      default:
        return FontAwesomeIcons.question;
    }
  }
}
