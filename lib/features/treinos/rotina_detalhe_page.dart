import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import '../../core/services/rotina_service.dart';
import 'configurar_exercicios_page.dart';
import 'models/exercicio_model.dart';
import 'widgets/rotina_modern_input.dart';
import 'widgets/rotina_input_decoration.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_nav_back_button.dart';
import '../../core/widgets/app_bar_text_button.dart';

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
  final RotinaService? rotinaService;

  const RotinaDetalhePage({
    super.key,
    this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
    this.rotinaService,
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

  late final RotinaService _rotinaService;

  @override
  void initState() {
    super.initState();

    _rotinaService = widget.rotinaService ?? RotinaService();

    nomeCtrl = TextEditingController(text: widget.rotinaData?['nome'] ?? '');
    objCtrl = TextEditingController(text: widget.rotinaData?['objetivo'] ?? '');
    objFocusNode = FocusNode();

    _preencherDados();
  }

  bool _verificarAlteracoes() {
    if (widget.rotinaId == null) {
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

    List<dynamic> sessoesRaw = data['sessoes'] ?? [];
    if (_treinos.length != sessoesRaw.length) return true;

    for (int i = 0; i < _treinos.length; i++) {
      final sessao = _treinos[i];
      final sessaoRaw = sessoesRaw[i];

      if (sessao.nome != sessaoRaw['nome']) return true;
      if ((sessao.diaSemana ?? '') != (sessaoRaw['diaSemana'] ?? '')) {
        return true;
      }
      if ((sessao.orientacoes ?? '') != (sessaoRaw['orientacoes'] ?? '')) {
        return true;
      }

      List<dynamic> exerciciosRaw = sessaoRaw['exercicios'] ?? [];
      if (sessao.exercicios.length != exerciciosRaw.length) return true;
    }

    return false;
  }

  Future<bool> _showDescartarDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
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
                  style: TextStyle(color: AppColors.primary),
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

  void _exibirModalInfo(BuildContext context) async {
    final bool isInitialSetup =
        widget.rotinaId == null && nomeCtrl.text.isEmpty;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => _PlanilhaSettingsPage(
          rotinaId: widget.rotinaId,
          nomeInicial: nomeCtrl.text,
          objetivoInicial: objCtrl.text,
          tipoVencimento: _tipoVencimento,
          vencimentoSessoes: _vencimentoSessoes,
          vencimentoData: _vencimentoData,
          hasTreinos: _treinos.isNotEmpty,
          onSave: (nome, obj, tipo, sessoes, data) {
            setState(() {
              nomeCtrl.text = nome;
              objCtrl.text = obj;
              _tipoVencimento = tipo;
              _vencimentoSessoes = sessoes;
              _vencimentoData = data;
            });
          },
          onDelete: _confirmarExclusao,
          showDescartarDialog: _showDescartarDialog,
        ),
      ),
    );

    // Se era a configuração inicial e o nome continua vazio, significa que o usuário cancelou/descartou.
    // Nesse caso, voltamos para a biblioteca de treinos.
    if (isInitialSetup && context.mounted && nomeCtrl.text.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  void _exibirModalSessao({int? index}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => _SessaoTreinoPage(
          sessao: index != null ? _treinos[index] : null,
          onSave: (nome, dia, notas) {
            setState(() {
              if (index != null) {
                _treinos[index].nome = nome;
                _treinos[index].diaSemana = dia;
                _treinos[index].orientacoes = notas;
              } else {
                _treinos.add(
                  _TreinoData(nome: nome, diaSemana: dia, orientacoes: notas),
                );
              }
            });
          },
        ),
      ),
    );
  }

  void _confirmarExclusao() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
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
              await _rotinaService.excluirRotina(widget.rotinaId!);
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

  void _excluirTreino(int index) {
    setState(() {
      _treinos.removeAt(index);
    });
  }

  Future<bool> _salvarRotinaCompleta() async {
    if (_isDeleting) return true;

    final String nomeParaSalvar = nomeCtrl.text.trim();
    final String objetivoParaSalvar = objCtrl.text.trim();

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
          const SnackBar(
            content: Text('O objetivo da planilha é obrigatório.'),
          ),
        );
      }
      return false;
    }

    if (_treinos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adicione pelo menos um treino à planilha.'),
          ),
        );
      }
      return false;
    }

    try {
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

      if (widget.rotinaId != null) {
        await _rotinaService.atualizarRotina(
          rotinaId: widget.rotinaId!,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: _tipoVencimento,
          sessoesAlvo: _tipoVencimento == 'sessoes' ? _vencimentoSessoes : null,
          dataVencimento: _tipoVencimento == 'data' ? _vencimentoData : null,
        );
      } else {
        await _rotinaService.criarRotina(
          alunoId: widget.alunoId,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: _tipoVencimento,
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

        if (!_verificarAlteracoes()) {
          setState(() => _canPopNow = true);
          Navigator.of(context).pop();
          return;
        }

        setState(() => _isSaving = true);
        try {
          bool salvo = await _salvarRotinaCompleta();
          if (salvo && mounted) {
            setState(() {
              _isSaving = false;
              _canPopNow = true;
            });
            Future.microtask(() {
              if (context.mounted) Navigator.of(context).pop();
            });
          } else {
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
          if (mounted) setState(() => _isSaving = false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leadingWidth: 100,
          leading: AppNavBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Gerenciar Planilha', style: AppTheme.pageTitle),
          bottom: const AppBarDivider(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.paddingScreen,
                right: AppTheme.paddingScreen,
                top: SpacingTokens.pageTopPadding,
                bottom: SpacingTokens.pageBottomPadding,
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
                                  style: CardTokens.cardSubtitle,
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: AppColors.labelSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _tipoVencimento == 'sessoes'
                                      ? '$_vencimentoSessoes ${_vencimentoSessoes == 1 ? 'sessão' : 'sessões'}'
                                      : 'Vence em ${DateFormat('dd/MM/yyyy').format(_vencimentoData)}',
                                  style: AppTheme.caption,
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
                          color: AppColors.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.xxl),
                  if (isTemplate) _buildTemplateBadge(),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Text('Lista de treinos', style: AppTheme.sectionHeader),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  if (_treinos.isEmpty)
                    _buildEmptyState()
                  else
                    ..._treinos.asMap().entries.map(
                      (entry) => _buildSessaoCard(
                        entry.value,
                        entry.key,
                        key: ValueKey(entry.value),
                      ),
                    ),
                  const SizedBox(height: SpacingTokens.lg),
                  _buildAddSessaoButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.square_list,
                size: 48,
                color: AppColors.primary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sua planilha está vazia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione as sessões de treino (ex: Treino A, Treino B)\npara começar a configurar os exercícios.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.labelSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSessaoButton() {
    return AppPrimaryButton(
      label: 'Nova sessão',
      icon: CupertinoIcons.add_circled,
      onPressed: () => _exibirModalSessao(),
    );
  }

  Widget _buildTemplateBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.collections_bookmark, color: AppColors.primary, size: 18),
          SizedBox(width: 12),
          Text(
            'Template de Biblioteca',
            style: TextStyle(
              color: AppColors.primary,
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
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: () async {
          final result = await Navigator.push(
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
          padding: CardTokens.padding,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessao.nome,
                      style: CardTokens.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${sessao.exercicios.length} ${sessao.exercicios.length == 1 ? 'exercício' : 'exercícios'}',
                      style: CardTokens.cardSubtitle,
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  size: 20,
                  color: AppColors.labelSecondary,
                ),
                onSelected: (v) {
                  if (v == 'edit') _exibirModalSessao(index: index);
                  if (v == 'delete') _excluirTreino(index);
                },
                itemBuilder: (c) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanilhaSettingsPage extends StatefulWidget {
  final String? rotinaId;
  final String nomeInicial;
  final String objetivoInicial;
  final String tipoVencimento;
  final int vencimentoSessoes;
  final DateTime vencimentoData;
  final bool hasTreinos;
  final Function(String, String, String, int, DateTime) onSave;
  final VoidCallback onDelete;
  final Future<bool> Function() showDescartarDialog;

  const _PlanilhaSettingsPage({
    required this.rotinaId,
    required this.nomeInicial,
    required this.objetivoInicial,
    required this.tipoVencimento,
    required this.vencimentoSessoes,
    required this.vencimentoData,
    required this.hasTreinos,
    required this.onSave,
    required this.onDelete,
    required this.showDescartarDialog,
  });

  @override
  State<_PlanilhaSettingsPage> createState() => _PlanilhaSettingsPageState();
}

class _PlanilhaSettingsPageState extends State<_PlanilhaSettingsPage> {
  late TextEditingController localNomeCtrl;
  late TextEditingController localObjCtrl;
  late FocusNode nomeFocus;
  late FocusNode objFocus;
  late String tipoTemp;
  late String sessoesInput;
  late DateTime dataTemp;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    localNomeCtrl = TextEditingController(text: widget.nomeInicial);
    localObjCtrl = TextEditingController(text: widget.objetivoInicial);
    nomeFocus = FocusNode();
    objFocus = FocusNode();

    // Listeners para atualizar a visibilidade do contador ao focar/desfocar
    nomeFocus.addListener(() => setState(() {}));
    objFocus.addListener(() => setState(() {}));

    tipoTemp = widget.tipoVencimento;
    sessoesInput = widget.rotinaId == null
        ? ''
        : widget.vencimentoSessoes.toString();
    dataTemp = widget.vencimentoData;
  }

  @override
  void dispose() {
    localNomeCtrl.dispose();
    localObjCtrl.dispose();
    nomeFocus.dispose();
    objFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () async {
            if (localNomeCtrl.text.trim().isNotEmpty &&
                localObjCtrl.text.trim().isNotEmpty) {
              Navigator.pop(context);
              return;
            }
            if (await widget.showDescartarDialog()) {
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
        title: const Text('Configurações', style: AppTheme.pageTitle),
        actions: [
          AppBarTextButton(
            label: 'Salvar',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final sessoes = int.tryParse(sessoesInput) ?? 20;
                if (tipoTemp == 'sessoes' &&
                    (int.tryParse(sessoesInput) == null || sessoes <= 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe uma quantidade válida de sessões.',
                      ),
                    ),
                  );
                  return;
                }
                widget.onSave(
                  localNomeCtrl.text.trim(),
                  localObjCtrl.text.trim(),
                  tipoTemp,
                  sessoes,
                  dataTemp,
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingScreen),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RotinaModernInput(
                label: 'Nome da Planilha',
                child: TextFormField(
                  controller: localNomeCtrl,
                  focusNode: nomeFocus,
                  autofocus: true,
                  maxLength: 40,
                  style: const TextStyle(
                    color: AppColors.labelPrimary,
                    fontSize: 15,
                  ),
                  decoration: rotinaInputDecoration(
                    hintText: 'Ex: Protocolo Y',
                  ).copyWith(counterText: nomeFocus.hasFocus ? null : ""),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              RotinaModernInput(
                label: 'Objetivo Principal',
                child: TextFormField(
                  controller: localObjCtrl,
                  focusNode: objFocus,
                  maxLength: 50,
                  decoration: rotinaInputDecoration(
                    hintText: 'Ex: Hipertrofia Máxima',
                  ).copyWith(counterText: objFocus.hasFocus ? null : ""),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              Row(
                children: [
                  const SizedBox(width: AppTheme.space8),
                  const Text('Vencimento', style: AppTheme.formLabel),
                ],
              ),
              const SizedBox(height: SpacingTokens.labelToField),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildTabOption(
                          'Sessões',
                          tipoTemp == 'sessoes',
                          () => setState(() => tipoTemp = 'sessoes'),
                        ),
                        _buildTabOption(
                          'Data Fixa',
                          tipoTemp == 'data',
                          () => setState(() => tipoTemp = 'data'),
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
                              decoration: rotinaInputDecoration(
                                hintText: 'Quantas sessões?',
                              ),
                              onChanged: (v) => sessoesInput = v,
                            )
                          : ListTile(
                              key: const ValueKey('inputData'),
                              tileColor: AppColors.surfaceDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSM,
                                ),
                              ),
                              leading: const Icon(
                                Icons.calendar_month,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                DateFormat('dd/MM/yyyy').format(dataTemp),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dataTemp,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() => dataTemp = picked);
                                }
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
                    onPressed: widget.onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'REMOVER PLANILHA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white38,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SessaoTreinoPage extends StatefulWidget {
  final _TreinoData? sessao;
  final Function(String, String?, String) onSave;

  const _SessaoTreinoPage({this.sessao, required this.onSave});

  @override
  State<_SessaoTreinoPage> createState() => _SessaoTreinoPageState();
}

class _SessaoTreinoPageState extends State<_SessaoTreinoPage> {
  late TextEditingController sNomeCtrl;
  late TextEditingController orientCtrl;
  String? diaSemana;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    sNomeCtrl = TextEditingController(text: widget.sessao?.nome);
    orientCtrl = TextEditingController(text: widget.sessao?.orientacoes);
    diaSemana = widget.sessao?.diaSemana;
  }

  @override
  void dispose() {
    sNomeCtrl.dispose();
    orientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sessao != null ? 'Editar Sessão' : 'Nova Sessão',
          style: AppTheme.pageTitle,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSave(
                  sNomeCtrl.text.trim(),
                  diaSemana,
                  orientCtrl.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: Text(
              'Salvar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingScreen),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RotinaModernInput(
                label: 'NOME DO TREINO',
                child: TextFormField(
                  controller: sNomeCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: rotinaInputDecoration(
                    hintText: 'Ex: Push, Pull...',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              RotinaModernInput(
                label: 'NOTAS',
                child: TextFormField(
                  controller: orientCtrl,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: rotinaInputDecoration(
                    hintText: 'Ex: Aquecer manguito antes...',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
