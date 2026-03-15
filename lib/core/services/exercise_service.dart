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

  /// Remove acentos e caracteres especiais para busca "fuzzy"
  String _normalizar(String text) {
    var str = text.toLowerCase();
    str = str.replaceAll(RegExp(r'[àáâãäå]'), 'a');
    str = str.replaceAll(RegExp(r'[èéêë]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíîï]'), 'i');
    str = str.replaceAll(RegExp(r'[òóôõö]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúûü]'), 'u');
    str = str.replaceAll(RegExp(r'[ç]'), 'c');
    str = str.replaceAll(RegExp(r'[ñ]'), 'n');
    return str;
  }

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

  Future<PaginatedExercises> buscarBibliotecaPaginada({
    String? categoria,
    String? busca,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    final personalId = _auth.currentUser?.uid;

    try {
      if (busca != null && busca.isNotEmpty) {
        final termoNormalizado = _normalizar(busca.trim());
        
        Query query = _db.collection('exercicios_base');
        query = query.where(Filter.or(
          Filter('personalId', isNull: true),
          Filter('personalId', isEqualTo: personalId),
        ));

        final snapshot = await query.get();
        List<ExercicioItem> allItems = snapshot.docs.map((doc) {
          return ExercicioItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        if (categoria != null && categoria != 'Tudo') {
          if (categoria == 'Meus Exercícios') {
            allItems = allItems.where((ex) => ex.personalId == personalId).toList();
          } else {
            allItems = allItems.where((ex) => ex.grupoMuscular.contains(categoria)).toList();
          }
        }

        // Busca com normalização em ambos os lados (Ignora acentos)
        final filtered = allItems.where((ex) {
          final nomeNorm = _normalizar(ex.nome);
          final gruposNorm = ex.grupoMuscular.map((g) => _normalizar(g)).toList();
          
          return nomeNorm.contains(termoNormalizado) || 
                 gruposNorm.any((g) => g.contains(termoNormalizado));
        }).toList();

        filtered.sort((a, b) => a.nome.compareTo(b.nome));

        return PaginatedExercises(
          items: filtered,
          lastDoc: null,
          hasMore: false,
        );
      }

      Query query = _db.collection('exercicios_base');
      Filter identityFilter = categoria == 'Meus Exercícios' 
          ? Filter('personalId', isEqualTo: personalId)
          : Filter.or(Filter('personalId', isNull: true), Filter('personalId', isEqualTo: personalId));
      
      query = query.where(identityFilter);

      if (categoria != null && categoria != 'Tudo' && categoria != 'Meus Exercícios') {
        query = query.where('grupoMuscular', arrayContains: categoria);
      }

      query = query.orderBy('nome');
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

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
      throw Exception('Erro ao carregar dados: $e');
    }
  }

  Future<void> criarExercicioCustomizado(ExercicioItem exercicio, {bool forPublico = false}) async {
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Utilizador não autenticado');
    exercicio.personalId = forPublico ? null : personalId;
    try {
      await _db.collection('exercicios_base').add(exercicio.toFirestore());
    } catch (e) {
      throw Exception('Erro ao criar exercício: $e');
    }
  }

  Future<void> semearExerciciosBase() async {
    final List<ExercicioItem> exerciciosSemente = [
      ExercicioItem(nome: 'Supino Reto (Barra)', grupoMuscular: ['Peito'], series: []),
      ExercicioItem(nome: 'Supino Inclinado (Halteres)', grupoMuscular: ['Peito'], series: []),
      ExercicioItem(nome: 'Puxada Frontal (Polia)', grupoMuscular: ['Costas'], series: []),
      ExercicioItem(nome: 'Remada Curvada (Barra)', grupoMuscular: ['Costas'], series: []),
      ExercicioItem(nome: 'Agachamento Livre (Barra)', grupoMuscular: ['Pernas', 'Glúteos'], series: []),
      ExercicioItem(nome: 'Leg Press 45°', grupoMuscular: ['Pernas', 'Glúteos'], series: []),
      ExercicioItem(nome: 'Elevação Pélvica (Máquina)', grupoMuscular: ['Glúteos'], series: []),
      ExercicioItem(nome: 'Rosca Direta (Barra)', grupoMuscular: ['Bíceps'], series: []),
      ExercicioItem(nome: 'Tríceps Pulley', grupoMuscular: ['Tríceps'], series: []),
      ExercicioItem(nome: 'Abdominal Supra', grupoMuscular: ['Abdômen'], series: []),
    ];
    for (var ex in exerciciosSemente) {
      ex.personalId = null;
      String docId = ex.nome.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), '_');
      await _db.collection('exercicios_base').doc(docId).set(ex.toFirestore());
    }
  }
}
