import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Encapsula autenticação e sincronização mínima do perfil em `usuarios`.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> getUserType(String uid) async {
    try {
      final doc = await _db
          .collection('usuarios')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 30));
      return doc.data()?['tipoUsuario'] as String?;
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

      final batch = _db.batch();
      final userRef = _db.collection('usuarios').doc(uid);

      final userData = {
        'nome': nome,
        'email': email,
        'tipoUsuario': tipoUsuario,
        'dataCadastro': FieldValue.serverTimestamp(),
      };

      // Metadados iniciais usados para habilitar recursos do fluxo personal.
      if (tipoUsuario == 'personal') {
        userData['especialidade'] = especialidade ?? 'Geral';
        userData['plano'] = 'gratuito';
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

  Future<void> primeiroAcessoAluno({
    required String email,
    required String password,
  }) async {
    // Localiza o pré-cadastro criado pelo personal antes da conta Auth existir.
    final query = await _db
        .collection('usuarios')
        .where('email', isEqualTo: email)
        .where('tipoUsuario', isEqualTo: 'aluno')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception(
        'Nenhum cadastro encontrado para este e-mail. Peça ao seu personal para te cadastrar.',
      );
    }

    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }

    final uid = credential.user!.uid;
    final oldDoc = query.docs.first;
    final oldId = oldDoc.id;

    // Rotinas apontam para o id provisório e precisam ser migradas para o uid.
    final rotinasQuery = await _db
        .collection('rotinas')
        .where('alunoId', isEqualTo: oldId)
        .get();

    final batch = _db.batch();
    batch.set(_db.collection('usuarios').doc(uid), oldDoc.data());
    batch.delete(oldDoc.reference);

    for (final rotinaDoc in rotinasQuery.docs) {
      batch.update(rotinaDoc.reference, {'alunoId': uid});
    }

    final temAtivaOuNenhuma =
        rotinasQuery.docs.isEmpty ||
        rotinasQuery.docs.any((d) => d.data()['ativa'] == true);
    if (!temAtivaOuNenhuma) {
      // Mantém a regra de negócio: aluno deve ter ao menos uma rotina ativa.
      final maisRecente = rotinasQuery.docs.reduce((a, b) {
        final tsA =
            (a.data()['dataCriacao'] as Timestamp?)?.millisecondsSinceEpoch ??
            0;
        final tsB =
            (b.data()['dataCriacao'] as Timestamp?)?.millisecondsSinceEpoch ??
            0;
        return tsA >= tsB ? a : b;
      });
      batch.update(maisRecente.reference, {'ativa': true});
    }

    try {
      await batch.commit();
    } catch (e) {
      // Evita usuário órfão no Auth quando a migração Firestore falha.
      await credential.user?.delete();
      throw Exception('Erro ao configurar sua conta. Tente novamente.');
    }
  }

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    final email = user.email!;

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: senhaAtual,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(novaSenha);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> alterarEmail({
    required String senhaAtual,
    required String novoEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: senhaAtual,
      );
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(novoEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
        return Exception(
          'Credenciais inválidas. Verifique seu e-mail e senha.',
        );
      default:
        return Exception('Ocorreu um erro de autenticação: ${e.message}');
    }
  }
}
