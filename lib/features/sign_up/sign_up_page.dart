import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/keys.dart';
import 'package:tcc_3/common/constants/routes.dart';
import 'package:tcc_3/common/utils/uppercase_text_formatter.dart';
import 'package:tcc_3/common/utils/validator.dart';
import 'package:tcc_3/features/sign_up/sign_up_controller.dart';
import 'package:tcc_3/features/sign_up/sign_up_state.dart';
import 'package:tcc_3/locator.dart';
import '../../common/widgets/widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with CustomModalSheetMixin<SignUpPage> {
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
    // Removido `_controller.dispose();` pois provavelmente é singleton
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    if (!mounted) return;

    if (_controller.state is SignUpStateLoading) {
      _showLoadingDialog();
    } else {
      _closeDialog(); 
      if (_controller.state is SignUpStateSuccess) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, NamedRoute.home);
      } else if (_controller.state is SignUpStateError) {
        final errorMessage = (_controller.state as SignUpStateError).message;
        _showErrorModal(errorMessage);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede o usuário de fechar enquanto carrega
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _closeDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showErrorModal(String message) {
    showCustomModalBottomSheet(
      context: context,
      content: message, // Agora exibe a mensagem real do erro
      buttonText: "Fechar",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'Gaste de forma inteligente',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.mediumText36.copyWith(
                      color: AppColors.greenOne,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Economize mais',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.mediumText36.copyWith(
                      color: AppColors.greenOne,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/sign_up_image.png',
                height: 180,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CustomTextFormField(
                        hintText: "Gabriel Vinicius",
                        labelText: "Nome",
                        controller: _nameController,
                        inputFormatters: [
                          UpperCaseTextInputFormatter(),
                        ],
                        validator: Validator.validateName,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CustomTextFormField(
                        hintText: "gabriel@hotmail.com",
                        labelText: "Email",
                        controller: _emailController,
                        validator: Validator.validateEmail,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: PasswordFormField(
                        hintText: "Escolha sua senha",
                        labelText: "Senha",
                        controller: _passwordController,
                        validator: Validator.validatePassword,
                        helperText:
                            "Sua senha precisa de 8 caracteres, 1 letra maiúscula e 7 números",
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: PasswordFormField(
                        hintText: "Confirme sua senha",
                        labelText: "Confirmar Senha",
                        validator: (value) =>
                            Validator.validateConfirmPassword(
                                _passwordController.text, value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: PrimaryButton(
                  key: Keys.onboardingGetStartedButton,
                  text: 'Logue-se',
                  onPressed: () {
                    final valid = _formKey.currentState?.validate();
                    log(valid.toString());
                    if (valid == true) {
                      _controller.signUp(
                        name: _nameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                    } else {
                      log("Erro ao logar");
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              MultiTextButton(
                key: Keys.onboardingAlreadyHaveAccountButton,
                onPressed: () =>
                    Navigator.pushNamed(context, NamedRoute.signIn),
                children: [
                  Text(
                    'Ja tem uma conta? ',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    'Logue agora!',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.greenOne,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

