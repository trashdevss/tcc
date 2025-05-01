// lib/common/models/user_model.dart

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  // Removido password por segurança, mas pode adicionar de volta se realmente precisar
  // final String? password;

  // +++ NOVO CAMPO ADICIONADO +++
  final String? profilePictureUrl; // Para guardar a URL da imagem

  UserModel({
    this.id,
    this.name,
    this.email,
    // this.password,
    this.profilePictureUrl, // <<< Adicionado ao construtor
  });

  Map<String, dynamic> toMap() {
    // Usado principalmente para debug ou se precisar converter localmente
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'profile_picture_url': profilePictureUrl, // <<< Adicionado
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Cria o modelo a partir dos dados vindos do GraphQL/Hasura
    return UserModel(
      id: map['id'] as String?, // Assume que Hasura retorna 'id'
      name: map['name'] as String?, // Assume que Hasura retorna 'name'
      email: map['email'] as String?, // Assume que Hasura retorna 'email'
      // Não lê password do mapa
      // Lê a URL da foto
      profilePictureUrl: map['profile_picture_url'] as String?, // <<< Adicionado (verifique nome da coluna)
    );
  }

  // Se precisar converter para JSON (ex: para enviar em alguma função), use toMap()
  String toJson() => json.encode(toMap());

  // Se precisar converter de JSON (raro se usar fromMap com dados do GraphQL)
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    // String? password,
    String? profilePictureUrl, // <<< Adicionado
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      // password: password ?? this.password,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl, // <<< Adicionado
    );
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.email == email &&
        // other.password == password &&
        other.profilePictureUrl == profilePictureUrl; // <<< Adicionado
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        // password.hashCode ^
        profilePictureUrl.hashCode; // <<< Adicionado
  }
}