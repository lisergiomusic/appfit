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
      final baseSnapshot = await _db
          .collection('exercicios_base')
          .where('personalId', isNull: true)
          .get();

      biblioteca.addAll(
        baseSnapshot.docs.map((doc) => ExercicioItem.fromFirestore(doc.data())),
      );

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

  // --- SCRIPT DE SEED (BIOMECÂNICA CORRIGIDA) ---
  Future<void> semearExerciciosBase() async {
    final List<ExercicioItem> exerciciosSemente = [
      // PEITO
      ExercicioItem(
        nome: 'Supino Reto (Barra)',
        grupoMuscular: 'Peito, Ombros, Tríceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Supino Inclinado (Halteres)',
        grupoMuscular: 'Peito, Ombros, Tríceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Crossover (Polia)',
        grupoMuscular: 'Peito, Ombros',
        series: [],
      ),
      ExercicioItem(
        nome: 'Voador / Peck Deck (Máquina)',
        grupoMuscular: 'Peito, Ombros',
        series: [],
      ),
      ExercicioItem(
        nome: 'Crucifixo Reto (Halteres)',
        grupoMuscular: 'Peito, Ombros',
        series: [],
      ),

      // COSTAS
      ExercicioItem(
        nome: 'Puxada Frontal (Polia)',
        grupoMuscular: 'Costas, Bíceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Remada Curvada (Barra)',
        grupoMuscular: 'Costas, Bíceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Remada Baixa (Polia)',
        grupoMuscular: 'Costas, Bíceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Pulldown (Polia)',
        grupoMuscular: 'Costas',
        series: [],
      ),
      ExercicioItem(
        nome: 'Levantamento Terra (Barra)',
        grupoMuscular: 'Costas, Pernas, Glúteos',
        series: [],
      ),

      // PERNAS & GLÚTEOS
      ExercicioItem(
        nome: 'Agachamento Livre (Barra)',
        grupoMuscular: 'Pernas, Glúteos',
        series: [],
      ),
      ExercicioItem(
        nome: 'Leg Press 45° (Máquina)',
        grupoMuscular: 'Pernas, Glúteos',
        series: [],
      ),
      ExercicioItem(
        nome: 'Cadeira Extensora (Máquina)',
        grupoMuscular: 'Pernas',
        series: [],
      ),
      ExercicioItem(
        nome: 'Mesa Flexora (Máquina)',
        grupoMuscular: 'Pernas',
        series: [],
      ),
      ExercicioItem(
        nome: 'Elevação Pélvica (Máquina)',
        grupoMuscular: 'Glúteos, Pernas',
        series: [],
      ),
      ExercicioItem(
        nome: 'Cadeira Abdutora (Máquina)',
        grupoMuscular: 'Glúteos',
        series: [],
      ),
      ExercicioItem(
        nome: 'Panturrilha em Pé (Máquina)',
        grupoMuscular: 'Pernas',
        series: [],
      ),

      // OMBROS
      ExercicioItem(
        nome: 'Desenvolvimento (Halteres)',
        grupoMuscular: 'Ombros, Tríceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Elevação Lateral (Halteres)',
        grupoMuscular: 'Ombros',
        series: [],
      ),
      ExercicioItem(
        nome: 'Elevação Frontal (Polia)',
        grupoMuscular: 'Ombros, Peito',
        series: [],
      ),
      ExercicioItem(
        nome: 'Crucifixo Inverso (Máquina)',
        grupoMuscular: 'Ombros, Costas',
        series: [],
      ),
      ExercicioItem(
        nome: 'Encolhimento (Halteres)',
        grupoMuscular: 'Ombros, Costas',
        series: [],
      ),

      // TRÍCEPS
      ExercicioItem(
        nome: 'Tríceps Pulley (Polia)',
        grupoMuscular: 'Tríceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Tríceps Testa (Corda)',
        grupoMuscular: 'Tríceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Tríceps Francês (Halteres)',
        grupoMuscular: 'Tríceps',
        series: [],
      ),

      // BÍCEPS
      ExercicioItem(
        nome: 'Rosca Direta (Barra)',
        grupoMuscular: 'Bíceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Rosca Martelo (Halteres)',
        grupoMuscular: 'Bíceps',
        series: [],
      ),
      ExercicioItem(
        nome: 'Rosca Scott (Máquina)',
        grupoMuscular: 'Bíceps',
        series: [],
      ),

      // ABDÔMEN
      ExercicioItem(
        nome: 'Abdominal Supra (Livre)',
        grupoMuscular: 'Abdômen',
        series: [],
      ),
      ExercicioItem(
        nome: 'Prancha Isométrica (Livre)',
        grupoMuscular: 'Abdômen',
        series: [],
      ),
      ExercicioItem(
        nome: 'Abdominal Infra (Barra)',
        grupoMuscular: 'Abdômen',
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
