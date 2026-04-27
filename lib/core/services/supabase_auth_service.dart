import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream para monitorar o estado da autenticação (similar ao Firebase authStateChanges)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Retorna o usuário logado atualmente
  User? get currentUser => _supabase.auth.currentUser;

  /// Login com e-mail e senha
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erro ao entrar: $e');
    }
  }

  /// Cadastro de novo usuário e criação automática do perfil na tabela SQL
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nome,
    required String tipoUsuario,
    String? personalId,
    String? especialidade,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': nome,
        },
      );

      final user = response.user;
      if (user != null) {
        // Criar o registro na tabela 'profiles' que definimos no SQL Editor
        await _supabase.from('profiles').insert({
          'id': user.id,
          'nome': nome,
          'email': email,
          'tipo_usuario': tipoUsuario,
          'personal_id': personalId,
          'especialidade': especialidade ?? (tipoUsuario == 'personal' ? 'Geral' : null),
          'plano': tipoUsuario == 'personal' ? 'gratuito' : null,
        });
      }

      return response;
    } catch (e) {
      throw Exception('Erro ao cadastrar: $e');
    }
  }

  /// Recupera o tipo de usuário do banco SQL
  Future<String?> getUserType(String uid) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('tipo_usuario')
          .eq('id', uid)
          .single();
      return data['tipo_usuario'] as String?;
    } catch (e) {
      print('Erro ao buscar tipo de usuário no Supabase: $e');
      return null;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}