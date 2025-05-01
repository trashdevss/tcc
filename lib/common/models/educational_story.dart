// Modelo de dados para representar uma dica/story educativo
// (Certifique-se que está no arquivo correto, ex: lib/common/models/educational_story.dart)


class EducationalStory {
  final String id;
  final String title;
  final String contentType; // Ex: 'text', 'text_image'
  final String textContent;
  final String? imagePath; // Caminho da imagem local nos assets (pode ser nulo)

  // +++ NOVO CAMPO ADICIONADO +++
  final String? toolLink; // Guarda o identificador da ferramenta ('debt_calculator', etc.) ou null

  EducationalStory({
    required this.id,
    required this.title,
    required this.contentType,
    required this.textContent,
    this.imagePath,
    this.toolLink, // <<< Adicionado ao construtor
  });

  // Método de fábrica para criar um objeto EducationalStory a partir de um Map JSON
  factory EducationalStory.fromJson(Map<String, dynamic> json) {
    // Usa '??' para fornecer valores padrão caso o campo não exista no JSON
    return EducationalStory(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sem Título',
      contentType: json['content_type'] ?? 'text',
      textContent: json['text_content'] ?? '',
      imagePath: json['image_path'] as String?, // Permite que seja nulo
      // +++ LENDO O NOVO CAMPO DO JSON +++
      toolLink: json['tool_link'] as String?, // Lê 'tool_link' do JSON (pode ser null)
    );
  }

  // --- Métodos Opcionais (Adicione se precisar/usar) ---

  // Exemplo: Se precisar converter para Map para salvar em algum lugar
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content_type': contentType,
      'text_content': textContent,
      'image_path': imagePath,
      'tool_link': toolLink, // Inclui o novo campo
    };
  }

   // Exemplo: Se precisar do método copyWith
  EducationalStory copyWith({
    String? id,
    String? title,
    String? contentType,
    String? textContent,
    String? imagePath,
    String? toolLink, // Inclui o novo campo
  }) {
    return EducationalStory(
      id: id ?? this.id,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      textContent: textContent ?? this.textContent,
      imagePath: imagePath ?? this.imagePath,
      toolLink: toolLink ?? this.toolLink, // Inclui o novo campo
    );
  }

  // Exemplo: Se precisar dos operadores == e hashCode
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EducationalStory &&
      other.id == id &&
      other.title == title &&
      other.contentType == contentType &&
      other.textContent == textContent &&
      other.imagePath == imagePath &&
      other.toolLink == toolLink; // Inclui o novo campo
  }

  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      contentType.hashCode ^
      textContent.hashCode ^
      imagePath.hashCode ^
      toolLink.hashCode; // Inclui o novo campo
  }
  // --- Fim dos Métodos Opcionais ---

} // Fim da classe EducationalStory