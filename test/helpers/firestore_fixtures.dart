import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreFixtures {
  static Map<String, dynamic> aluno({
    String nome = 'João',
    String sobrenome = 'Silva',
    String personalId = 'personal_123',
    DateTime? ultimoTreino,
  }) {
    return {
      'nome': nome,
      'sobrenome': sobrenome,
      'email': 'joao@email.com',
      'tipoUsuario': 'aluno',
      'status': 'ativo',
      'personalId': personalId,
      'ultimoTreino': Timestamp.fromDate(ultimoTreino ?? DateTime.now()),
    };
  }

  static Map<String, dynamic> personal({
    String nome = 'Personal',
    String sobrenome = 'Trainer',
  }) {
    return {
      'nome': nome,
      'sobrenome': sobrenome,
      'tipoUsuario': 'personal',
    };
  }

  static Map<String, dynamic> rotina({
    required String alunoId,
    bool ativa = true,
    int sessoesConcluidas = 0,
  }) {
    return {
      'alunoId': alunoId,
      'ativa': ativa,
      'nome': 'Treino de Hipertrofia',
      'sessoesConcluidas': sessoesConcluidas,
    };
  }

  static Map<String, dynamic> logTreino({
    required String alunoId,
    required String rotinaId,
    DateTime? dataHora,
    String sessaoNome = 'Treino A',
    int esforco = 0,
  }) {
    final data = {
      'alunoId': alunoId,
      'rotinaId': rotinaId,
      'sessaoNome': sessaoNome,
      'dataHora': Timestamp.fromDate(dataHora ?? DateTime.now()),
      'duracaoMinutos': 45,
      'exercicios': [],
    };
    if (esforco > 0) {
      data['esforco'] = esforco;
    }
    return data;
  }
}