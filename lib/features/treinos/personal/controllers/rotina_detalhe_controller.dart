import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/rotina_service.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/models/rotina_model.dart';

class RemovedSessaoResult {
  final int index;
  final SessaoTreinoModel sessao;

  const RemovedSessaoResult({required this.index, required this.sessao});
}

class RotinaDetalheController extends ChangeNotifier {
  String? _rotinaId;
  String? get rotinaId => _rotinaId;
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

  // Debounce: evita disparar múltiplos saves em sequência rápida
  Timer? _debounceTimer;

  // Verdadeiro entre o momento em que um save foi disparado manualmente
  // e o dispose do controller — impede que _handlePop dispare um segundo write.
  bool _saveFlushed = false;

final Map<String, dynamic>? initialData;

  // Baseline para comparação de alterações — atualizado quando dados frescos chegam do Firestore.
  Map<String, dynamic>? _loadedData;

  RotinaDetalheController({
    String? rotinaId,
    this.alunoId,
    RotinaService? rotinaService,
    this.initialData,
  }) : _rotinaId = rotinaId,
       _rotinaService = rotinaService ?? RotinaService() {
    _loadedData = initialData;
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
      tipoVencimento = initialData!['tipo_vencimento'] ?? initialData!['tipoVencimento'] ?? 'data';

      if (tipoVencimento == 'sessoes') {
        vencimentoSessoes = initialData!['vencimento_sessoes'] ?? initialData!['vencimentoSessoes'] ?? 20;
      } else {
        final dataVencRaw = initialData!['data_vencimento'] ?? initialData!['dataVencimento'];
        if (dataVencRaw != null) {
          vencimentoData = DateTime.tryParse(dataVencRaw.toString()) ?? vencimentoData;
        }
      }

      final rotinaModel = RotinaModel.fromMap(initialData!, rotinaId);
      treinos = rotinaModel.sessoes;
    }
  }

  /// Recarrega todos os campos com dados frescos do banco.
  void recarregarDados(Map<String, dynamic> data) {
    _loadedData = data; // salva como baseline para verificarAlteracoes
    nomeCtrl.text = data['nome'] ?? '';
    objCtrl.text = data['objetivo'] ?? '';
    tipoVencimento = data['tipo_vencimento'] ?? data['tipoVencimento'] ?? 'data';

    if (tipoVencimento == 'sessoes') {
      vencimentoSessoes = data['vencimento_sessoes'] ?? data['vencimentoSessoes'] ?? 20;
    } else {
      final dataVencRaw = data['data_vencimento'] ?? data['dataVencimento'];
      if (dataVencRaw != null) {
        vencimentoData = DateTime.tryParse(dataVencRaw.toString()) ?? vencimentoData;
      }
    }

    final rotinaModel = RotinaModel.fromMap(data, rotinaId);
    treinos = rotinaModel.sessoes;
    notifyListeners();
  }

  bool verificarAlteracoes() {
    if (rotinaId == null) {
      return nomeCtrl.text.trim().isNotEmpty ||
          objCtrl.text.trim().isNotEmpty ||
          treinos.isNotEmpty;
    }

    // Dados ainda não carregados do banco — sem alterações por enquanto.
    if (_loadedData == null) return false;

    final data = _loadedData!;
    if (nomeCtrl.text.trim() != (data['nome'] ?? '')) return true;
    if (objCtrl.text.trim() != (data['objetivo'] ?? '')) return true;
    
    final tipoVenc = data['tipo_vencimento'] ?? data['tipoVencimento'] ?? 'data';
    if (tipoVencimento != tipoVenc) return true;

    if (tipoVencimento == 'sessoes') {
      final vencSess = data['vencimento_sessoes'] ?? data['vencimentoSessoes'] ?? 20;
      if (vencimentoSessoes != vencSess) return true;
    } else {
      final oldDateRaw = data['data_vencimento'] ?? data['dataVencimento'];
      final oldDate = oldDateRaw != null ? DateTime.tryParse(oldDateRaw.toString()) : null;
      if (oldDate == null ||
          vencimentoData.day != oldDate.day ||
          vencimentoData.month != oldDate.month ||
          vencimentoData.year != oldDate.year) {
        return true;
      }
    }

    List<dynamic> sessoesRaw = data['sessoes'] ?? [];
    if (treinos.length != sessoesRaw.length) return true;

    for (int i = 0; i < treinos.length; i++) {
      final sessao = treinos[i];
      final sessaoRaw = sessoesRaw[i];

      if (sessao.nome != sessaoRaw['nome']) return true;
      
      final rawDia = sessaoRaw['dia_semana'] ?? sessaoRaw['diaSemana'] ?? '';
      if ((sessao.diaSemana ?? '') != rawDia) {
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
        
        final rawInstrucaoPers = exRaw['instrucoes_personalizadas'] ?? exRaw['instrucoesPersonalizadas'] ?? '';
        if ((ex.instrucoesPersonalizadas ?? '') != rawInstrucaoPers) {
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

  void atualizarSessaoCompleta(
    int index,
    String nome,
    String? dia,
    String notas,
    List<ExercicioItem> exercicios,
  ) {
    treinos[index].nome = nome;
    treinos[index].diaSemana = dia;
    treinos[index].orientacoes = notas;
    treinos[index].exercicios = exercicios;
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

  /// Valida os campos sem tocar em [isSaving].
  bool podeSerSalva() {
    if (rotinaId == null && nomeCtrl.text.trim().isEmpty && treinos.isEmpty) {
      return true;
    }
    return nomeCtrl.text.trim().isNotEmpty &&
        objCtrl.text.trim().isNotEmpty &&
        treinos.isNotEmpty;
  }

  /// Save bloqueante — aguarda o write completar e retorna true/false.
  /// Usado pelo onSaveToFirebase da SessaoDetalhePage para garantir que
  /// o spinner da sessão só desaparece quando o dado foi persistido.
  Future<bool> salvarRotinaAgora() async {
    if (rotinaId == null || isSaving) return false;
    _debounceTimer?.cancel();
    _debounceTimer = null;

    final nomeParaSalvar = nomeCtrl.text.trim();
    final objetivoParaSalvar = objCtrl.text.trim();
    if (nomeParaSalvar.isEmpty || objetivoParaSalvar.isEmpty || treinos.isEmpty) {
      return false;
    }

    isSaving = true;
    notifyListeners();

    final sessoesJson = treinos.map((t) => t.toMap()).toList();

    _loadedData = {
      ...?_loadedData,
      'nome': nomeParaSalvar,
      'objetivo': objetivoParaSalvar,
      'sessoes': sessoesJson,
      'tipo_vencimento': tipoVencimento,
      if (tipoVencimento == 'sessoes') 'vencimento_sessoes': vencimentoSessoes,
      if (tipoVencimento == 'data') 'data_vencimento': vencimentoData.toIso8601String(),
    };

    try {
      await _rotinaService.atualizarRotina(
        rotinaId: rotinaId!,
        nome: nomeParaSalvar,
        objetivo: objetivoParaSalvar,
        sessoes: sessoesJson,
        tipoVencimento: tipoVencimento,
        sessoesAlvo: tipoVencimento == 'sessoes' ? vencimentoSessoes : null,
        dataVencimento: tipoVencimento == 'data' ? vencimentoData : null,
      );
      _saveFlushed = true;
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar rotina: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Fire-and-forget com debounce para rotinas existentes. Não altera [isSaving].
  /// Saves chamados dentro de 800ms são coalesced em um único write.
  void salvarRotinaBackground() {
    if (rotinaId == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), _dispararSave);
  }

  /// Aguardado apenas na criação (rotinaId == null), onde o ID ainda não existe.
  Future<bool> salvarRotina() async {
    if (isSaving) return false;

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
      final sessoesJson = treinos.map((t) => t.toMap()).toList();
      final newId = await _rotinaService.criarRotina(
        alunoId: alunoId,
        nome: nomeParaSalvar,
        objetivo: objetivoParaSalvar,
        sessoes: sessoesJson,
        tipoVencimento: tipoVencimento,
        sessoesAlvo: tipoVencimento == 'sessoes' ? vencimentoSessoes : null,
        dataVencimento: tipoVencimento == 'data' ? vencimentoData : null,
      );

      _rotinaId = newId;
      _loadedData = {
        'nome': nomeParaSalvar,
        'objetivo': objetivoParaSalvar,
        'sessoes': sessoesJson,
        'tipo_vencimento': tipoVencimento,
        if (tipoVencimento == 'sessoes') 'vencimento_sessoes': vencimentoSessoes,
        if (tipoVencimento == 'data')
          'data_vencimento': vencimentoData.toIso8601String(),
      };

      _saveFlushed = true;
      return true;
    } catch (e) {
      debugPrint('Erro ao criar rotina: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _dispararSave() {
    final nomeParaSalvar = nomeCtrl.text.trim();
    final objetivoParaSalvar = objCtrl.text.trim();
    if (rotinaId == null ||
        nomeParaSalvar.isEmpty ||
        objetivoParaSalvar.isEmpty ||
        treinos.isEmpty) {
      return;
    }

    // Evita write duplicado: se os dados em memória são idênticos ao baseline
    // (já foram salvos pelo debounce anterior), não dispara outro write.
    if (!verificarAlteracoes()) {
      debugPrint('[CONTROLLER-SAVE] _dispararSave ignorado — sem alterações desde último save');
      return;
    }

    debugPrint('[CONTROLLER-SAVE] _dispararSave chamado stack:\n${StackTrace.current}');
    final sessoesJson = treinos.map((t) => t.toMap()).toList();

    // Atualiza o baseline antes do save para que verificarAlteracoes()
    // não trate esses dados como "não salvos" em verificações futuras.
    _loadedData = {
      ...?_loadedData,
      'nome': nomeParaSalvar,
      'objetivo': objetivoParaSalvar,
      'sessoes': sessoesJson,
      'tipo_vencimento': tipoVencimento,
      if (tipoVencimento == 'sessoes') 'vencimento_sessoes': vencimentoSessoes,
      if (tipoVencimento == 'data')
        'data_vencimento': vencimentoData.toIso8601String(),
    };

    unawaited(_rotinaService
        .atualizarRotina(
          rotinaId: rotinaId!,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: tipoVencimento,
          sessoesAlvo: tipoVencimento == 'sessoes' ? vencimentoSessoes : null,
          dataVencimento: tipoVencimento == 'data' ? vencimentoData : null,
        )
        .catchError((e) {
          debugPrint('Erro ao salvar rotina: $e');
        }));
  }

  /// Verdadeiro após o primeiro flush manual — impede double-write via _handlePop.
  bool get saveFlushed => _saveFlushed;

  /// Força o save imediatamente, cancelando o debounce pendente.
  /// Não bloqueia — o write Firestore completa em background.
  void flushPendingSave() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _saveFlushed = true;
    _dispararSave();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    nomeCtrl.dispose();
    objCtrl.dispose();
    super.dispose();
  }
}