import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../../features/alunos/shared/models/aluno_perfil_data.dart';

class PaginatedAlunos {
  final List<DocumentSnapshot> docs;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  PaginatedAlunos({required this.docs, this.lastDoc, required this.hasMore});
}

class ContagemAlunos {
  final int total;
  final int ativos;
  final int inativos;
  final int risco;

  ContagemAlunos({
    required this.total,
    required this.ativos,
    required this.inativos,
    required this.risco,
  });
}

class AlunoService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AlunoService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get _currentPersonalId => _auth.currentUser?.uid;

  Future<void> salvarAluno(
    String nome,
    String sobrenome,
    String email, {
    String? whatsapp,
    String? genero,
    DateTime? dataNascimento,
  }) async {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    final Map<String, dynamic> data = {
      'nome': nome,
      'sobrenome': sobrenome,
      'email': email,
      'tipoUsuario': 'aluno',
      'status': 'ativo',
      'personalId': personalId,
      'dataCriacao': FieldValue.serverTimestamp(),
      'ultimoTreino': FieldValue.serverTimestamp(),
    };

    if (genero != null) data['genero'] = genero;
    if (whatsapp != null && whatsapp.trim().isNotEmpty) {
      data['telefone'] = whatsapp.trim();
    }
    if (dataNascimento != null) {
      data['dataNascimento'] = Timestamp.fromDate(dataNascimento);
    }

    await _firestore.collection('usuarios').add(data);
  }

  Future<void> atualizarAluno({
    required String alunoId,
    required String nome,
    required String sobrenome,
    required String email,
    String? telefone,
    double? peso,
    double? altura,
    DateTime? dataNascimento,
    String? genero,
    String? recadoPersonal,
  }) async {
    final Map<String, dynamic> data = {
      'nome': nome,
      'sobrenome': sobrenome,
      'email': email,
    };

    if (telefone != null) data['telefone'] = telefone;
    if (peso != null) data['pesoAtual'] = peso;
    if (altura != null) data['alturaAtual'] = altura;
    if (dataNascimento != null) {
      data['dataNascimento'] = Timestamp.fromDate(dataNascimento);
    }
    if (genero != null) data['genero'] = genero;
    if (recadoPersonal != null) data['recadoPersonal'] = recadoPersonal;

    await _firestore.collection('usuarios').doc(alunoId).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getAluno(String alunoId) async {
    return await _firestore.collection('usuarios').doc(alunoId).get();
  }

  Future<void> deletarAluno(String alunoId) async {
    await _firestore.collection('usuarios').doc(alunoId).delete();
  }

  Future<ContagemAlunos> fetchContagens() async {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    final baseQuery = _firestore
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'aluno')
        .where('personalId', isEqualTo: personalId);

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Executa as contagens em paralelo para ganhar performance
    final results = await Future.wait([
      baseQuery.count().get(),
      baseQuery.where('status', isEqualTo: 'ativo').count().get(),
      baseQuery.where('status', isEqualTo: 'inativo').count().get(),
      baseQuery
          .where('status', isEqualTo: 'ativo')
          .where(
            'ultimoTreino',
            isLessThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .count()
          .get(),
    ]);

    return ContagemAlunos(
      total: results[0].count ?? 0,
      ativos: results[1].count ?? 0,
      inativos: results[2].count ?? 0,
      risco: results[3].count ?? 0,
    );
  }

  Future<PaginatedAlunos> fetchAlunosPaginado({
    required String statusFilter,
    required String searchQuery,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    Query query = _firestore
        .collection('usuarios')
        .where('tipoUsuario', isEqualTo: 'aluno')
        .where('personalId', isEqualTo: personalId);

    if (statusFilter == "ativo") {
      query = query.where('status', isEqualTo: 'ativo');
    } else if (statusFilter == "inativo") {
      query = query.where('status', isEqualTo: 'inativo');
    } else if (statusFilter == "risco") {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      query = query
          .where('status', isEqualTo: 'ativo')
          .where(
            'ultimoTreino',
            isLessThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          );
    }

    if (searchQuery.isNotEmpty) {
      query = query
          .where('nome', isGreaterThanOrEqualTo: searchQuery)
          .where('nome', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }

    query = query.orderBy('nome').limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();

    return PaginatedAlunos(
      docs: snapshot.docs,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Stream<DocumentSnapshot> getAlunoStream(String alunoId) {
    return _firestore.collection('usuarios').doc(alunoId).snapshots();
  }

  /// Stream reativa e otimizada para o perfil do aluno.
  /// Agora que os índices estão criados, podemos usar a combinação de streams
  /// para garantir que mudanças na rotina reflitam instantaneamente na UI.
  Stream<AlunoPerfilData> getAlunoPerfilCompletoStream(String alunoId) {
    return _firestore
        .collection('usuarios')
        .doc(alunoId)
        .snapshots()
        .switchMap((alunoSnap) {
      final alunoMap = alunoSnap.data() as Map<String, dynamic>? ?? {};
      final personalId = alunoMap['personalId'] as String?;

      // Stream da Rotina Ativa
      final rotinaStream = _firestore
          .collection('rotinas')
          .where('alunoId', isEqualTo: alunoId)
          .where('ativa', isEqualTo: true)
          .limit(1)
          .snapshots();

      // Stream do Personal (ou valor nulo se não houver)
      final personalStream = personalId != null
          ? _firestore
              .collection('usuarios')
              .doc(personalId)
              .snapshots()
              .map((doc) => doc as DocumentSnapshot?)
              .startWith(null)
          : Stream<DocumentSnapshot?>.value(null);

      return Rx.combineLatest2<QuerySnapshot, DocumentSnapshot?,
          AlunoPerfilData>(
        rotinaStream,
        personalStream,
        (rotinaSnap, personalSnap) {
          final rotinaDoc =
              rotinaSnap.docs.isNotEmpty ? rotinaSnap.docs.first : null;
          final personalMap =
              personalSnap?.data() as Map<String, dynamic>? ?? {};
          
          final pNome = personalMap['nome']?.toString() ?? '';
          final pSobrenome = personalMap['sobrenome']?.toString() ?? '';
          final pNomeCompleto = '$pNome $pSobrenome'.trim();

          return AlunoPerfilData(
            aluno: alunoMap,
            rotinaAtiva: rotinaDoc?.data(),
            rotinaId: rotinaDoc?.id,
            nomePersonal: pNomeCompleto.isNotEmpty ? pNomeCompleto : null,
            especialidadePersonal: personalMap['especialidade']?.toString(),
            photoUrlPersonal: personalMap['photoUrl']?.toString(),
            telefonePersonal: personalMap['telefone']?.toString(),
          );
        },
      );
    });
  }

  Stream<QuerySnapshot> getRotinasTemplates() {
    final personalId = _currentPersonalId;
    if (personalId == null) return const Stream.empty();

    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isNull: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPlanilhasStream(String alunoId) {
    final personalId = _currentPersonalId;
    if (personalId == null) return const Stream.empty();

    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isEqualTo: alunoId)
        .snapshots();
  }

  Stream<QuerySnapshot> getRotinaAtivaStream(String alunoId) {
    final personalId = _currentPersonalId;
    if (personalId == null) return const Stream.empty();

    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isEqualTo: alunoId)
        .where('ativa', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getLogsDaSemanaStream(String alunoId) {
    final agora = DateTime.now();
    final segundaFeira = DateTime(
      agora.year,
      agora.month,
      agora.day - (agora.weekday - 1),
    );

    return _firestore
        .collection('logs_treino')
        .where('alunoId', isEqualTo: alunoId)
        .where(
          'dataHora',
          isGreaterThanOrEqualTo: Timestamp.fromDate(segundaFeira),
        )
        .snapshots();
  }

  Stream<QuerySnapshot> getUltimoLogStream(String alunoId) {
    return _firestore
        .collection('logs_treino')
        .where('alunoId', isEqualTo: alunoId)
        .orderBy('dataHora', descending: true)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot> getHistoricoPesoStream(String alunoId) {
    return _firestore
        .collection('usuarios')
        .doc(alunoId)
        .collection('historico_peso')
        .orderBy('dataHora', descending: true)
        .snapshots();
  }

  Future<void> registrarPeso({
    required String alunoId,
    required double peso,
  }) async {
    final agora = Timestamp.now();

    await _firestore
        .collection('usuarios')
        .doc(alunoId)
        .collection('historico_peso')
        .add({'peso': peso, 'dataHora': agora});

    await _firestore.collection('usuarios').doc(alunoId).set({'pesoAtual': peso}, SetOptions(merge: true));
  }

  Future<void> atribuirTreinoAoAluno({
    required String alunoId,
    required String templateId,
    required String tipoVencimento,
    int? sessoesAlvo,
    DateTime? dataVencimento,
  }) async {
    final templateDoc = await _firestore
        .collection('rotinas')
        .doc(templateId)
        .get();
    if (!templateDoc.exists) return;

    final rotinasAntigas = await _firestore
        .collection('rotinas')
        .where('alunoId', isEqualTo: alunoId)
        .where('ativa', isEqualTo: true)
        .get();

    final rotinaData = templateDoc.data() as Map<String, dynamic>;
    rotinaData['alunoId'] = alunoId;
    rotinaData['ativa'] = true;
    rotinaData['dataCriacao'] = FieldValue.serverTimestamp();
    rotinaData['tipoVencimento'] = tipoVencimento;

    if (tipoVencimento == 'sessoes') {
      rotinaData['vencimentoSessoes'] = sessoesAlvo;
      rotinaData['sessoesConcluidas'] = 0;
      rotinaData.remove('dataVencimento');
    } else {
      rotinaData['dataVencimento'] = Timestamp.fromDate(
        dataVencimento ?? DateTime.now().add(const Duration(days: 30)),
      );
      rotinaData.remove('vencimentoSessoes');
    }

    final novaRotinaRef = _firestore.collection('rotinas').doc();
    final batch = _firestore.batch();

    for (var doc in rotinasAntigas.docs) {
      batch.update(doc.reference, {'ativa': false});
    }
    batch.set(novaRotinaRef, rotinaData);

    await batch.commit();
  }

  Future<({List<AtividadeRecenteItem> items, DocumentSnapshot? lastDoc})>
      fetchAtividadePage({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final personalId = _currentPersonalId;
    if (personalId == null) {
      return (items: <AtividadeRecenteItem>[], lastDoc: null);
    }

    var query = _firestore
        .collection('logs_treino')
        .where('personalId', isEqualTo: personalId)
        .orderBy('dataHora', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      return (items: <AtividadeRecenteItem>[], lastDoc: null);
    }

    final alunoIds = snapshot.docs
        .map((doc) => doc.data()['alunoId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final alunoFutures = alunoIds.map((id) => _firestore
        .collection('usuarios')
        .doc(id)
        .get()
        .then((d) => MapEntry(id, Map<String, dynamic>.from(d.data() ?? {})))
        .catchError((_) => MapEntry(id, <String, dynamic>{})));

    final alunoEntries = await Future.wait(alunoFutures);
    final alunoCache = Map<String, Map<String, dynamic>>.fromEntries(alunoEntries);

    final items = <AtividadeRecenteItem>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final alunoId = data['alunoId'] as String? ?? '';
      final aluno = alunoCache[alunoId] ?? {};

      items.add(AtividadeRecenteItem(
        logId: doc.id,
        alunoId: alunoId,
        alunoNome: aluno['nome']?.toString() ?? 'Aluno',
        alunoPhotoUrl: aluno['photoUrl']?.toString(),
        sessaoNome: data['sessaoNome']?.toString() ?? '',
        dataHora:
            (data['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
        duracaoMinutos: (data['duracaoMinutos'] as num?)?.toInt() ?? 0,
        esforco: (data['esforco'] as num?)?.toInt(),
        observacoes: data['observacoes']?.toString(),
        exercicios:
            (data['exercicios'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      ));
    }

    final lastDoc =
        snapshot.docs.length == limit ? snapshot.docs.last : null;
    return (items: items, lastDoc: lastDoc);
  }

  /// Stream dos N logs mais recentes dos alunos do personal logado,
  /// enriquecidos com nome e photoUrl do aluno.
  /// Os docs de aluno são buscados em paralelo via Future.wait para evitar
  /// latência acumulada de gets sequenciais.
  Stream<List<AtividadeRecenteItem>> getAtividadeRecenteStream({int limit = 10}) {
    final personalId = _currentPersonalId;
    if (personalId == null) return const Stream.empty();

    return _firestore
        .collection('logs_treino')
        .where('personalId', isEqualTo: personalId)
        .orderBy('dataHora', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return <AtividadeRecenteItem>[];

      // Coleta IDs únicos de alunos e busca todos em paralelo.
      final alunoIds = snapshot.docs
          .map((doc) => doc.data()['alunoId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final alunoFutures = alunoIds.map((id) => _firestore
          .collection('usuarios')
          .doc(id)
          .get()
          .then((d) => MapEntry(id, Map<String, dynamic>.from(d.data() ?? {})))
          .catchError((_) => MapEntry(id, <String, dynamic>{})));

      final alunoEntries = await Future.wait(alunoFutures);
      final alunoCache = Map<String, Map<String, dynamic>>.fromEntries(alunoEntries);

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final alunoId = data['alunoId'] as String? ?? '';
        final aluno = alunoCache[alunoId] ?? {};

        return AtividadeRecenteItem(
          logId: doc.id,
          alunoId: alunoId,
          alunoNome: aluno['nome']?.toString() ?? 'Aluno',
          alunoPhotoUrl: aluno['photoUrl']?.toString(),
          sessaoNome: data['sessaoNome']?.toString() ?? '',
          dataHora: (data['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
          duracaoMinutos: (data['duracaoMinutos'] as num?)?.toInt() ?? 0,
          esforco: (data['esforco'] as num?)?.toInt(),
          observacoes: data['observacoes']?.toString(),
          exercicios: (data['exercicios'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [],
        );
      }).toList();
    });
  }
}

class AtividadeRecenteItem {
  final String logId;
  final String alunoId;
  final String alunoNome;
  final String? alunoPhotoUrl;
  final String sessaoNome;
  final DateTime dataHora;
  final int duracaoMinutos;
  final int? esforco;
  final String? observacoes;
  final List<Map<String, dynamic>> exercicios;

  const AtividadeRecenteItem({
    required this.logId,
    required this.alunoId,
    required this.alunoNome,
    this.alunoPhotoUrl,
    required this.sessaoNome,
    required this.dataHora,
    required this.duracaoMinutos,
    this.esforco,
    this.observacoes,
    required this.exercicios,
  });
}