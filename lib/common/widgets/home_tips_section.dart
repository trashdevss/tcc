// lib/common/widgets/home_tips_section.dart (ou seu caminho)

import 'package:flutter/material.dart';
// Ajuste os caminhos dos imports!
import 'package:tcc_3/common/models/educational_story.dart'; // Modelo
import 'package:tcc_3/common/widgets/story_card.dart'; // Card individual
import 'package:tcc_3/features/tips/view/tips_screen.dart';
import 'package:tcc_3/services/story_service.dart'; // Serviço que carrega as dicas

class HomeTipsSection extends StatelessWidget {
  const HomeTipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Ajustes de Layout ---
    // Altura total para a seção do carrossel
    const double sectionHeight = 155.0; // <<<--- VALOR REDUZIDO (teste)
    // Largura de cada card na lista horizontal
    const double tipCardWidth = 135.0; // <<<--- VALOR REDUZIDO (teste)
    // -------------------------

    return SizedBox(
      height: sectionHeight, // <<<--- Usa a altura reduzida
      child: FutureBuilder<List<EducationalStory>>(
        future: loadStories(), // Função que busca as dicas
        builder: (context, snapshot) {
          // Tratamento de estados (loading, error, empty)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            if (snapshot.hasError) {
              print("Erro ao carregar dicas para Home: ${snapshot.error}");
            }
            // Retorna um espaço vazio ou uma mensagem discreta
            return const Center(child: Text("...", style: TextStyle(color: Colors.grey)));
          }

          // Se tem dados, mostra a lista horizontal
          final List<EducationalStory> stories = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            // Padding nas laterais da lista inteira
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              // Define a largura de cada card
              return SizedBox(
                width: tipCardWidth, // <<<--- Usa a largura reduzida
                // Usa o StoryCard (certifique-se que ele está na versão compacta)
                child: StoryCard(
                  story: story,
                  onTap: () {
                    // Navega para a tela de detalhes ao clicar
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryDetailScreen(story: story),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
