import 'package:flutter/material.dart';

// Ajuste os caminhos
import 'package:tcc_3/common/models/educational_story.dart';
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';

// --- AJUSTE ESTES IMPORTS ---
// Importe as telas das suas calculadoras
import '../../tools/view/budget_calculator_page.dart';
import '../../tools/view/debt_impact_calculator_page.dart';
import '../../tools/view/compound_interest_calculator_page.dart';
// --------------------------

class StoryDetailScreen extends StatelessWidget {
  final EducationalStory story;

  const StoryDetailScreen({super.key, required this.story});

  // Helper para dados do botão (sem alterações)
  Map<String, String>? _getToolButtonData(String? toolLink) {
    if (toolLink == null || toolLink.isEmpty) { return null; }
    switch (toolLink) {
      case 'budget_calculator': return {'text': 'Abrir Calculadora de Orçamento'};
      case 'debt_calculator': return {'text': 'Simular Impacto da Dívida'};
      case 'compound_interest_calculator': return {'text': 'Ver Calculadora de Juros Compostos'};
      default: return null;
    }
  }

   // Helper para navegação (sem alterações)
   void _navigateToTool(BuildContext context, String? toolId) {
     if (toolId != null) {
       Widget? targetScreen;
       if (toolId == 'budget_calculator') { targetScreen = const BudgetCalculatorPage(); }
       else if (toolId == 'debt_calculator') { targetScreen = const DebtImpactCalculatorPage(); }
       else if (toolId == 'compound_interest_calculator') { targetScreen = const CompoundInterestCalculatorPage(); }

       if (targetScreen != null) {
         Navigator.push( context, MaterialPageRoute(builder: (context) => targetScreen!), );
       } else {
         print("Nenhuma tela definida para o link: $toolId");
         ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Ferramenta não encontrada.'), duration: Duration(seconds: 1)) );
       }
     }
   }


  @override
  Widget build(BuildContext context) {
    final toolButtonData = _getToolButtonData(story.toolLink);

    return Scaffold(
      // === COR DE FUNDO SUAVE ===
      backgroundColor: AppColors.iceWhite, // Ou outra cor clara
      // ==========================
      appBar: AppBar(
        title: Text(story.title),
         // Estilo da AppBar (pode manter o seu ou usar este exemplo)
         backgroundColor: AppColors.green, // Fundo verde para combinar
         foregroundColor: Colors.white,   // Texto e ícone brancos
         elevation: 0, // Sem sombra na AppBar
         leading: IconButton( // Ícone voltar branco
           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
           onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagem --- (Sem mudanças na lógica)
            if (story.imagePath != null && story.imagePath!.isNotEmpty)
              Image.asset( story.imagePath!, width: double.infinity, height: MediaQuery.of(context).size.height * 0.3, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) { return Container( height: MediaQuery.of(context).size.height * 0.3, color: Colors.grey[300], child: Center( child: Icon(Icons.broken_image, color: Colors.grey[500], size: 50), ), ); }, ),

            // === CONTEÚDO DENTRO DE UM CARD ===
            Card(
              margin: const EdgeInsets.all(16.0), // Margem para desgrudar das bordas
              elevation: 2, // Sombra sutil
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Padding interno do card
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      // --- Texto Principal ---
                      Text(
                        story.textContent,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith( fontSize: 17, height: 1.5, color: AppColors.darkGrey ), // Ajuste cor se necessário
                      ),
                      const SizedBox(height: 16.0),

                      // --- Botão Condicional (Agora ElevatedButton) ---
                      if (toolButtonData != null)
                        Center( // Centraliza o botão
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calculate_outlined, size: 20),
                            label: Text(toolButtonData['text'] ?? 'Abrir Ferramenta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green, // Cor de fundo do botão
                              foregroundColor: Colors.white,     // Cor do texto/ícone
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              textStyle: AppTextStyles.mediumText14.copyWith(fontWeight: FontWeight.bold) // Use seu estilo
                            ),
                            onPressed: () {
                              _navigateToTool(context, story.toolLink); // Chama helper de navegação
                            },
                          ),
                        ),
                      // -----------------------------------------
                   ],
                ),
              ),
            ),
            // ===================================

            const SizedBox(height: 16.0), // Espaço final (ajuste se necessário)
          ],
        ),
      ),
    );
  }
}