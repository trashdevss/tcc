// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';


import 'package:flutter/material.dart';
import 'package:tcc_3/common/constants/routes.dart';
import 'package:tcc_3/common/utils/uppercase_text_formatter.dart';
import 'package:tcc_3/common/utils/validator.dart';
import 'package:tcc_3/common/widgets/custom_circular_progress_indicator.dart';
import 'package:tcc_3/common/widgets/password_form_field.dart';
import 'package:tcc_3/features/sign_up/sign_up_controller.dart';
import 'package:tcc_3/features/sign_up/sign_up_state.dart';
import 'package:tcc_3/locator.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_text_styles.dart';
import '../../common/widgets/custom_bottom_sheet.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/widgets/multi_text_button.dart';
import '../../common/widgets/primary_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with CustomModalSheetMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = locator.get<SignUpController>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(
      () {
        if (_controller.state is SignUpStateLoading) {
          showDialog(
            context: context,
            builder: (context) => const CustomCircularProgressIndicator(),
          );
        }
        if (_controller.state is SignUpStateSuccess) {
          Navigator.pop(context);

          Navigator.pushReplacementNamed(
            context,
            NamedRoute.home,
          );
        }

        if (_controller.state is SignUpStateError) {
          final error = _controller.state as SignUpStateError;
          Navigator.pop(context);
          showCustomModalBottomSheet(
            context: context,
            content: error.message,
            buttonText: "Tentar novamente",
          );
        }
      },
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                'Spend Smarter',
                textAlign: TextAlign.center,
                style: AppTextStyles.mediumText36.copyWith(
                  color: AppColors.greenOne,
                ),
              ),
              Text(
                'Save More',
                textAlign: TextAlign.center,
                style: AppTextStyles.mediumText36.copyWith(
                  color: AppColors.greenOne,
                ),
              ),
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/sign_up_image.png',
                height: 180, // Limita o tamanho da imagem
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextFormField(
                      controller: _nameController,
                      labelText: "your name",
                      hintText: "JOHN DOE",
                      inputFormatters: [UpperCaseTextInputFormatter()],
                      validator: Validator.validateName,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _emailController,
                      labelText: "your email",
                      hintText: "john@email.com",
                      validator: Validator.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    PasswordFormField(
                      controller: _passwordController,
                      labelText: "choose your password",
                      hintText: "*********",
                      validator: Validator.validatePassword,
                      helperText:
                          "Must have at least 8 characters, 1 capital letter and 1 number.",
                    ),
                    const SizedBox(height: 16),
                    PasswordFormField(
                      labelText: "confirm your password",
                      hintText: "*********",
                      validator: (value) => Validator.validateConfirmPassword(
                        _passwordController.text,
                        value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Sign Up',
                onPressed: () {
                  final valid = _formKey.currentState?.validate() ?? false;
                  if (valid) {
                    _controller.signUp(
                      name: _nameController.text,
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                  } else {
                    log("Erro ao cadastrar");
                  }
                },
              ),
              const SizedBox(height: 16),
              MultiTextButton(
                onPressed: () => Navigator.popAndPushNamed(
                  context,
                  NamedRoute.signIn,
                ),
                children: [
                  Text(
                    'Already have account? ',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    'Sign In ',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.greenOne,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}