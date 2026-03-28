import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import 'configurar_exercicios_page.dart';
import 'models/exercicio_model.dart';
import 'widgets/rotina_modern_input.dart';
import 'widgets/rotina_input_decoration.dart';

class _TreinoData {
  String nome;
  String? diaSemana;
  String? orientacoes;
  List<ExercicioItem> exercicios;

  _TreinoData({
    required this.nome,
    this.diaSemana,
    this.orientacoes,
    List<ExercicioItem>? exercicios,
  }) : exercicios = exercicios ?? [];
}

class RotinaDetalhePage extends StatefulWidget {
  final Map<String, dynamic>? rotinaData;
  final String? rotinaId;
  final String? alunoId;
  final String? alunoNome;

  const RotinaDetalhePage({
    super.key,
    this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
  });

  @override
  State<RotinaDetalhePage> createState() => _RotinaDetalhePageState();
}

class _RotinaDetalhePageState extends State<RotinaDetalhePage> {
  late TextEditingController nomeCtrl;
  late TextEditingController objCtrl;
  late FocusNode objFocusNode;
  String _tipoVencimento = 'sessoes';
  int _vencimentoSessoes = 20;
  DateTime _vencimentoData = DateTime.now().add(const Duration(days: 30));

  final List<_TreinoData> _treinos = [];
  bool _isDeleting = false;
  bool _isSaving = false;
  bool _canPopNow = false;

  @override
  void initState() {
    super.initState();

    nomeCtrl = TextEditingController(text: widget.rotinaData?['nome'] ?? '');
    objCtrl = TextEditingController(text: widget.rotinaData?['objetivo'] ?? '');
    objFocusNode = FocusNode();

    _preencherDados();
  }

  bool _verificarAlteracoes() {
    if (widget.rotinaId == null) {
      // Nova rotina: tem alterações se campos não estão vazios ou tem treinos
      return nomeCtrl.text.trim().isNotEmpty ||
          objCtrl.text.trim().isNotEmpty ||
          _treinos.isNotEmpty;
    }

    final data = widget.rotinaData!;
    if (nomeCtrl.text.trim() != (data['nome'] ?? '')) return true;
    if (objCtrl.text.trim() != (data['objetivo'] ?? '')) return true;
    if (_tipoVencimento != (data['tipoVencimento'] ?? 'data')) return true;

    if (_tipoVencimento == 'sessoes') {
      if (_vencimentoSessoes != (data['vencimentoSessoes'] ?? 20)) return true;
    } else {
      final oldDate = (data['dataVencimento'] as Timestamp?)?.toDate();
      if (oldDate == null ||
          _vencimentoData.day != oldDate.day ||
          _vencimentoData.month != oldDate.month ||
          _vencimentoData.year != oldDate.year) {
        return true;
      }
    }

    // Comparação profunda das sessões
    List<dynamic> sessoesRaw = data['sessoes'] ?? [];
    if (_treinos.length != sessoesRaw.length) return true;

    for (int i = 0; i < _treinos.length; i++) {
      final sessao = _treinos[i];
      final sessaoRaw = sessoesRaw[i];

      if (sessao.nome != sessaoRaw['nome']) return true;
      if ((sessao.diaSemana ?? '') != (sessaoRaw['diaSemana'] ?? '')) return true;
      if ((sessao.orientacoes ?? '') != (sessaoRaw['orientacoes'] ?? '')) return true;

      List<dynamic> exerciciosRaw = sessaoRaw['exercicios'] ?? [];
      if (sessao.exercicios.length != exerciciosRaw.length) return true;

      for (int j = 0; j < sessao.exercicios.length; j++) {
        final ex = sessao.exercicios[j];
        final exRaw = exerciciosRaw[j];

        if (ex.nome != exRaw['nome']) return true;
        if (ex.tipoAlvo != (exRaw['tipoAlvo'] ?? 'Reps')) return true;

        // Comparação de grupos musculares
        List<String> gruposRaw = [];
        final rawG = exRaw['grupoMuscular'];
        if (rawG is String) {
          gruposRaw = rawG.split(',').map((e) => e.trim()).toList();
        } else if (rawG is List) {
          gruposRaw = List<String>.from(rawG);
        }
        if (ex.grupoMuscular.length != gruposRaw.length) return true;
        for (int k = 0; k < ex.grupoMuscular.length; k++) {
          if (ex.grupoMuscular[k] != gruposRaw[k]) return true;
        }

        // Comparação de séries
        List<dynamic> seriesRaw = exRaw['series'] ?? [];
        if (ex.series.length != seriesRaw.length) return true;

        for (int k = 0; k < ex.series.length; k++) {
          final s = ex.series[k];
          final sRaw = seriesRaw[k];

          if (s.tipo.name != sRaw['tipo']) return true;
          if (s.alvo != sRaw['alvo']) return true;
          if (s.carga != sRaw['carga']) return true;
          if (s.descanso != sRaw['descanso']) return true;
        }
      }
    }

    return false;
  }

  Future<bool> _showDescartarDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text(
              'Descartar alterações?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Os dados preenchidos não são válidos para salvar e serão perdidos.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'CONTINUAR EDITANDO',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'DESCARTAR',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    objCtrl.dispose();
    objFocusNode.dispose();
    super.dispose();
  }

  void _preencherDados() {
    if (widget.rotinaData != null) {
      _tipoVencimento = widget.rotinaData!['tipoVencimento'] ?? 'data';

      if (_tipoVencimento == 'sessoes') {
        _vencimentoSessoes = widget.rotinaData!['vencimentoSessoes'] ?? 20;
      } else {
        if (widget.rotinaData!['dataVencimento'] != null) {
          _vencimentoData = (widget.rotinaData!['dataVencimento'] as Timestamp)
              .toDate();
        }
      }

      List<dynamic> sessoesRaw = widget.rotinaData!['sessoes'] ?? [];
      for (var sessao in sessoesRaw) {
        List<ExercicioItem> exerciciosList = [];
        for (var ex in (sessao['exercicios'] ?? [])) {
          List<SerieItem> seriesList = [];
          for (var s in (ex['series'] ?? [])) {
            seriesList.add(
              SerieItem(
                tipo: _parseTipoSerie(s['tipo']),
                alvo: s['alvo'] ?? '10',
                carga: s['carga'] ?? '-',
                descanso: s['descanso'] ?? '60s',
              ),
            );
          }

          List<String> grupos = ['Geral'];
          final rawGrupo = ex['grupoMuscular'];
          if (rawGrupo is String) {
            grupos = rawGrupo.split(',').map((e) => e.trim()).toList();
          } else if (rawGrupo is List) {
            grupos = List<String>.from(rawGrupo);
          }

          exerciciosList.add(
            ExercicioItem(
              nome: ex['nome'] ?? 'Exercício',
              grupoMuscular: grupos,
              tipoAlvo: ex['tipoAlvo'] ?? 'Reps',
              imagemUrl: ex['imagemUrl'],
              personalId: ex['personalId'],
              series: seriesList,
            ),
          );
        }
        _treinos.add(
          _TreinoData(
            nome: sessao['nome'],
            diaSemana: sessao['diaSemana'],
            orientacoes: sessao['orientacoes'],
            exercicios: exerciciosList,
          ),
        );
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _exibirModalInfo(context);
      });
    }
  }

  TipoSerie _parseTipoSerie(String? tipo) {
    if (tipo == 'aquecimento' || tipo == 'TipoSerie.aquecimento') {
      return TipoSerie.aquecimento;
    }
    if (tipo == 'feeder' || tipo == 'TipoSerie.feeder') return TipoSerie.feeder;
    return TipoSerie.trabalho;
  }

  void _exibirModalInfo(BuildContext context) {
    String tipoTemp = _tipoVencimento;
    String sessoesInput = widget.rotinaId == null ? '' : _vencimentoSessoes.toString();
    DateTime dataTemp = _vencimentoData;

    final localNomeCtrl = TextEditingController(text: nomeCtrl.text);
    final localObjCtrl = TextEditingController(text: objCtrl.text);
    final formKeyInfo = GlobalKey<FormState>();

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => StatefulBuilder(
          builder: (stfContext, setStateModal) => Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () async {
                  final nome = localNomeCtrl.text.trim();
                  final obj = localObjCtrl.text.trim();

                  if (nome.isNotEmpty && obj.isNotEmpty) {
                    Navigator.of(pageContext).pop();
                    return;
                  }

                  final descartar = await _showDescartarDialog();
                  if (descartar && pageContext.mounted) {
                    Navigator.of(pageContext).pop();
                    if (widget.rotinaId == null && _treinos.isEmpty && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              title: const Text('Configurações', style: AppTheme.pageTitle),
              actions: [
                TextButton(
                  onPressed: () {
                    if (formKeyInfo.currentState!.validate()) {
                      final nome = localNomeCtrl.text.trim();
                      final obj = localObjCtrl.text.trim();
                      final sessoes = int.tryParse(sessoesInput);

                      if (tipoTemp == 'sessoes' && (sessoes == null || sessoes <= 0)) {
                        ScaffoldMessenger.of(stfContext).showSnackBar(
                          const SnackBar(content: Text('Informe uma quantidade válida de sessões.')),
                        );
                        return;
                      }

                      setState(() {
                        nomeCtrl.text = nome;
                        objCtrl.text = obj;
                        _tipoVencimento = tipoTemp;
                        _vencimentoSessoes = sessoes ?? 20;
                        _vencimentoData = dataTemp;
                      });
                      Navigator.of(pageContext).pop();
                    }
                  },
                  child: const Text('SALVAR', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingScreen),
              child: Form(
                key: formKeyInfo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RotinaModernInput(
                      label: 'Nome da Planilha',
                      child: TextFormField(
                        controller: localNomeCtrl,
                        autofocus: true,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        decoration: rotinaInputDecoration(hintText: 'Ex: Protocolo Y'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RotinaModernInput(
                      label: 'Objetivo Principal',
                      child: TextFormField(
                        controller: localObjCtrl,
                        maxLength: 50,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        decoration: rotinaInputDecoration(hintText: 'Ex: Hipertrofia Máxima'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('VENCIMENTO', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildTabOption(
                                label: 'Sessões',
                                isSelected: tipoTemp == 'sessoes',
                                onTap: () => setStateModal(() => tipoTemp = 'sessoes'),
                              ),
                              _buildTabOption(
                                label: 'Data Fixa',
                                isSelected: tipoTemp == 'data',
                                onTap: () => setStateModal(() => tipoTemp = 'data'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: tipoTemp == 'sessoes'
                                ? TextFormField(
                                    key: const ValueKey('inputSessoes'),
                                    keyboardType: TextInputType.number,
                                    initialValue: sessoesInput,
                                    style: const TextStyle(color: AppTheme.textPrimary),
                                    decoration: rotinaInputDecoration(hintText: 'Quantas sessões?'),
                                    onChanged: (v) => sessoesInput = v,
                                  )
                                : ListTile(
                                    key: const ValueKey('inputData'),
                                    tileColor: AppTheme.surfaceDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    leading: const Icon(Icons.calendar_month, color: AppTheme.primary),
                                    title: Text(DateFormat('dd/MM/yyyy').format(dataTemp), style: const TextStyle(color: Colors.white)),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: stfContext,
                                        initialDate: dataTemp,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) setStateModal(() => dataTemp = picked);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.rotinaId != null) ...[
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => _confirmarExclusao(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('REMOVER PLANILHA', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      localNomeCtrl.dispose();
      localObjCtrl.dispose();
    });
  }

  void _confirmarExclusao() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Remover Planilha?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita e todos os dados desta planilha serão perdidos.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _isDeleting = true);
              await RotinaService().excluirRotina(widget.rotinaId!);
              if (mounted) {
                setState(() {
                  _canPopNow = true;
                  _isDeleting = false;
                });
                navigator.pop(); // Fecha dialog
                navigator.pop(); // Fecha modal
                navigator.pop(); // Volta para a tela anterior
              }
            },
            child: const Text(
              'REMOVER',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para as abas de Sessão/Data
  Widget _buildTabOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : Colors.white38,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _exibirModalSessao({int? index}) {
    final bool isEditing = index != null;
    final sNomeCtrl = TextEditingController(
      text: isEditing ? _treinos[index].nome : null,
    );
    String? diaSemana = isEditing ? _treinos[index].diaSemana : null;
    final orientCtrl = TextEditingController(
      text: isEditing ? _treinos[index].orientacoes : null,
    );
    final formKeySessao = GlobalKey<FormState>();

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => StatefulBuilder(
          builder: (stfContext, setStateModal) => Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(pageContext).pop(),
              ),
              title: Text(isEditing ? 'Editar Sessão' : 'Nova Sessão', style: AppTheme.pageTitle),
              actions: [
                TextButton(
                  onPressed: () {
                    if (formKeySessao.currentState!.validate()) {
                      final newName = sNomeCtrl.text.trim();
                      setState(() {
                        if (isEditing) {
                          _treinos[index].nome = newName;
                          _treinos[index].diaSemana = diaSemana;
                          _treinos[index].orientacoes = orientCtrl.text.trim();
                        } else {
                          _treinos.add(
                            _TreinoData(
                              nome: newName,
                              diaSemana: diaSemana,
                              orientacoes: orientCtrl.text.trim(),
                            ),
                          );
                        }
                      });
                      Navigator.pop(pageContext);
                    }
                  },
                  child: const Text('SALVAR', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingScreen),
              child: Form(
                key: formKeySessao,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RotinaModernInput(
                      label: 'NOME DO TREINO',
                      child: TextFormField(
                        controller: sNomeCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: rotinaInputDecoration(hintText: 'Ex: Push, Pull...'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    RotinaModernInput(
                      label: 'DIA DA SEMANA',
                      child: DropdownButtonFormField<String>(
                        initialValue: diaSemana,
                        dropdownColor: AppTheme.surfaceLight,
                        items: ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) => diaSemana = v,
                        decoration: rotinaInputDecoration(hintText: 'Sem dia fixo'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RotinaModernInput(
                      label: 'NOTAS',
                      child: TextFormField(
                        controller: orientCtrl,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: rotinaInputDecoration(hintText: 'Ex: Aquecer manguito antes...'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _excluirTreino(int index) {
    setState(() {
      _treinos.removeAt(index);
    });
  }

  Future<bool> _salvarRotinaCompleta() async {
    if (_isDeleting) return true;

    final String nomeParaSalvar = nomeCtrl.text.trim();
    final String objetivoParaSalvar = objCtrl.text.trim();

    // Se estiver totalmente vazio e for criação, deixa sair sem salvar
    if (widget.rotinaId == null && nomeParaSalvar.isEmpty && _treinos.isEmpty) {
      return true;
    }

    if (nomeParaSalvar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O nome da planilha é obrigatório.')),
        );
      }
      return false;
    }

    if (objetivoParaSalvar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O objetivo da planilha é obrigatório.')),
        );
      }
      return false;
    }

    if (_treinos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione pelo menos um treino à planilha.')),
        );
      }
      return false;
    }

    try {
      // 1. Mapeamento das sessões para JSON
      List<Map<String, dynamic>> sessoesJson = _treinos
          .map(
            (t) => {
              'nome': t.nome,
              'diaSemana': t.diaSemana ?? '',
              'orientacoes': t.orientacoes ?? '',
              'exercicios': t.exercicios
                  .map(
                    (ex) => {
                      'nome': ex.nome,
                      'grupoMuscular': ex.grupoMuscular,
                      'tipoAlvo': ex.tipoAlvo,
                      'series': ex.series
                          .map(
                            (s) => {
                              'tipo': s.tipo.name,
                              'alvo': s.alvo,
                              'carga': s.carga,
                              'descanso': s.descanso,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            },
          )
          .toList();

      debugPrint('--- [DATABASE] SALVANDO PLANILHA: $nomeParaSalvar ---');

      // 2. Chamada do serviço tratando as duas opções
      if (widget.rotinaId != null) {
        // EDIÇÃO
        await RotinaService().atualizarRotina(
          rotinaId: widget.rotinaId!,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: _tipoVencimento, // Passando o tipo escolhido
          sessoesAlvo: _tipoVencimento == 'sessoes' ? _vencimentoSessoes : null,
          dataVencimento: _tipoVencimento == 'data' ? _vencimentoData : null,
        );
      } else {
        // CRIAÇÃO NOVA
        await RotinaService().criarRotina(
          alunoId: widget.alunoId,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: _tipoVencimento, // Passando o tipo escolhido
          sessoesAlvo: _tipoVencimento == 'sessoes' ? _vencimentoSessoes : null,
          dataVencimento: _tipoVencimento == 'data' ? _vencimentoData : null,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao salvar rotina: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTemplate =
        widget.rotinaData != null && widget.rotinaData!['alunoId'] == null;

    return PopScope(
      canPop: _canPopNow,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSaving) return;

        // 1. Se não houver alterações, sai direto
        if (!_verificarAlteracoes()) {
          setState(() => _canPopNow = true);
          Navigator.of(context).pop();
          return;
        }

        // 2. Se houver alterações, tenta salvar
        setState(() => _isSaving = true);

        try {
          bool salvo = await _salvarRotinaCompleta();

          if (salvo && mounted) {
            setState(() {
              _isSaving = false;
              _canPopNow = true;
            });
            // Pequeno delay para garantir que o frame do setState foi processado
            Future.microtask(() {
              if (context.mounted) Navigator.of(context).pop();
            });
          } else {
            // Se não salvou (falta nome, etc), pergunta se quer descartar ou continuar
            if (mounted) {
              setState(() => _isSaving = false);
              final descartar = await _showDescartarDialog();
              if (descartar && context.mounted) {
                setState(() => _canPopNow = true);
                Navigator.of(context).pop();
              }
            }
          }
        } catch (e) {
          debugPrint('Erro crítico no PopScope: $e');
          if (mounted) setState(() => _isSaving = false);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: CupertinoButton(
            padding: const EdgeInsets.only(left: 8),
            child: const Icon(
              CupertinoIcons.back,
              color: AppTheme.textPrimary,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Gerenciar Planilha', style: AppTheme.pageTitle),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: nomeCtrl,
                              builder: (context, value, _) {
                                return Text(
                                  value.text.isEmpty
                                      ? 'Nova Rotina'
                                      : value.text,
                                  style: AppTheme.bigTitle,
                                );
                              },
                            ),

                            ValueListenableBuilder(
                              valueListenable: objCtrl,
                              builder: (context, value, _) {
                                return Text(
                                  value.text.isEmpty
                                      ? 'Defina o objetivo'
                                      : value.text,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _tipoVencimento == 'sessoes'
                                      ? '$_vencimentoSessoes sessões'
                                      : 'Vence em ${DateFormat('dd/MM/yyyy').format(_vencimentoData)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _exibirModalInfo(context),
                        icon: const Icon(
                          CupertinoIcons.ellipsis_vertical,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (isTemplate) _buildTemplateBadge(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lista de treinos',
                        style: AppTheme.textSectionHeaderDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_treinos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Text(
                          'Nenhuma sessão',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._treinos.asMap().entries.map(
                      (entry) => _buildSessaoCard(
                        entry.value,
                        entry.key,
                        key: ValueKey(entry.value),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildAddSessaoButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS DE WIDGETS AUXILIARES ---

  Widget _buildAddSessaoButton() {
    return InkWell(
      onTap: () => _exibirModalSessao(),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'Novo Treino',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withAlpha(30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.collections_bookmark, color: AppTheme.primary, size: 18),
          SizedBox(width: 12),
          Text(
            'Template de Biblioteca',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessaoCard(_TreinoData sessao, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: AppTheme.cardDecoration,
        child: Material(
          type: MaterialType.transparency,
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            splashColor: AppTheme.splash.withAlpha(50),
            highlightColor: AppTheme.splash.withAlpha(30),
            onTap: () async {
              final dynamic result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigurarExerciciosPage(
                    nomeTreino: sessao.nome,
                    exercicios: sessao.exercicios,
                    sessaoNote: sessao.orientacoes ?? '',
                  ),
                ),
              );

              if (mounted && result is Map<String, dynamic>) {
                setState(() {
                  sessao.nome = result['nome'];
                  sessao.orientacoes = result['sessaoNote'];
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: Colors.black.withAlpha(40),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          sessao.nome,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${sessao.exercicios.length} exercícios',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    onSelected: (v) {
                      if (v == 'edit') _exibirModalSessao(index: index);
                      if (v == 'delete') _excluirTreino(index);
                    },
                    itemBuilder: (c) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}