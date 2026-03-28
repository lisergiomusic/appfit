import 'package:cloud_firestore/cloud_firestore.dart';

class FaturaModel {
  final String id;
  final String alunoId;
  final double valor;
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final String status; // 'pendente', 'pago', 'atrasado'
  final String descricao;

  FaturaModel({
    required this.id,
    required this.alunoId,
    required this.valor,
    required this.dataVencimento,
    this.dataPagamento,
    required this.status,
    required this.descricao,
  });

  factory FaturaModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FaturaModel(
      id: doc.id,
      alunoId: data['alunoId'] ?? '',
      valor: (data['valor'] ?? 0.0).toDouble(),
      dataVencimento: (data['dataVencimento'] as Timestamp).toDate(),
      dataPagamento: (data['dataPagamento'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'pendente',
      descricao: data['descricao'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alunoId': alunoId,
      'valor': valor,
      'dataVencimento': Timestamp.fromDate(dataVencimento),
      'dataPagamento': dataPagamento != null ? Timestamp.fromDate(dataPagamento!) : null,
      'status': status,
      'descricao': descricao,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
  }
}

class FinanceiroService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<FaturaModel>> getFaturasStream(String alunoId) {
    return _db
        .collection('faturas')
        .where('alunoId', isEqualTo: alunoId)
        .orderBy('dataVencimento', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FaturaModel.fromFirestore(doc)).toList());
  }

  Future<void> criarFatura(FaturaModel fatura) async {
    await _db.collection('faturas').add(fatura.toMap());
  }

  Future<void> marcarComoPaga(String faturaId) async {
    await _db.collection('faturas').doc(faturaId).update({
      'status': 'pago',
      'dataPagamento': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirFatura(String faturaId) async {
    await _db.collection('faturas').doc(faturaId).delete();
  }
}
