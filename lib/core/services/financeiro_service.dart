import 'package:supabase_flutter/supabase_flutter.dart';

class FaturaModel {
  final String id;
  final String alunoId;
  final double valor;
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final String status;
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

  factory FaturaModel.fromSupabase(Map<String, dynamic> data) {
    return FaturaModel(
      id: data['id'].toString(),
      alunoId: data['aluno_id'] ?? '',
      valor: (data['valor'] ?? 0.0).toDouble(),
      dataVencimento: DateTime.tryParse(data['data_vencimento'].toString()) ?? DateTime.now(),
      dataPagamento: data['data_pagamento'] != null 
          ? DateTime.tryParse(data['data_pagamento'].toString()) 
          : null,
      status: data['status'] ?? 'pendente',
      descricao: data['descricao'] ?? '',
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'aluno_id': alunoId,
      'valor': valor,
      'data_vencimento': dataVencimento.toIso8601String(),
      'data_pagamento': dataPagamento?.toIso8601String(),
      'status': status,
      'descricao': descricao,
    };
  }
}

class FinanceiroService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<FaturaModel>> getFaturasStream(String alunoId) {
    return _supabase
        .from('faturas')
        .stream(primaryKey: ['id'])
        .eq('aluno_id', alunoId)
        .order('data_vencimento', ascending: false)
        .map((data) => data.map((json) => FaturaModel.fromSupabase(json)).toList());
  }

  Future<void> criarFatura(FaturaModel fatura) async {
    try {
      await _supabase.from('faturas').insert(fatura.toSupabase());
    } catch (e) {
      throw Exception('Erro ao criar fatura: $e');
    }
  }

  Future<void> marcarComoPaga(String faturaId) async {
    try {
      await _supabase.from('faturas').update({
        'status': 'pago',
        'data_pagamento': DateTime.now().toIso8601String(),
      }).eq('id', faturaId);
    } catch (e) {
      throw Exception('Erro ao pagar fatura: $e');
    }
  }

  Future<void> excluirFatura(String faturaId) async {
    try {
      await _supabase.from('faturas').delete().eq('id', faturaId);
    } catch (e) {
      throw Exception('Erro ao excluir fatura: $e');
    }
  }
}