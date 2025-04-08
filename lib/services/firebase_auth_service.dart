import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/services/auth_service.dart';

class FirebaseAuthService implements AuthService {
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final token = await result.user!.getIdToken();
        log("Token inicial gerado: $token");

        return UserModel(
          name: result.user!.displayName ?? '',
          email: result.user!.email ?? '',
          id: result.user!.uid,
        );
      } else {
        throw Exception("Erro ao fazer login.");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Erro ao fazer login.");
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> signUp({
    String? name,
    required String email,
    required String password,
  }) async {
    try {
      await _functions.httpsCallable('registerUser').call({
        'name': name,
        'email': email,
        'password': password,
        'displayName': name,
      });

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final token = await _auth.currentUser?.getIdToken(true);
        log("Token após cadastro: ${token ?? 'nulo'}");

        
        if (name != null) {
          await result.user!.updateDisplayName(name);
        }
 
        return UserModel(
          name: _auth.currentUser?.displayName ?? name ?? '',
          email: _auth.currentUser?.email ?? email,
          id: _auth.currentUser?.uid ?? result.user!.uid,
        );
      } else {
        throw Exception("Erro ao cadastrar usuário.");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Erro ao cadastrar.");
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? "Erro na Cloud Function.");
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
  
    @override
  Future<String> get userToken async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        return token;
      } else {
        throw Exception('Usuário não encontrado');
      }
    } catch (e) {
      rethrow;
    }
  }
}
