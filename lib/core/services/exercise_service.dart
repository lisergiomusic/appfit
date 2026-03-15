import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/treinos/models/exercicio_model.dart';

class PaginatedExercises {
  final List<ExercicioItem> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  PaginatedExercises({
    required this.items,
    this.lastDoc,
    required this.hasMore,
  });
}

class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Busca os exercícios do Sistema + Os exercícios que o próprio Personal criou
  Future<List<ExercicioItem>> buscarBibliotecaCompleta() async {
    final personalId = _auth.currentUser?.uid;
    List<ExercicioItem> biblioteca = [];

    try {
      final snapshot = await _db.collection('exercicios_base')
          .where(Filter.or(
            Filter('personalId', isNull: true),
            Filter('personalId', isEqualTo: personalId),
          ))
          .get();

      biblioteca = snapshot.docs.map((doc) => ExercicioItem.fromFirestore(doc.data(), doc.id)).toList();
      biblioteca.sort((a, b) => a.nome.compareTo(b.nome));
      return biblioteca;
    } catch (e) {
      throw Exception('Erro ao carregar biblioteca: $e');
    }
  }

  // NOVA LÓGICA: Busca paginada usando Filter.or para evitar erro de 'null' no whereIn
  Future<PaginatedExercises> buscarBibliotecaPaginada({
    String? categoria,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    final personalId = _auth.currentUser?.uid;

    try {
      Query query = _db.collection('exercicios_base');

      // 1. Filtro de Identidade (Público + Privado) usando Filter.or
      Filter identityFilter;
      if (categoria == 'Meus Exercícios') {
        identityFilter = Filter('personalId', isEqualTo: personalId);
      } else {
        identityFilter = Filter.or(
          Filter('personalId', isNull: true),
          Filter('personalId', isEqualTo: personalId),
        );
      }
      
      query = query.where(identityFilter);

      // 2. Filtro de Categoria (Migrado para array-contains)
      if (categoria != null && categoria != 'Tudo' && categoria != 'Meus Exercícios') {
        // Agora usamos arrayContains pois grupoMuscular no Firestore é uma lista
        query = query.where('grupoMuscular', arrayContains: categoria);
      }

      // 3. Ordenação por Nome (Exige Índice Composto se houver Filter.or + orderBy)
      query = query.orderBy('nome');

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.limit(limit).get();
      final items = snapshot.docs.map((doc) {
        return ExercicioItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      return PaginatedExercises(
        items: items,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length == limit,
      );
    } catch (e) {
      throw Exception('Erro ao carregar biblioteca: $e');
    }
  }

  // Salva um exercício novo criado pelo Personal
  // Se forPublico for true e o user for admin (validado no app), personalId será null
  Future<void> criarExercicioCustomizado(ExercicioItem exercicio, {bool forPublico = false}) async {
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Utilizador não autenticado');

    // Se for público, personalId fica null. Caso contrário, leva o ID do utilizador.
    exercicio.personalId = forPublico ? null : personalId;

    try {
      await _db.collection('exercicios_base').add(exercicio.toFirestore());
    } catch (e) {
      throw Exception('Erro ao criar exercício: $e');
    }
  }

  // SCRIPT DE SEED (Atualizado para o novo formato de lista)
  Future<void> semearExerciciosBase() async {
    final List<ExercicioItem> exerciciosSemente = [
      ExercicioItem(
          nome: 'Supino Reto (Barra)',
          grupoMuscular: ['Peito'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Supino Inclinado (Halteres)',
          grupoMuscular: ['Peito'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Puxada Frontal (Polia)',
          grupoMuscular: ['Costas'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Remada Curvada (Barra)',
          grupoMuscular: ['Costas'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Agachamento Livre (Barra)',
          grupoMuscular: ['Pernas', 'Glúteos'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Leg Press 45°',
          grupoMuscular: ['Pernas', 'Glúteos'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Elevação Pélvica (Máquina)',
          grupoMuscular: ['Glúteos'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Rosca Direta (Barra)',
          grupoMuscular: ['Bíceps'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Tríceps Pulley',
          grupoMuscular: ['Tríceps'],
          imagemUrl: null,
          series: []
      ),
      ExercicioItem(
          nome: 'Abdominal Supra',
          grupoMuscular: ['Abdômen'],
          imagemUrl: null,
          series: []
      ),
    ];

    for (var ex in exerciciosSemente) {
      // Garante que são exercícios do sistema (públicos)
      ex.personalId = null;

      // Gera um ID de documento amigável baseado no nome
      String docId = ex.nome
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      // Salva no Firestore usando o método toFirestore do modelo
      await _db.collection('exercicios_base').doc(docId).set(ex.toFirestore());
    }
  }
}
