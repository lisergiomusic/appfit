import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/rotina_service.dart';
import 'models/rotina_model.dart';

class RotinaDetalheController extends ChangeNotifier {
  final String? rotinaId;
  final String? alunoId;
  final RotinaService _rotinaService;

  late TextEditingController nomeCtrl;
  late TextEditingController objCtrl;
  String tipoVencimento = 'sessoes';
  int vencimentoSessoes = 20;
  DateTime vencimentoData = DateTime.now().add(const Duration(days: 30));
  List<SessaoTreinoModel> treinos = [];

  bool isSaving = false;
  bool isDeleting = false;

  final Map<String, dynamic>? initialData;

  RotinaDetalheController({
    this.rotinaId,
    this.alunoId,
    RotinaService? rotinaService,
    this.initialData,
  }) : _rotinaService = rotinaService ?? RotinaService() {
    nomeCtrl = TextEditingController(text: initialData?['nome'] ?? '');
    objCtrl = TextEditingController(text: initialData?['objetivo'] ?? '');
    _preencherDados();
    
    nomeCtrl.addListener(notifyListeners);
    objCtrl.addListener(notifyListeners);
  }

  void _preencherDados() {
    if (initialData != null) {
      tipoVencimento = initialData!['tipoVencimento'] ?? 'data';

      if (tipoVencimento == 'sessoes') {
        vencimentoSessoes = initialData!['vencimentoSessoes'] ?? 20;
      } else {
        if (initialData!['dataVencimento'] != null) {
          vencimentoData = (initialData!['dataVencimento'] as Timestamp).toDate();
        }
      }

      final rotinaModel = RotinaModel.fromFirestore(initialData!, rotinaId);
      treinos = rotinaModel.sessoes;
    }
  }

  bool verificarAlteracoes() {
    if (rotinaId == null) {
      return nomeCtrl.text.trim().isNotEmpty ||
          objCtrl.text.trim().isNotEmpty ||
          treinos.isNotEmpty;
    }

    final data = initialData!;
    if (nomeCtrl.text.trim() != (data['nome'] ?? '')) return true;
    if (objCtrl.text.trim() != (data['objetivo'] ?? '')) return true;
    if (tipoVencimento != (data['tipoVencimento'] ?? 'data')) return true;

    if (tipoVencimento == 'sessoes') {
      if (vencimentoSessoes != (data['vencimentoSessoes'] ?? 20)) return true;
    } else {
      final oldDate = (data['dataVencimento'] as Timestamp?)?.toDate();
      if (oldDate == null ||
          vencimentoData.day != oldDate.day ||
          vencimentoData.month != oldDate.month ||
          vencimentoData.year != oldDate.year) {
        return true;
      }
    }

    List<dynamic> sessoesRaw = data['sessoes'] ?? [];
    if (treinos.length != sessoesRaw.length) return true;

    // Simplified check: if any session data changed or exercises count changed
    for (int i = 0; i < treinos.length; i++) {
      final sessao = treinos[i];
      final sessaoRaw = sessoesRaw[i];

      if (sessao.nome != sessaoRaw['nome']) return true;
      if ((sessao.diaSemana ?? '') != (sessaoRaw['diaSemana'] ?? '')) return true;
      if ((sessao.orientacoes ?? '') != (sessaoRaw['orientacoes'] ?? '')) return true;

      final List<dynamic> exerciciosRaw = sessaoRaw['exercicios'] ?? [];
      if (sessao.exercicios.length != exerciciosRaw.length) return true;

      for (int j = 0; j < sessao.exercicios.length; j++) {
        final ex = sessao.exercicios[j];
        final exRaw = exerciciosRaw[j] as Map<String, dynamic>;

        if (ex.nome != (exRaw['nome'] ?? '')) return true;

        final List<dynamic> seriesRaw = exRaw['series'] ?? [];
        if (ex.series.length != seriesRaw.length) return true;

        for (int k = 0; k < ex.series.length; k++) {
          final s = ex.series[k];
          final sRaw = seriesRaw[k] as Map<String, dynamic>;
          if (s.tipo.name != (sRaw['tipo'] ?? '') ||
              s.alvo != (sRaw['alvo'] ?? '') ||
              s.carga != (sRaw['carga'] ?? '') ||
              s.descanso != (sRaw['descanso'] ?? '')) {
            return true;
          }
        }
      }
    }

    return false;
  }

  void atualizarConfiguracoes({
    required String nome,
    required String objetivo,
    required String tipo,
    required int sessoes,
    required DateTime data,
  }) {
    nomeCtrl.text = nome;
    objCtrl.text = objetivo;
    tipoVencimento = tipo;
    vencimentoSessoes = sessoes;
    vencimentoData = data;
    notifyListeners();
  }

  void adicionarSessao(String nome, String? dia, String notas) {
    treinos.add(SessaoTreinoModel(nome: nome, diaSemana: dia, orientacoes: notas));
    notifyListeners();
  }

  void atualizarSessao(int index, String nome, String? dia, String notas) {
    treinos[index].nome = nome;
    treinos[index].diaSemana = dia;
    treinos[index].orientacoes = notas;
    notifyListeners();
  }

  void removerSessao(int index) {
    treinos.removeAt(index);
    notifyListeners();
  }

  Future<bool> excluirRotina() async {
    if (rotinaId == null) return false;
    isDeleting = true;
    notifyListeners();
    try {
      await _rotinaService.excluirRotina(rotinaId!);
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir rotina: $e');
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<bool> salvarRotina() async {
    final String nomeParaSalvar = nomeCtrl.text.trim();
    final String objetivoParaSalvar = objCtrl.text.trim();

    if (rotinaId == null && nomeParaSalvar.isEmpty && treinos.isEmpty) {
      return true;
    }

    if (nomeParaSalvar.isEmpty || objetivoParaSalvar.isEmpty || treinos.isEmpty) {
      return false;
    }

    isSaving = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> sessoesJson = treinos.map((t) => t.toFirestore()).toList();

      if (rotinaId != null) {
        await _rotinaService.atualizarRotina(
          rotinaId: rotinaId!,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: tipoVencimento,
          sessoesAlvo: tipoVencimento == 'sessoes' ? vencimentoSessoes : null,
          dataVencimento: tipoVencimento == 'data' ? vencimentoData : null,
        );
      } else {
        await _rotinaService.criarRotina(
          alunoId: alunoId,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: tipoVencimento,
          sessoesAlvo: tipoVencimento == 'sessoes' ? vencimentoSessoes : null,
          dataVencimento: tipoVencimento == 'data' ? vencimentoData : null,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar rotina: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    objCtrl.dispose();
    super.dispose();
  }
}
