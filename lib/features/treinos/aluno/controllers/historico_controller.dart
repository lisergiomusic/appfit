import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/services/treino_service.dart';

class HistoricoController extends ChangeNotifier {
  final String uid;
  final TreinoService _treinoService = TreinoService();
  final AlunoService _alunoService = AlunoService();

  late DateTime _mesAtual;
  late Stream<List<Map<String, dynamic>>> _logsStream;
  late final Stream<dynamic> _pesoStream;

  // Cache de streams por mês para evitar flickering e re-conexões constantes
  final Map<String, Stream<List<Map<String, dynamic>>>> _streamsCache = {};

  HistoricoController({required this.uid}) {
    final hoje = DateTime.now();
    _mesAtual = DateTime(hoje.year, hoje.month);
    _pesoStream = _alunoService.getHistoricoPesoStream(uid);
    _atualizarLogsStream();
  }

  DateTime get mesAtual => _mesAtual;
  Stream<List<Map<String, dynamic>>> get logsStream => _logsStream;
  Stream<dynamic> get pesoStream => _pesoStream;

  void _atualizarLogsStream() {
    final chave = '${_mesAtual.year}-${_mesAtual.month}';
    if (!_streamsCache.containsKey(chave)) {
      final inicio = DateTime(_mesAtual.year, _mesAtual.month, 1);
      final fim = DateTime(_mesAtual.year, _mesAtual.month + 1, 1)
          .subtract(const Duration(seconds: 1));
      _streamsCache[chave] =
          _treinoService.getLogsIntervalStream(uid, inicio, fim);
    }
    _logsStream = _streamsCache[chave]!;
  }

  void irParaMesAnterior() {
    _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1);
    _atualizarLogsStream();
    notifyListeners();
  }

  void irParaProximoMes() {
    final hoje = DateTime.now();
    final mesHoje = DateTime(hoje.year, hoje.month);
    if (_mesAtual.isBefore(mesHoje)) {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1);
      _atualizarLogsStream();
      notifyListeners();
    }
  }

  bool get isUltimoMes {
    final hoje = DateTime.now();
    final mesHoje = DateTime(hoje.year, hoje.month);
    return !_mesAtual.isBefore(mesHoje);
  }

  Map<DateTime, List<Map<String, dynamic>>> processarLogs(
      List<Map<String, dynamic>> logs) {
    final result = <DateTime, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final tsRaw = log['dataHora'];
      final ts = tsRaw != null ? DateTime.tryParse(tsRaw.toString()) : null;
      if (ts == null) continue;
      final dia = DateTime(ts.year, ts.month, ts.day);
      result.putIfAbsent(dia, () => []).add(log);
    }
    return result;
  }

  Future<void> registrarPeso(double peso) async {
    await _alunoService.registrarPeso(alunoId: uid, peso: peso);
    // O stream de peso será atualizado automaticamente pelo Supabase Realtime
  }
}