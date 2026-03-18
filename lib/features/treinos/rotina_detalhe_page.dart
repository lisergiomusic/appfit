import 'package:appfit/core/widgets/sliver_safe_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import 'configurar_exercicios_page.dart';
import 'models/exercicio_model.dart';

// Modelo local para gerir as sessões durante a edição
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
  final Map<String, dynamic>? rotinaData; // Nulo se for nova rotina!
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
  // --- ESTADO GERAL DA ROTINA ---
  String _nome = '';
  String _objetivo = '';
  int _duracaoSemanas = 4;
  final List<_TreinoData> _treinos = [];

  bool _isReordering = false;
  bool _isLoading = false;
  bool _foiModificado = false; // Controla se o botão de Salvar aparece

  @override
  void initState() {
    super.initState();
    _preencherDados();
  }

  void _preencherDados() {
    if (widget.rotinaData != null) {
      _nome = widget.rotinaData!['nome'] ?? '';
      _objetivo = widget.rotinaData!['objetivo'] ?? '';

      if (widget.rotinaData!['dataCriacao'] != null &&
          widget.rotinaData!['dataVencimento'] != null) {
        DateTime criacao = (widget.rotinaData!['dataCriacao'] as Timestamp)
            .toDate();
        DateTime vencimento =
            (widget.rotinaData!['dataVencimento'] as Timestamp).toDate();
        int dias = vencimento.difference(criacao).inDays;
        if (dias > 0) _duracaoSemanas = (dias / 7).round();
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

          // Lógica de migração para grupoMuscular
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
              personalId: ex['personalId'], // Lendo a autoria corretamente
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
      // Se for uma rotina nova, abre logo o modal de informações no início
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

  // --- WIDGET AUXILIAR PARA INPUTS (APPLE NATIVE) ---
  Widget _buildModernInput({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  // --- BUILD CUSTOM INPUT DECORATION (APPLE NATIVE) ---
  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppTheme.textSecondary.withAlpha(80),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white.withAlpha(8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppTheme.primary.withAlpha(150),
          width: 1,
        ),
      ),
    );
  }

  // --- MODAL PARA EDITAR CABEÇALHO (REFINADO) ---
  void _exibirModalInfo(BuildContext context) {
    final nomeCtrl = TextEditingController(text: _nome);
    final objCtrl = TextEditingController(text: _objetivo);
    int semanasSelecionadas = _duracaoSemanas;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HANDLE DE ARRASTAR
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Configurar Rotina',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              _buildModernInput(
                label: 'NOME DA ROTINA',
                icon: Icons.title,
                child: TextField(
                  controller: nomeCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Ex: Projeto Hipertrofia Mês 1',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildModernInput(
                label: 'OBJETIVO PRINCIPAL',
                icon: Icons.track_changes,
                child: TextField(
                  controller: objCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Ex: Ganho de massa e força',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildModernInput(
                label: 'DURAÇÃO PLANEJADA',
                icon: Icons.schedule,
                child: DropdownButtonFormField<int>(
                  initialValue: semanasSelecionadas,
                  dropdownColor: AppTheme.surfaceLight,
                  icon: Icon(
                    Icons.expand_more_rounded,
                    color: AppTheme.primary.withAlpha(150),
                    size: 18,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  items: [4, 5, 6, 8, 10, 12]
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text('$w semanas'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setStateModal(() => semanasSelecionadas = v!),
                  decoration: _buildInputDecoration(
                    hintText: 'Escolha a duração',
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _nome = nomeCtrl.text.trim();
                    _objetivo = objCtrl.text.trim();
                    _duracaoSemanas = semanasSelecionadas;
                    _foiModificado = true;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Concluir',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL PARA ADICIONAR/EDITAR SESSÃO (REFINADO) ---
  void _exibirModalSessao({int? index}) {
    final bool isEditing = index != null;
    final nomeCtrl = TextEditingController(
      text: isEditing ? _treinos[index].nome : null,
    );
    String? diaSemana = isEditing ? _treinos[index].diaSemana : null;
    final orientCtrl = TextEditingController(
      text: isEditing ? _treinos[index].orientacoes : null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEditing ? 'Editar Sessão' : 'Nova Sessão',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 28),

            _buildModernInput(
              label: 'NOME DO TREINO',
              icon: Icons.fitness_center,
              child: TextField(
                controller: nomeCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                ),
                decoration: _buildInputDecoration(
                  hintText: 'Ex: Push, Pull, Costas...',
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildModernInput(
              label: 'DIA DA SEMANA (OPCIONAL)',
              icon: Icons.calendar_today,
              child: DropdownButtonFormField<String>(
                initialValue: diaSemana,
                dropdownColor: AppTheme.surfaceLight,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: AppTheme.primary.withAlpha(150),
                  size: 18,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                items:
                    <String>[
                          'Segunda',
                          'Terça',
                          'Quarta',
                          'Quinta',
                          'Sexta',
                          'Sábado',
                          'Domingo',
                        ]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (v) => diaSemana = v,
                decoration: _buildInputDecoration(hintText: 'Sem dia fixo'),
              ),
            ),
            const SizedBox(height: 24),

            _buildModernInput(
              label: 'NOTAS GERAIS DA SESSÃO',
              icon: Icons.notes,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(15),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: TextField(
                  controller: orientCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration:
                      _buildInputDecoration(
                        hintText: 'Ex: Aquecer manguito rotador antes...',
                      ).copyWith(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                final newName = nomeCtrl.text.trim().isEmpty
                    ? 'Treino ${String.fromCharCode(65 + _treinos.length)}'
                    : nomeCtrl.text.trim();
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
                  _foiModificado = true;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                isEditing ? 'Salvar' : 'Adicionar',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _excluirTreino(int index) {
    setState(() {
      _treinos.removeAt(index);
      _foiModificado = true;
    });
  }

  // --- SALVAR TUDO NO FIREBASE ---
  Future<void> _salvarRotinaCompleta() async {
    if (_nome.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dê um nome à rotina!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_treinos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma sessão!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> sessoesJson = _treinos
          .map(
            (t) => {
              'nome': t.nome,
              'diaSemana': t.diaSemana,
              'orientacoes': t.orientacoes,
              'exercicios': t.exercicios
                  .map(
                    (ex) => {
                      'nome': ex.nome,
                      'grupoMuscular': ex.grupoMuscular,
                      'tipoAlvo': ex.tipoAlvo,
                      'imagemUrl': ex.imagemUrl,
                      'personalId': ex
                          .personalId, // Adicionando para não perder autoria ao salvar!
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
        await RotinaService().atualizarRotina(
          rotinaId: widget.rotinaId!,
          nome: _nome,
          objetivo: _objetivo,
          sessoes: sessoesJson,
          duracaoDias: _duracaoSemanas * 7,
          dataCriacaoOriginal: widget.rotinaData?['dataCriacao'] as Timestamp?,
        );
      } else {
        await RotinaService().criarRotina(
          alunoId: widget.alunoId,
          nome: _nome,
          objetivo: _objetivo,
          sessoes: sessoesJson,
          duracaoDias: _duracaoSemanas * 7,
        );
      }

      setState(() => _foiModificado = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rotina salva com sucesso!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTemplate =
        widget.rotinaData != null && widget.rotinaData!['alunoId'] == null;

    return PopScope(
      canPop: !_foiModificado,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final sair = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text(
              'Descartar alterações?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Você fez mudanças nesta rotina. Se voltar agora, elas não serão salvas no banco de dados.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Ficar',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Descartar',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        if (sair == true) {
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: AppTheme.background,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              expandedHeight: 138,
              leadingWidth: 60,
              leading: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Material(
                    color: AppTheme.buttonSurface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        if (!_foiModificado) {
                          Navigator.pop(context);
                        } else {
                          showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.surfaceDark,
                              title: const Text(
                                'Descartar alterações?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                'Você fez mudanças nesta rotina. Se voltar agora, elas não serão salvas no banco de dados.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    'Ficar',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Descartar',
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
                      },
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          CupertinoIcons.back,
                          color: AppTheme.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Semantics(
                  label: 'Editar',
                  button: true,
                  child: TextButton(
                    onPressed: () => _exibirModalInfo(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentMetrics,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Editar',
                      style: TextStyle(
                        color: AppTheme.accentMetrics,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double collapsedHeight =
                      MediaQuery.of(context).padding.top + kToolbarHeight;
                  final bool isCollapsed =
                      constraints.biggest.height <= collapsedHeight + 20;
                  final String title = _nome.isEmpty ? 'Nova Rotina' : _nome;

                  return FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 18),
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        // Fade + slight upward slide
                        final offsetAnimation =
                            Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                )
                                .chain(CurveTween(curve: Curves.easeOutCubic))
                                .animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: isCollapsed
                          ? SliverSafeTitle(
                              key: const ValueKey('collapsed_title'),
                              title: title,
                              isVisible: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('empty_title'),
                              height: 0,
                            ),
                    ),
                    background: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppTheme.space16,
                          right: AppTheme.space16,
                          bottom: 10,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isCollapsed ? 0.0 : 1.0,
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // O Resto da tela
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _objetivo.isEmpty ? 'Defina o objetivo' : _objetivo,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_duracaoSemanas semanas',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    isTemplate
                        ? _buildTemplateBadge()
                        : const SizedBox.shrink(),
                    isTemplate
                        ? const SizedBox(height: 24)
                        : const SizedBox.shrink(),

                    // --- CABEÇALHO DA LISTA DE SESSÕES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SESSÕES DE TREINO',
                          style: AppTheme.textSectionHeaderDark,
                        ),
                        if (_treinos.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              if (_treinos.length > 1) {
                                setState(() => _isReordering = !_isReordering);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Precisas de pelo menos 2 sessões para reordenar.',
                                    ),
                                    backgroundColor: AppTheme.surfaceLight,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isReordering
                                    ? AppTheme.primary.withAlpha(30)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isReordering
                                        ? Icons.check_rounded
                                        : Icons.swap_vert_outlined,
                                    size: 16,
                                    color: _isReordering
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isReordering ? 'Concluir' : 'Reordenar',
                                    style: TextStyle(
                                      color: _isReordering
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_treinos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 60,
                                color: Colors.white.withAlpha(20),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma sessão',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withAlpha(180),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_isReordering)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: _treinos.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _treinos.removeAt(oldIndex);
                            _treinos.insert(newIndex, item);
                            _foiModificado = true;
                          });
                        },
                        proxyDecorator: (child, index, animation) {
                          return Transform.scale(
                            scale: 1.0,
                            child: Material(
                              elevation: 0,
                              color: Colors.transparent,
                              child: child,
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          var sessao = _treinos[index];
                          return Container(
                            key: ValueKey(sessao),
                            child: _buildSessaoCard(
                              sessao,
                              index,
                              isReordering: true,
                            ),
                          );
                        },
                      )
                    else
                      ..._treinos.asMap().entries.map(
                        (entry) => _buildSessaoCard(
                          entry.value,
                          entry.key,
                          isReordering: false,
                        ),
                      ),

                    const SizedBox(height: 8),

                    if (!_isReordering) _buildAddSessaoButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: (_foiModificado || widget.rotinaId == null)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _salvarRotinaCompleta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              26,
                            ), // Pílula Perfeita
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _isLoading ? 'Salvando...' : 'Salvar',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // BOTÃO ADICIONAR SESSÃO - REFINADO (OUTLINE PILL)
  Widget _buildAddSessaoButton() {
    return InkWell(
      onTap: () => _exibirModalSessao(),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withAlpha(120),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Nova Sessão',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(24), // Ajustado para Pill Style
        border: Border.all(color: AppTheme.primary.withAlpha(30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.collections_bookmark, color: AppTheme.primary, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template de Biblioteca',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sem data de vencimento até ser atribuído.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessaoCard(
    _TreinoData sessao,
    int index, {
    required bool isReordering,
  }) {
    String letra = String.fromCharCode(65 + index);

    // Widget que contém o conteúdo do card
    final cardContent = Material(
      elevation: 1.0,
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: Colors.white.withAlpha(14), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingCard,
          vertical: AppTheme.space14,
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle, // Avatar agora é 100% redondo
              ),
              child: Center(
                child: Text(
                  letra,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.space6),
                  Text(
                    '${sessao.exercicios.length} ${sessao.exercicios.length == 1 ? 'exercício' : 'exercícios'}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: isReordering
                  ? ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.drag_indicator, // Ícone elegante de drag
                          color: AppTheme.textSecondary.withAlpha(80),
                          size: 20,
                        ),
                      ),
                    )
                  : PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      color: AppTheme.surfaceLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      position: PopupMenuPosition.under,
                      icon: Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary.withAlpha(160),
                        size: 28,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') _exibirModalSessao(index: index);
                        if (value == 'delete') _excluirTreino(index);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: AppTheme.textSecondary.withAlpha(200),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Editar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Excluir',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    return isReordering
        ? Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: cardContent,
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () async {
                final String? novoNomeTreino = await Navigator.push<String?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfigurarExerciciosPage(
                      nomeTreino: sessao.nome,
                      exercicios: sessao.exercicios,
                    ),
                  ),
                );
                if (!mounted) return;
                setState(() {
                  _foiModificado = true;
                  final novoNomeTrim = novoNomeTreino?.trim() ?? '';
                  if (novoNomeTrim.isNotEmpty && novoNomeTrim != sessao.nome) {
                    sessao.nome = novoNomeTrim;
                  }
                });
              },
              borderRadius: BorderRadius.circular(24), // Pill Style
              child: cardContent,
            ),
          );
  }
}