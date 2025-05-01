// lib/common/widgets/story_card.dart (ou seu caminho)

import 'package:flutter/material.dart';
import 'package:tcc_3/common/models/educational_story.dart';
// Ajuste o caminho para o modelo EducationalStory se necessário

class StoryCard extends StatelessWidget {
  final EducationalStory story;
  final VoidCallback? onTap;

  const StoryCard({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Padding interno
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Imagem (se existir) ---
              if (story.imagePath != null && story.imagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: Image.asset(
                    story.imagePath!,
                    height: 60, // Altura da imagem
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 60,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 24),
                        ),
                      );
                    },
                  ),
                ),
              // ==============================================
              // <<<--- CORREÇÃO AQUI (SizedBox Pós-Imagem) --- >>>
              // ==============================================
              // Diminui o espaço após a imagem para ganhar os últimos pixels
              if (story.imagePath != null && story.imagePath!.isNotEmpty)
                const SizedBox(height: 5.0), // <<<--- Reduzido de 8.0 para 5.0 (teste)
              // ==============================================

              // --- Título ---
              Text(
                story.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Fonte menor
                    ),
                 maxLines: 2, // Limite de 2 linhas
                 overflow: TextOverflow.ellipsis,
              ),
              // SizedBox entre título e conteúdo foi removido na correção anterior

              // --- Conteúdo ---
              Text(
                story.textContent,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11, // Fonte menor
                      color: Colors.black54,
                    ),
                maxLines: 2, // Limite de 2 linhas
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
