// lib/data/local/local_story_datasource.dart

import 'dart:convert'; // Para json.decode
import 'package:flutter/services.dart' show rootBundle; // Para carregar assets
import 'package:tcc_3/common/models/educational_story.dart';

// Importe o modelo de dados que você criou

// Classe que representa a fonte de dados local para as histórias educativas
class LocalStoryDatasource {

  // Método assíncrono para carregar e decodificar as histórias do arquivo JSON local
  Future<List<EducationalStory>> loadStories() async {
    try {
      // Carrega o conteúdo bruto do arquivo JSON como uma String
      final String jsonString = await rootBundle.loadString('assets/data/educational_stories.json');

      // Decodifica a String JSON em uma Lista dinâmica (List<dynamic>)
      final List<dynamic> jsonList = json.decode(jsonString);

      // Mapeia cada item da lista JSON para um objeto EducationalStory usando o factory constructor
      // e converte o resultado em uma List<EducationalStory>
      final List<EducationalStory> stories = jsonList
          .map((jsonItem) => EducationalStory.fromJson(jsonItem as Map<String, dynamic>))
          .toList();

      return stories;
    } catch (e) {
      // Em caso de erro (arquivo não encontrado, JSON inválido, etc.)
      print('Erro ao carregar stories do JSON local (Datasource): $e');
      // Retorna uma lista vazia ou lança uma exceção, dependendo de como você quer tratar
      return [];
      // ou throw Exception('Falha ao carregar histórias: $e');
    }
  }

  // Você poderia adicionar outros métodos relacionados a dados locais aqui no futuro, se necessário.
}