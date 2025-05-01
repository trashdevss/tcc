// lib/features/goals/view/goals_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Exemplo
import 'package:tcc_3/common/models/goal.dart';
import 'package:tcc_3/common/widgets/goal_card.dart';
import 'package:tcc_3/services/data_service/graphql_service.dart';

// Ajuste os caminhos conforme sua estrutura
import '../../../services/goal_service.dart';
import '../../../locator.dart'; // Se usar GetIt
import 'add_edit_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final GoalService _goalService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    // Sua lógica de inicialização (pegar userId, pegar GraphQLService, criar GoalService)
     try {
       final graphQLService = locator.get<GraphQLService>(); // Exemplo com GetIt
       final user = FirebaseAuth.instance.currentUser;
       if (user != null && user.uid.isNotEmpty) {
          _goalService = GoalService(graphQLService: graphQLService);
          if(mounted) setState(() => _isInitialized = true);
       } else {
          print("GoalsScreen: Usuário não logado.");
          if(mounted) setState(() => _isInitialized = false);
       }
    } catch (e) {
       print("Erro ao inicializar GoalService em GoalsScreen: $e");
       if(mounted) setState(() => _isInitialized = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Metas'),
        // Seus estilos de AppBar...
      ),
      body: Builder(
         builder: (context) {
           if (!_isInitialized) {
             // Melhora a mensagem se o usuário não estiver logado
             if (FirebaseAuth.instance.currentUser == null) {
                return const Center(child: Text("Faça login para ver suas metas.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)));
             }
             return const Center(child: Text("Carregando metas...")); // Ou um ProgressIndicator
           }

           // --- StreamBuilder se inicializado ---
           return StreamBuilder<List<Goal>>(
             stream: _goalService.getGoalsStream(),
             builder: (context, snapshot) {
                // Seus cases de connectionState, hasError, !hasData ...
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                 return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                 return Center(child: Text('Erro ao carregar metas: ${snapshot.error}'));
                }
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   // Mensagem centralizada e mais amigável
                   return const Center(
                     child: Padding(
                       padding: EdgeInsets.all(24.0),
                       child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flag_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma meta por aqui ainda!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                             SizedBox(height: 8),
                             Text(
                              'Crie sua primeira meta clicando no botão +',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          ],
                       )
                     ),
                   );
                 }

                // --- Lista de Metas ---
                final List<Goal> goals = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return GoalCard(
                      goal: goal,
                      goalService: _goalService,
                      currencyFormatter: currencyFormatter,
                    );
                  },
                );
             },
           );
         }
      ),
      // ==================================================
      // <<<--- heroTag ADICIONADA AO FAB DE METAS --- >>>
      // ==================================================
      floatingActionButton: Builder(
         builder: (context) {
            // Só mostra o botão se inicializado com sucesso
            return _isInitialized
              ? FloatingActionButton(
                  heroTag: 'fab_goals_screen', // <-- Tag única e DIFERENTE
                  onPressed: () {
                    // Navega para a tela de adicionar/editar
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditGoalScreen(
                          goalService: _goalService,
                          goalToEdit: null, // Criação
                        ),
                      ),
                    );
                  },
                  tooltip: 'Adicionar Nova Meta',
                  child: const Icon(Icons.add),
                  // style: ..., // Seu estilo
                )
              : const SizedBox.shrink(); // Não mostra botão se não inicializado
         }
      ),
      // ==================================================
    );
  }
}