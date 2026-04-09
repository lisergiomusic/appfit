import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
      final snapshot = await _db
          .collection('exercicios_base')
          .where(
            Filter.or(
              Filter('personalId', isNull: true),
              Filter('personalId', isEqualTo: personalId),
            ),
          )
          .get();

      biblioteca = snapshot.docs
          .map((doc) => ExercicioItem.fromFirestore(doc.data(), doc.id))
          .toList();
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
      // 1. Buscamos os dados. Para evitar problemas com Filter.or e limitações do Firestore,
      // fazemos buscas simples e combinamos.

      List<DocumentSnapshot> allDocs = [];

      if (categoria == 'Meus Exercícios') {
        if (personalId != null) {
          final snap = await _db
              .collection('exercicios_base')
              .where('personalId', isEqualTo: personalId)
              .get()
              .timeout(const Duration(seconds: 10));
          allDocs = snap.docs;
        }
      } else {
        // Busca exercícios públicos (personalId == null)
        final snapPublic = await _db
            .collection('exercicios_base')
            .where('personalId', isNull: true)
            .get()
            .timeout(const Duration(seconds: 10));

        allDocs.addAll(snapPublic.docs);

        // Busca exercícios privados do personal logado
        if (personalId != null) {
          final snapPrivate = await _db
              .collection('exercicios_base')
              .where('personalId', isEqualTo: personalId)
              .get()
              .timeout(const Duration(seconds: 10));
          allDocs.addAll(snapPrivate.docs);
        }
      }

      // Converte para objetos de modelo
      List<ExercicioItem> allItems = allDocs.map((doc) {
        return ExercicioItem.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Remove duplicatas (caso um exercício tenha personalId e também caia em outra regra por erro de dados)
      final seenIds = <String>{};
      allItems = allItems.where((ex) => seenIds.add(ex.id ?? '')).toList();

      // 2. Filtro de Categoria em memória
      if (categoria != null &&
          categoria != 'Tudo' &&
          categoria != 'Meus Exercícios') {
        allItems = allItems
            .where((ex) => ex.grupoMuscular.contains(categoria))
            .toList();
      }

      // 3. Filtro de Busca em memória (Fuzzy Search)
      if (busca != null && busca.trim().isNotEmpty) {
        final termo = _normalizar(busca.trim());
        allItems = allItems.where((ex) {
          final nomeNorm = _normalizar(ex.nome);
          final gruposNorm = ex.grupoMuscular
              .map((g) => _normalizar(g))
              .join(' ');
          return nomeNorm.contains(termo) || gruposNorm.contains(termo);
        }).toList();
      }

      // 4. Ordenação por nome
      allItems.sort((a, b) => a.nome.compareTo(b.nome));

      // 5. Paginação manual em memória
      int startIndex = 0;
      if (lastDoc != null) {
        final lastId = lastDoc.id;
        startIndex = allItems.indexWhere((ex) => ex.id == lastId) + 1;
        if (startIndex <= 0) startIndex = 0;
      }

      final paginatedItems = allItems.skip(startIndex).take(limit).toList();

      // Encontra o DocumentSnapshot correspondente ao último item paginado
      DocumentSnapshot? lastDocResult;
      if (paginatedItems.isNotEmpty) {
        final lastItem = paginatedItems.last;
        try {
          lastDocResult = allDocs.firstWhere((doc) => doc.id == lastItem.id);
        } catch (_) {
          lastDocResult = null;
        }
      }

      return PaginatedExercises(
        items: paginatedItems,
        lastDoc: lastDocResult,
        hasMore: (startIndex + paginatedItems.length) < allItems.length,
      );
    } catch (e) {
      debugPrint('Erro detalhado no ExerciseService: $e');
      throw Exception('Falha ao carregar biblioteca: $e');
    }
  }

  Future<ExercicioItem?> buscarExercicioPorNome(String nome) async {
    final personalId = _auth.currentUser?.uid;

    try {
      ExercicioItem? exercicioEncontrado;

      if (personalId != null) {
        final privado = await _db
            .collection('exercicios_base')
            .where('nome', isEqualTo: nome)
            .where('personalId', isEqualTo: personalId)
            .limit(1)
            .get();

        if (privado.docs.isNotEmpty) {
          final doc = privado.docs.first;
          exercicioEncontrado = ExercicioItem.fromFirestore(doc.data(), doc.id);
        }
      }

      if (exercicioEncontrado != null) {
        return exercicioEncontrado;
      }

      final publico = await _db
          .collection('exercicios_base')
          .where('nome', isEqualTo: nome)
          .where('personalId', isNull: true)
          .limit(1)
          .get();

      if (publico.docs.isEmpty) {
        return null;
      }

      final doc = publico.docs.first;
      return ExercicioItem.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Erro ao buscar exercício por nome: $e');
    }
  }

  Future<void> criarExercicioCustomizado(
    ExercicioItem exercicio, {
    bool forPublico = false,
  }) async {
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
      ExercicioItem(
        nome: 'Supino Reto (Barra)',
        grupoMuscular: ['Peito'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Supino Inclinado (Halteres)',
        grupoMuscular: ['Peito'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Puxada Frontal (Polia)',
        grupoMuscular: ['Costas'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Remada Curvada (Barra)',
        grupoMuscular: ['Costas'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Agachamento Livre (Barra)',
        grupoMuscular: ['Pernas', 'Glúteos'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Leg Press 45°',
        grupoMuscular: ['Pernas', 'Glúteos'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Elevação Pélvica (Máquina)',
        grupoMuscular: ['Glúteos'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Rosca Direta (Barra)',
        grupoMuscular: ['Bíceps'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Tríceps Pulley',
        grupoMuscular: ['Tríceps'],
        series: [],
      ),
      ExercicioItem(
        nome: 'Abdominal Supra',
        grupoMuscular: ['Abdômen'],
        series: [],
      ),
    ];
    for (var ex in exerciciosSemente) {
      ex.personalId = null;
      String docId = ex.nome
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      await _db.collection('exercicios_base').doc(docId).set(ex.toFirestore());
    }
  }
}
