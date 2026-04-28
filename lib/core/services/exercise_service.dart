import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/treinos/shared/models/exercicio_model.dart';

/// Serviço de leitura e escrita da biblioteca de exercícios usando Supabase.
class ExerciseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

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
          .maybeSingle();

      if (data == null) return null;
      return ExercicioItem.fromSupabase(data);
    } catch (e) {
      debugPrint('Erro ao buscar exercício por nome: $e');
      return null;
    }
  }

  /// Busca exercícios filtrados
  Future<List<ExercicioItem>> buscarComFiltros({
    String? categoria,
    String? busca,
  }) async {
    try {
      var query = _supabase.from('exercicios_base').select();

      if (categoria != null && categoria != 'Tudo') {
        if (categoria == 'Meus Exercícios') {
          final uid = _currentUserId;
          if (uid != null) {
            query = query.eq('personal_id', uid);
          }
        } else {
          // No PostgreSQL, buscamos se a categoria existe dentro da lista grupo_muscular
          query = query.contains('grupo_muscular', [categoria]);
        }
      }

      if (busca != null && busca.isNotEmpty) {
        query = query.ilike('nome', '%$busca%');
      }

      // Ordenar: primeiro os favoritos/customizados do personal, depois por nome
      final List<dynamic> data = await query.order('nome', ascending: true);
      return data.map((json) => ExercicioItem.fromSupabase(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar exercícios: $e');
    }
  }

  /// Compatibilidade para UI paginada
  Future<dynamic> buscarBibliotecaPaginada({
    String? categoria,
    String? busca,
    dynamic lastDoc,
    int limit = 20,
  }) async {
    // Para simplificar a migração, buscamos com filtros. 
    // O Supabase lida bem com centenas de registros sem paginação complexa inicial.
    final items = await buscarComFiltros(categoria: categoria, busca: busca);
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
        'personal_id': forPublico ? null : _currentUserId,
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
        'personal_id': forPublico ? null : (exercicio.personalId ?? _currentUserId),
      }).eq('id', exercicio.id!);
    } catch (e) {
      throw Exception('Erro ao atualizar exercício: $e');
    }
  }

  /// Ferramenta de Admin: Cadastrar em massa
  Future<void> cadastrarExerciciosEmMassa(List<ExercicioItem> lista, {bool? asSystemExercises}) async {
    final List<Map<String, dynamic>> payload = lista.map((ex) => {
      'nome': ex.nome,
      'grupo_muscular': ex.grupoMuscular,
      'tipo_alvo': ex.tipoAlvo,
      'media_url': ex.mediaUrl,
      'instrucoes': ex.instrucoes,
      'personal_id': asSystemExercises == true ? null : _currentUserId,
    }).toList();

    await _supabase.from('exercicios_base').insert(payload);
  }

  /// Ferramenta de Admin: Limpeza
  Future<void> limparColecaoExcetoModelo(String nomeModelo) async {
    await _supabase.from('exercicios_base').delete().neq('nome', nomeModelo);
  }

  /// Ferramenta de Admin: Obter Template
  Future<Map<String, dynamic>?> obterTemplateDeExercicio(String nome) async {
    return await _supabase.from('exercicios_base').select().eq('nome', nome).maybeSingle();
  }
}

class _FakePaginatedExercises {
  final List<ExercicioItem> items;
  final bool hasMore = false;
  final dynamic lastDoc = null;
  _FakePaginatedExercises(this.items);
}