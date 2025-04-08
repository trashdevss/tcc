import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/keys.dart';
import 'package:tcc_3/common/constants/routes.dart';
import 'package:tcc_3/common/utils/validator.dart';
import 'package:tcc_3/features/sign_in/sign_in_controller.dart';
import 'package:tcc_3/features/sign_in/sign_in_state.dart';
import 'package:tcc_3/locator.dart';
import '../../common/widgets/widgets.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with CustomModalSheetMixin<SignInPage> {
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
    _controller.addListener(_handleAuthState);
  }

  void _handleAuthState() {
    if (!mounted) return;

    if (_controller.state is SignInStateLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    } else {
      // Fecha diálogo de carregamento, se aberto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (_controller.state is SignInStateSuccess) {
        Navigator.pushReplacementNamed(context, NamedRoute.home);
      } else if (_controller.state is SignInStateError) {
        final state = _controller.state as SignInStateError;
        showCustomModalBottomSheet(
          context: context,
          content: state.message,
          buttonText: "Fechar",
        );
      }
    }
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
              Text(
                'Bem-Vinde de volta',
                textAlign: TextAlign.center,
                style: AppTextStyles.mediumText36.copyWith(
                  color: AppColors.greenOne,
                ),
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/sign_in_image.png',
                height: 180,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, size: 50, color: Colors.red);
                },
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CustomTextFormField(
                        hintText: "Digite seu email",
                        labelText: "Email",
                        controller: _emailController,
                        validator: Validator.validateEmail,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: PasswordFormField(
                        hintText: "Digite sua senha",
                        labelText: "Senha",
                        controller: _passwordController,
                        validator: Validator.validatePassword,
                        helperText: "Sua senha precisa de 8 caracteres, 1 letra maiúscula e 7 números",
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
                  text: 'Sign In',
                  onPressed: () {
                    final valid = _formKey.currentState?.validate();
                    log(valid.toString());
                    if (valid == true) {
                      _controller.signIn(
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
                onPressed: () => Navigator.pushNamed(context, NamedRoute.signUp),
                children: [
                  Text(
                    'Não tem uma conta? ',
                    style: AppTextStyles.smallText.copyWith(color: AppColors.grey),
                  ),
                  Text(
                    'Crie agora',
                    style: AppTextStyles.smallText.copyWith(color: AppColors.greenOne),
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
