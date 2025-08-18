import 'package:flutter/material.dart';

class GraficosPage extends StatelessWidget {
  const GraficosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold( // Adicione um Scaffold se quiser AppBar, etc.
      appBar: AppBar(title: Text('Gráficos')),
      body: Center(
        child: Text('Página de Gráficos - Em construção'),
      ),
    );
  }
}