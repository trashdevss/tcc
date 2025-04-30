import 'package:flutter/painting.dart';
// Se você usa AppColors aqui, adicione o import:
// import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle bigText50 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 50.0,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle mediumText36 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36.0,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle mediumText30 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 30.0,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle mediumText16w500 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle mediumText16w600 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle mediumText18 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle mediumText20 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );

  // === DEFINIÇÃO CORRETA PARA mediumText14 ADICIONADA ===
  static const TextStyle mediumText14 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Ajuste o fontWeight se necessário
  );
  // =====================================================

  static const TextStyle smallText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle smallText13 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle inputLabelText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle inputText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputHintText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
  );

  // === LINHA INCORRETA REMOVIDA ===
  // static var mediumText16;
  // ================================

} // Fim da classe AppTextStyles