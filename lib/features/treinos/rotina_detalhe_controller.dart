import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/services/rotina_service.dart';
import 'models/rotina_model.dart';

class RemovedSessaoResult {
  final int index;
  final SessaoTreinoModel sessao;

  const RemovedSessaoResult({required this.index, required this.sessao});
}

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

  String get nomeRotinaExibicao =>
      nomeCtrl.text.isEmpty ? 'Nova Rotina' : nomeCtrl.text;

  String get objetivoExibicao =>
      objCtrl.text.isEmpty ? 'Defina o objetivo' : objCtrl.text;

  bool get canReorderSessoes => treinos.length >= 2;

  String get vencimentoLabel {
    if (tipoVencimento == 'sessoes') {
      if (vencimentoSessoes <= 0) {
        return 'Sem vencimento';
      }

      return '$vencimentoSessoes ${vencimentoSessoes == 1 ? 'sessão' : 'sessões'}';
    }

    return 'Vence em ${DateFormat('dd/MM/yyyy').format(vencimentoData)}';
  }

  void _preencherDados() {
    if (initialData != null) {
      tipoVencimento = initialData!['tipoVencimento'] ?? 'data';

      if (tipoVencimento == 'sessoes') {
        vencimentoSessoes = initialData!['vencimentoSessoes'] ?? 20;
      } else {
        if (initialData!['dataVencimento'] != null) {
          vencimentoData = (initialData!['dataVencimento'] as Timestamp)
              .toDate();
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
      if ((sessao.diaSemana ?? '') != (sessaoRaw['diaSemana'] ?? '')) {
        return true;
      }
      if ((sessao.orientacoes ?? '') != (sessaoRaw['orientacoes'] ?? '')) {
        return true;
      }

      final List<dynamic> exerciciosRaw = sessaoRaw['exercicios'] ?? [];
      if (sessao.exercicios.length != exerciciosRaw.length) return true;

      for (int j = 0; j < sessao.exercicios.length; j++) {
        final ex = sessao.exercicios[j];
        final exRaw = exerciciosRaw[j] as Map<String, dynamic>;

        if (ex.nome != (exRaw['nome'] ?? '')) return true;
        if ((ex.instrucoesPersonalizadas ?? '') !=
            (exRaw['instrucoesPersonalizadas'] ?? '')) {
          return true;
        }

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
    treinos.add(
      SessaoTreinoModel(nome: nome, diaSemana: dia, orientacoes: notas),
    );
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

  SessaoTreinoModel? removerSessaoComRetorno(int index) {
    if (index < 0 || index >= treinos.length) return null;
    final removida = treinos.removeAt(index);
    notifyListeners();
    return removida;
  }

  int indexOfSessao(SessaoTreinoModel sessao) {
    return treinos.indexWhere((item) => identical(item, sessao));
  }

  RemovedSessaoResult? removerSessaoPorReferencia(SessaoTreinoModel sessao) {
    final index = indexOfSessao(sessao);
    if (index < 0) return null;

    final removida = removerSessaoComRetorno(index);
    if (removida == null) return null;

    return RemovedSessaoResult(index: index, sessao: removida);
  }

  void inserirSessao(int index, SessaoTreinoModel sessao) {
    final safeIndex = index.clamp(0, treinos.length);
    treinos.insert(safeIndex, sessao);
    notifyListeners();
  }

  void onReorderSessoes(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = treinos.removeAt(oldIndex);
    treinos.insert(newIndex, item);
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

    if (nomeParaSalvar.isEmpty ||
        objetivoParaSalvar.isEmpty ||
        treinos.isEmpty) {
      return false;
    }

    isSaving = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> sessoesJson = treinos
          .map((t) => t.toFirestore())
          .toList();

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
