// Dentro da sua classe NamedRoute em lib/common/constants/routes.dart

class NamedRoute {
  NamedRoute._();

  // --- Rotas Principais e de Autenticação ---
  static const String initial = "/";
  static const String splash = "/splash";
  static const String onboarding = "/onboarding";
  static const String signUp = "/sign_up";
  static const String signIn = "/sign_in";
  static const String forgotPassword = "/forgot-password";
  static const String checkYourEmail = "/check-your-email";

  // --- Rotas das Abas Principais ---
  static const String home = "/home";
  static const String stats = "/stats";
  static const String metas = "/metas"; // Rota para GoalsScreen
  static const String wallet = "/wallet";
  static const String profile = "/profile";

  // --- Rotas de Funcionalidades ---
  static const String transaction = "/transaction";
  static const String addEditGoal = "/add-edit-goal"; // <<<--- ADICIONE ESTA LINHA

  // --- Rotas da Seção Ferramentas ---
  static const String tools = "/tools";
  static const String debtCalculator = "/debt-calculator";
  static const String compoundInterestCalculator = "/compound-interest-calculator";
  static const String budgetCalculator = "/budget-calculator";

  // --- Outras Rotas ---
  static const String graficos = "/graficos"; // Manter se você usa
}