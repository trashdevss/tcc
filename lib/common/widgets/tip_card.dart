// lib/common/widgets/tip_card.dart

import 'package:flutter/material.dart';
import 'dart:developer'; // Para usar log()

// --- VERIFIQUE OS CAMINHOS DOS SEUS IMPORTS ---
// Precisa importar TipModel e a definição da classe para tip.action (ex: TipActionModel)
// Precisa importar NamedRoute para usar as constantes de rota
import 'package:tcc_3/features/home/models/tip_model.dart'; // Certifique-se que este caminho está correto
import 'package:tcc_3/common/constants/app_colors.dart';
import 'package:tcc_3/common/constants/app_text_styles.dart';
import 'package:tcc_3/common/constants/routes.dart'; // Import das suas rotas nomeadas
// Importe a definição da TipDetailPage se ela estiver em um arquivo separado e remova a classe abaixo
// import 'package:tcc_3/features/tips/tip_detail_page.dart'; // Exemplo
// --- FIM DOS IMPORTS ---


// =========================================================================
//  Widget do Card Pequeno (usado na lista da HomePage)
// =========================================================================
class TipCard extends StatelessWidget {
  final TipModel tip;
  const TipCard({Key? key, required this.tip}) : super(key: key);

  // --- AÇÃO DO CARD: SEMPRE ABRE A PÁGINA DE DETALHES ---
  void _handleAction(BuildContext context, TipModel tip) {
    // Sempre navega para a página de detalhes, passando o objeto tip inteiro
    print('>>> TipCard: Navegando para detalhes de ${tip.id}');
    Navigator.push(
      context,
      MaterialPageRoute(
        // Passa o objeto tip COMPLETO para TipDetailPage
        builder: (context) => TipDetailPage(tip: tip), // Passa o modelo todo
      ),
    );
  }
  // --- FIM DA AÇÃO DO CARD ---


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.65; // Largura do card na lista

    return SizedBox(
      width: cardWidth,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: InkWell(
          // Chama a _handleAction (que agora só abre detalhes)
          onTap: () => _handleAction(context, tip),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem
              Image.asset(
                tip.imageUrl,
                height: 60,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 60,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 30,),
                    ),
                  );
                },
              ),
              // Textos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( tip.title, style: (AppTextStyles.mediumText16 ?? const TextStyle(fontSize: 14)).copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis, ),
                    const SizedBox(height: 3),
                    Text( tip.subtitle, // Mostra a frase/subtítulo
                          style: (AppTextStyles.smallText ?? const TextStyle(fontSize: 12)).copyWith(color: AppColors.grey),
                          maxLines: 2, // Ajuste maxLines se necessário
                          overflow: TextOverflow.ellipsis, ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =========================================================================
//  Página de Detalhes da Dica (TipDetailPage)
// =========================================================================
// Se você já tem esta classe em outro arquivo, APAGUE esta definição
// e IMPORTE a sua versão no início deste arquivo, aplicando as
// modificações do _buildActionButton lá.
class TipDetailPage extends StatelessWidget {
  // Recebe o TipModel completo
  final TipModel tip;

  const TipDetailPage({
    Key? key,
    required this.tip, // Construtor atualizado
  }) : super(key: key);

  // --- Helper para construir o botão de ação (CORRIGIDO para null safety) ---
  Widget _buildActionButton(BuildContext context) {
     final actionData = tip.action; // Pega a ação do modelo (TipActionModel?)

     // Verifica se actionData existe e o tipo é 'navigateTo'
     if (actionData != null && actionData.type == 'navigateTo') {

        // Atribui o valor a uma VARIÁVEL LOCAL (String?) para promoção de tipo
        final String? actionValue = actionData.value;

        // AGORA verifica se a VARIÁVEL LOCAL não é nula E não é vazia
        if (actionValue != null && actionValue.isNotEmpty) {
            // ---- Daqui para baixo, podemos usar actionValue com segurança ----

            // Determina o texto e ícone do botão
            String buttonText = 'Abrir Ferramenta';
            IconData buttonIcon = Icons.open_in_new;
            // Usa a variável local que sabemos não ser nula aqui
            final String routeName = actionValue;

            // Mapeia a rota para um texto/ícone mais específico (Usando NamedRoute)
            if (routeName == NamedRoute.debtCalculator) {
               buttonText = 'Simular Impacto da Dívida';
               buttonIcon = Icons.calculate_outlined; // Ajuste o ícone
            } else if (routeName == NamedRoute.budgetCalculator) {
               buttonText = 'Acessar Calculadora Orçamento';
               buttonIcon = Icons.pie_chart_outline;
            } else if (routeName == NamedRoute.compoundInterestCalculator) {
               buttonText = 'Calcular Juros Compostos';
               buttonIcon = Icons.trending_up;
            } else if (routeName == NamedRoute.stats) {
               buttonText = 'Ver minhas Estatísticas';
               buttonIcon = Icons.bar_chart;
            } else if (routeName == NamedRoute.metas) {
               buttonText = 'Ver minhas Metas';
               buttonIcon = Icons.flag_outlined;
            }
            // Adicione mais 'else if' para outras rotas

            // Retorna o botão configurado
            return Center(
               child: ElevatedButton.icon(
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonText),
                  onPressed: () {
                     print('>>> TipDetailPage: Navegando para $routeName');
                     try {
                       // Usa routeName (que veio de actionValue não nulo)
                       Navigator.pushNamed(context, routeName);
                     } catch (e) {
                        log('>>> TipDetailPage: Erro ao navegar para "$routeName". Rota não definida? Erro: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Não foi possível abrir a ferramenta.'))
                        );
                     }
                  },
                  style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.green, // Sua cor primária
                     foregroundColor: Colors.white, // Cor do texto/ícone
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     textStyle: AppTextStyles.mediumText16 ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
               ),
            );
            // ---- Fim do bloco seguro ----
        } else {
           // Se actionValue for nulo ou vazio
           log('>>> TipDetailPage: action.value é nulo ou vazio para navigateTo (ID: ${tip.id})');
           return const SizedBox.shrink(); // Não mostra botão
        }
     } else {
        // Se actionData for nulo ou o tipo não for 'navigateTo'
        return const SizedBox.shrink(); // Não mostra botão
     }
  }
  // --- Fim do Helper do Botão ---


  @override
  Widget build(BuildContext context) {
    // Acessa os dados diretamente de 'tip' recebido no construtor
    final String title = tip.title;
    // Usa o subtitle como conteúdo principal, pode ajustar se tiver outro campo
    final String content = tip.subtitle ?? "Conteúdo não disponível.";
    final String imageUrl = tip.imageUrl;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fundo para destacar o card
      appBar: AppBar(
        title: Text(title), // Usa o título da dica
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0), // Espaço entre tela e card
        child: Card(
          elevation: 4.0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Cantos do card
          ),
          clipBehavior: Clip.antiAlias,
          // Padding interno do card
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinha conteúdo à esquerda
              mainAxisSize: MainAxisSize.min, // Coluna ocupa só o necessário
              children: [
                // Imagem
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0), // Cantos da imagem
                    child: Image.asset( // Usa Image.asset
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 20.0), // Espaço abaixo da imagem
                ],

                // Texto do Conteúdo da Dica
                Text(
                  content,
                  style: AppTextStyles.mediumText16?.copyWith(
                    height: 1.5, // Espaçamento entre linhas
                    color: Colors.black87,
                  ) ?? const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 28.0), // Espaço abaixo do texto

                // --- BOTÃO CONDICIONAL ADICIONADO AQUI ---
                _buildActionButton(context), // Chama a função que monta o botão (ou nada)

                const SizedBox(height: 8.0), // Pequeno espaço no final do card
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --------------- FIM DA TipDetailPage ---------------