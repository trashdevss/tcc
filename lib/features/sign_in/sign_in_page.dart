// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';


import 'package:flutter/material.dart';
import 'package:tcc_3/common/constants/routes.dart';
import 'package:tcc_3/common/utils/validator.dart';
import 'package:tcc_3/common/widgets/custom_circular_progress_indicator.dart';
import 'package:tcc_3/common/widgets/password_form_field.dart';
import 'package:tcc_3/locator.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_text_styles.dart';
import '../../common/widgets/custom_bottom_sheet.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/widgets/multi_text_button.dart';
import '../../common/widgets/primary_button.dart';
import 'sign_in_controller.dart';
import 'sign_in_state.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with CustomModalSheetMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = locator.get<SignInController>();

  @override
  void dispose() {
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
        if (_controller.state is SignInStateLoading) {
          showDialog(
            context: context,
            builder: (context) => const CustomCircularProgressIndicator(),
          );
        }
        if (_controller.state is SignInStateSuccess) {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(
            context,
            NamedRoute.home,
          );
        }

        if (_controller.state is SignInStateError) {
          final error = _controller.state as SignInStateError;
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
              const SizedBox(height: 32),
              Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: AppTextStyles.mediumText36.copyWith(
                  color: AppColors.greenOne,
                ),
              ),
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/sign_in_image.png',
                height: 180, // Limita o tamanho da imagem
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextFormField(
                      controller: _emailController,
                      labelText: "your email",
                      hintText: "john@email.com",
                      validator: Validator.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    PasswordFormField(
                      controller: _passwordController,
                      labelText: "your password",
                      hintText: "*********",
                      validator: Validator.validatePassword,
                      helperText:
                          "Must have at least 8 characters, 1 capital letter and 1 number.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Sign In',
                onPressed: () {
                  final valid = _formKey.currentState?.validate() ?? false;
                  if (valid) {
                    _controller.signIn(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                  } else {
                    log("erro ao logar");
                  }
                },
              ),
              const SizedBox(height: 16),
              MultiTextButton(
                onPressed: () => Navigator.popAndPushNamed(
                  context,
                  NamedRoute.signUp,
                ),
                children: [
                  Text(
                    'Don\'t have account? ',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    'Sign Up',
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