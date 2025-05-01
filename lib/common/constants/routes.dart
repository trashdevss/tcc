// Dentro de lib/common/constants/named_route.dart (ou onde estiver sua classe)

class NamedRoute {
  NamedRoute._(); // Construtor privado para impedir instanciação

  static const String initial = "/";
  static const String splash = "/splash";
  static const String signUp = "/sign_up";
  static const String signIn = "/sign_in";
  static const String home = "/home";
  static const String stats = "/stats";
  static const String wallet = "/wallet";
  static const String profile = "/profile";
  static const String transaction = "/transaction";
  static const String forgotPassword = "/forgot-password";
  static const String checkYourEmail = "/check-your-email";

  // +++ ROTAS ADICIONADAS +++
  static const String tools = "/tools"; // Rota para a página principal de ferramentas
  static const String debtCalculator = "/debt-calculator";
// Dentro da sua classe NamedRoute
// Dentro da classe NamedRoute
 static const String budgetCalculator = "/budget-calculator"; // <<<--- ADICIONE ESTA LINHA
  static const String compoundInterestCalculator = "/compound-interest-calculator"; // Rota para a calculadora de juros compostos  // +++++++++++++++++++++++++

  // Adicione outras rotas futuras aqui...
}