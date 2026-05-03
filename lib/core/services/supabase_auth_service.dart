import 'package:flutter/foundation.dart';
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
    } on AuthException catch (e) {
      // Erro específico do Supabase (ex: credenciais erradas, usuário não existe)
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('E-mail ou senha incorretos.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro inesperado ao entrar: $e');
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
          'tipo_usuario': tipoUsuario,
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
    // 1. Tenta primeiro pelo metadata do usuário (cacheado no Auth, ultra rápido)
    final metaType = _supabase.auth.currentUser?.userMetadata?['tipo_usuario'];
    if (metaType != null) return metaType as String;

    try {
      // 2. Tenta buscar pelo ID (UID do Auth)
      final data = await _supabase
          .from('profiles')
          .select('tipo_usuario')
          .eq('id', uid)
          .maybeSingle();
      
      if (data != null) return data['tipo_usuario'] as String?;

      // 3. Fallback: Tenta buscar pelo E-mail do usuário atual
      // Isso é necessário para Alunos cadastrados manualmente pelo Personal,
      // onde o ID na tabela 'profiles' ainda não foi sincronizado com o UID do Auth.
      final email = currentUser?.email;
      if (email != null) {
        final dataByEmail = await _supabase
            .from('profiles')
            .select('tipo_usuario')
            .ilike('email', email.trim())
            .maybeSingle();
        
        return dataByEmail?['tipo_usuario'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('>>> [SupabaseAuthService] Erro ao buscar tipo de usuário: $e');
      return null;
    }
  }

  /// Verifica se o usuário atual é administrador
  Future<bool> isAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final data = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .maybeSingle();

      return data?['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Recupera todos os dados do perfil do usuário logado
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return data;
    } catch (e) {
      return null;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Altera a senha do usuário logado
  Future<void> alterarSenha({required String novaSenha}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: novaSenha),
      );
    } catch (e) {
      throw Exception('Erro ao alterar senha: $e');
    }
  }

  /// Primeiro acesso de aluno pré-cadastrado pelo personal.
  /// Cria a conta no Auth do Supabase e vincula ao perfil existente na tabela profiles.
  Future<void> primeiroAcessoAluno({
    required String email,
    required String password,
  }) async {
    final existing = await _supabase
        .from('profiles')
        .select('id, nome, sobrenome')
        .ilike('email', email.trim())
        .eq('tipo_usuario', 'aluno')
        .maybeSingle();

    if (existing == null) {
      // Log para depuração (pode ser removido depois)
      throw Exception(
        'Nenhum cadastro encontrado para este e-mail. Peça ao seu personal para te cadastrar.',
      );
    }

    try {
      // 1. Criar o usuário no Auth com o nome e tipo no user_metadata
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': '${existing['nome']} ${existing['sobrenome'] ?? ''}'.trim(),
          'tipo_usuario': 'aluno',
        },
      );

      final newUserId = res.user?.id;
      if (newUserId != null) {

        try {
          // 2. Vinculamos o perfil ao ID do Auth usando o e-mail como chave de busca
          await _supabase
              .from('profiles')
              .update({'id': newUserId})
              .eq('email', email.trim().toLowerCase());
        } catch (updateError) {
        }
      }
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('Este e-mail já possui uma conta. Use a tela de login.');
      }
      throw Exception(e.message);
    }
  }
}