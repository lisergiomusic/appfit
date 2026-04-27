import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> migrarBibliotecaExercicios() async {
    int sucessos = 0;
    int erros = 0;
    List<String> logs = [];

    try {
      dev.log('Buscando exercícios no Firestore...');
      final snapshot = await _firestore.collection('exercicios_base').get();
      
      final totalNoFirestore = snapshot.docs.length;
      
      if (totalNoFirestore == 0) {
        return {
          'total': 0,
          'sucessos': 0,
          'erros': 0,
          'logs': ['A coleção está vazia no Firestore.']
        };
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final nome = data['nome'] ?? 'Sem Nome';

        try {
          await _supabase.from('exercicios_base').insert({
            'nome': nome,
            'grupo_muscular': data['grupoMuscular'] is List 
                ? data['grupoMuscular'] 
                : [data['grupoMuscular'] ?? 'Geral'],
            'tipo_alvo': data['tipoAlvo'] ?? 'Reps',
            'imagem_url': data['imagemUrl'],
            'media_url': data['mediaUrl'],
            'instrucoes': data['instrucoes'],
            'personal_id': null,
          });
          
          sucessos++;
          logs.add('✅ $nome');
        } catch (e) {
          erros++;
          logs.add('❌ $nome: $e');
        }
      }

      return {
        'total': totalNoFirestore,
        'sucessos': sucessos,
        'erros': erros,
        'logs': logs
      };
    } catch (e) {
      return {'erro': e.toString()};
    }
  }
}