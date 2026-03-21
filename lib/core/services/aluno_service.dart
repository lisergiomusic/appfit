import 'package:cloud_firestore/cloud_firestore.dart';

class AlunoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Stream<DocumentSnapshot> getAlunoStream(String alunoId) {
    return _firestore
        .collection('usuarios')
        .doc(alunoId)
        .snapshots();
  }


  Stream<QuerySnapshot> getRotinasTemplates(String personalId) {
    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isNull: true)
        .snapshots();
  }
}