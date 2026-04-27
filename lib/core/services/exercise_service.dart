import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/treinos/shared/models/exercicio_model.dart';

/// Serviço de leitura e escrita da biblioteca de exercícios usando Supabase.
class ExerciseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Busca todos os exercícios da biblioteca base.
  Future<List<ExercicioItem>> buscarBibliotecaCompleta() async {
    try {
      final List<dynamic> data = await _supabase
          .from('exercicios_base')
          .select()
          .order('nome', ascending: true);

      return data.map((json) => ExercicioItem.fromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar biblioteca: $e');
    }
  }

  /// Busca um exercício específico pelo nome
  Future<ExercicioItem?> buscarExercicioPorNome(String nome) async {
    try {
      final data = await _supabase
          .from('exercicios_base')
          .select()
          .eq('nome', nome)
          .maybeSingle(); // Retorna null se não encontrar, em vez de dar erro

      if (data == null) return null;
      return ExercicioItem.fromSupabase(data);
    } catch (e) {
      debugPrint('Erro ao buscar exercício por nome: $e');
      return null;
    }
  }

  /// Busca exercícios filtrados (Substitui o buscarBibliotecaPaginada por enquanto)
  Future<List<ExercicioItem>> buscarComFiltros({
    String? categoria,
    String? busca,
  }) async {
    try {
      var query = _supabase.from('exercicios_base').select();

      if (categoria != null && categoria != 'Tudo' && categoria != 'Meus Exercícios') {
        query = query.contains('grupo_muscular', [categoria]);
      }

      if (busca != null && busca.isNotEmpty) {
        query = query.ilike('nome', '%$busca%');
      }

      final List<dynamic> data = await query.order('nome', ascending: true);
      return data.map((json) => ExercicioItem.fromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar exercícios: $e');
    }
  }

  /// Compatibilidade: Redireciona a busca paginada para a filtrada (simplificação temporária)
  Future<dynamic> buscarBibliotecaPaginada({
    String? categoria,
    String? busca,
    dynamic lastDoc, // Ignorado no Supabase por enquanto
    int limit = 20,
  }) async {
    final items = await buscarComFiltros(categoria: categoria, busca: busca);
    // Retornamos um objeto similar ao PaginatedExercises para não quebrar a UI
    return _FakePaginatedExercises(items);
  }

  /// Criar exercício customizado
  Future<void> criarExercicioCustomizado(
    ExercicioItem exercicio, {
    bool forPublico = false,
  }) async {
    try {
      await _supabase.from('exercicios_base').insert({
        'nome': exercicio.nome,
        'grupo_muscular': exercicio.grupoMuscular,
        'tipo_alvo': exercicio.tipoAlvo,
        'imagem_url': exercicio.imagemUrl,
        'media_url': exercicio.mediaUrl,
        'instrucoes': exercicio.instrucoes,
        'personal_id': forPublico ? null : _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      throw Exception('Erro ao criar exercício: $e');
    }
  }

  /// Atualizar exercício
  Future<void> atualizarExercicio(
    ExercicioItem exercicio, {
    bool forPublico = false,
  }) async {
    if (exercicio.id == null) throw Exception('ID necessário para atualizar');
    try {
      await _supabase.from('exercicios_base').update({
        'nome': exercicio.nome,
        'grupo_muscular': exercicio.grupoMuscular,
        'tipo_alvo': exercicio.tipoAlvo,
        'imagem_url': exercicio.imagemUrl,
        'media_url': exercicio.mediaUrl,
        'instrucoes': exercicio.instrucoes,
        'personal_id': forPublico ? null : _supabase.auth.currentUser?.id,
      }).eq('id', exercicio.id!);
    } catch (e) {
      throw Exception('Erro ao atualizar exercício: $e');
    }
  }

  // Métodos de utilidade vazios para compilação (serão removidos ou implementados depois)
  Future<void> cadastrarExerciciosEmMassa(List<ExercicioItem> ex, {bool? asSystemExercises}) async {}
  Future<void> limparColecaoExcetoModelo(String nome) async {}
  Future<Map<String, dynamic>?> obterTemplateDeExercicio(String nome) async => null;
}

class _FakePaginatedExercises {
  final List<ExercicioItem> items;
  final bool hasMore = false;
  final dynamic lastDoc = null;
  _FakePaginatedExercises(this.items);
}