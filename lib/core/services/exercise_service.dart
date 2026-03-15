import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/treinos/models/exercicio_model.dart';

class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Busca os exercícios do Sistema + Os exercícios que o próprio Personal criou
  Future<List<ExercicioItem>> buscarBibliotecaCompleta() async {
    final personalId = _auth.currentUser?.uid;
    List<ExercicioItem> biblioteca = [];

    try {
      // 1. Busca os exercícios do sistema (onde personalId é nulo)
      final baseSnapshot = await _db
          .collection('exercicios_base')
          .where('personalId', isNull: true)
          .get();

      biblioteca.addAll(
        baseSnapshot.docs.map((doc) => ExercicioItem.fromFirestore(doc.data())),
      );

      // 2. Busca os exercícios customizados deste personal
      if (personalId != null) {
        final customSnapshot = await _db
            .collection('exercicios_base')
            .where('personalId', isEqualTo: personalId)
            .get();

        biblioteca.addAll(
          customSnapshot.docs.map(
            (doc) => ExercicioItem.fromFirestore(doc.data()),
          ),
        );
      }

      // Ordena a lista em ordem alfabética para ficar organizado
      biblioteca.sort((a, b) => a.nome.compareTo(b.nome));

      return biblioteca;
    } catch (e) {
      throw Exception('Erro ao carregar biblioteca: $e');
    }
  }

  // Salva um exercício novo criado pelo Personal
  Future<void> criarExercicioCustomizado(ExercicioItem exercicio) async {
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Utilizador não autenticado');

    exercicio.personalId = personalId;

    try {
      await _db.collection('exercicios_base').add(exercicio.toFirestore());
    } catch (e) {
      throw Exception('Erro ao criar exercício: $e');
    }
  }
}
