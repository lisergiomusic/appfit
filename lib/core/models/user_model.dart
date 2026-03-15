import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nome;
  final String email;
  final String tipoUsuario;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.isAdmin = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      tipoUsuario: data['tipoUsuario'] ?? 'aluno',
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'email': email,
      'tipoUsuario': tipoUsuario,
      'isAdmin': isAdmin,
    };
  }
}
