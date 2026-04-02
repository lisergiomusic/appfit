import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../../features/alunos/models/aluno_perfil_data.dart';

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
    DateTime? dataNascimento,
    String? objetivos,
    String? genero,
  }) async {
    final Map<String, dynamic> data = {
      'nome': nome,
      'sobrenome': sobrenome,
      'email': email,
    };

    if (telefone != null) data['telefone'] = telefone;
    if (peso != null) data['pesoAtual'] = peso;
    if (dataNascimento != null)
      data['dataNascimento'] = Timestamp.fromDate(dataNascimento);
    if (objetivos != null) data['objetivos'] = objetivos;
    if (genero != null) data['genero'] = genero;

    await _firestore.collection('usuarios').doc(alunoId).update(data);
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

    final total = await baseQuery.count().get();
    final ativos = await baseQuery
        .where('status', isEqualTo: 'ativo')
        .count()
        .get();
    final inativos = await baseQuery
        .where('status', isEqualTo: 'inativo')
        .count()
        .get();

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final risco = await baseQuery
        .where('status', isEqualTo: 'ativo')
        .where(
          'ultimoTreino',
          isLessThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .count()
        .get();

    return ContagemAlunos(
      total: total.count ?? 0,
      ativos: ativos.count ?? 0,
      inativos: inativos.count ?? 0,
      risco: risco.count ?? 0,
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

  /// Combina os dados do aluno e sua rotina ativa em um único Stream
  Stream<AlunoPerfilData> getAlunoPerfilCompletoStream(String alunoId) {
    final alunoStream = getAlunoStream(alunoId);

    final rotinaStream = _firestore
        .collection('rotinas')
        .where('alunoId', isEqualTo: alunoId)
        .where('ativa', isEqualTo: true)
        .limit(1)
        .snapshots();

    return Rx.combineLatest2<DocumentSnapshot, QuerySnapshot, AlunoPerfilData>(
      alunoStream,
      rotinaStream,
      (alunoSnap, rotinaSnap) {
        final alunoMap = alunoSnap.data() as Map<String, dynamic>? ?? {};
        final rotinaMap = rotinaSnap.docs.isNotEmpty
            ? rotinaSnap.docs.first.data() as Map<String, dynamic>?
            : null;
        final rotinaId = rotinaSnap.docs.isNotEmpty
            ? rotinaSnap.docs.first.id
            : null;

        return AlunoPerfilData(
          aluno: alunoMap,
          rotinaAtiva: rotinaMap,
          rotinaId: rotinaId,
        );
      },
    );
  }

  Stream<QuerySnapshot> getRotinasTemplates() {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isNull: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPlanilhasStream(String alunoId) {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isEqualTo: alunoId)
        .snapshots();
  }

  Stream<QuerySnapshot> getRotinaAtivaStream(String alunoId) {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isEqualTo: alunoId)
        .where('ativa', isEqualTo: true)
        .snapshots();
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

    for (var doc in rotinasAntigas.docs) {
      await doc.reference.update({'ativa': false});
    }

    final rotinaData = templateDoc.data() as Map<String, dynamic>;
    rotinaData['alunoId'] = alunoId;
    rotinaData['ativa'] = true;
    rotinaData['dataCriacao'] = FieldValue.serverTimestamp();
    rotinaData['tipoVencimento'] = tipoVencimento;

    if (tipoVencimento == 'sessoes') {
      rotinaData['vencimentoSessoes'] = sessoesAlvo;
      rotinaData.remove('dataVencimento');
    } else {
      rotinaData['dataVencimento'] = Timestamp.fromDate(
        dataVencimento ?? DateTime.now().add(const Duration(days: 30)),
      );
      rotinaData.remove('vencimentoSessoes');
    }

    await _firestore.collection('rotinas').add(rotinaData);
  }
}
