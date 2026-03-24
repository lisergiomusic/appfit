import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> getUserType(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['tipoUsuario'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      final doc = await _db.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      final doc = await _db.collection('usuarios').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String nome,
    required String tipoUsuario,
    String? especialidade,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Persiste os metadados do usuário no Firestore usando Batch para garantir transação
      final batch = _db.batch();
      final userRef = _db.collection('usuarios').doc(uid);

      final userData = {
        'nome': nome,
        'email': email,
        'tipoUsuario': tipoUsuario,
        'dataCadastro': FieldValue.serverTimestamp(),
      };

      if (tipoUsuario == 'personal') {
        userData['especialidade'] = especialidade ?? 'Geral';
        userData['plano'] = 'gratuito'; // Valor default otimizado
      }

      batch.set(userRef, userData);
      await batch.commit();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Falha ao registrar usuário: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Nenhum usuário encontrado para este e-mail.');
      case 'wrong-password':
        return Exception('Senha incorreta.');
      case 'email-already-in-use':
        return Exception('Este e-mail já está em uso.');
      case 'weak-password':
        return Exception('A senha fornecida é muito fraca.');
      case 'invalid-email':
        return Exception('O endereço de e-mail é inválido.');
      case 'invalid-credential':
        return Exception('Credenciais inválidas. Verifique seu e-mail e senha.');
      default:
        return Exception('Ocorreu um erro de autenticação: ${e.message}');
    }
  }
}
