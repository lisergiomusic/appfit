import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  /// Retorna os dados brutos de qualquer perfil pelo ID
  Future<Map<String, dynamic>> getProfile(String uid) async {
    try {
      final data = await _supabase.from('profiles').select().eq('id', uid).single();
      return data;
    } catch (e) {
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Stream de um perfil específico (reatividade)
  Stream<Map<String, dynamic>> getProfileStream(String uid) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((list) => list.isNotEmpty ? list.first : {});
  }

  /// Atualiza dados comuns de perfil (Personal ou Aluno)
  Future<void> updateProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', uid);
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  /// Atalho para atualizar dados específicos de Personal
  Future<void> updatePersonalProfile({
    required String uid,
    required String nome,
    required String sobrenome,
    required String email,
    required String especialidade,
    String? telefone,
  }) async {
    return updateProfile(uid: uid, data: {
      'nome': nome,
      'sobrenome': sobrenome,
      'email': email,
      'especialidade': especialidade,
      'telefone': telefone,
    });
  }
}