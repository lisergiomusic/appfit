import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../core/services/aluno_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import '../alunos/models/aluno_perfil_data.dart';
import '../treinos/aluno_rotina_view_page.dart';
import '../treinos/models/rotina_model.dart';
import '../treinos/executar_treino_page.dart';
import '../alunos/widgets/ritmo_da_semana_card.dart';
import 'widgets/peso_historico_card.dart';

class AlunoHomePage extends StatelessWidget {
  final String uid;
  const AlunoHomePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final service = AlunoService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.systemRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: const AppBarDivider(),
      ),
      body: StreamBuilder<AlunoPerfilData>(
        stream: service.getAlunoPerfilCompletoStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'Erro ao carregar dados.',
                style: TextStyle(color: AppColors.labelSecondary),
              ),
            );
          }

          final data = snapshot.data!;
          final aluno = data.aluno;
          final rotina = data.rotinaAtiva;
          final rotinaId = data.rotinaId;

          final nome = aluno['nome']?.toString().split(' ')[0] ?? 'Aluno';
          final photoUrl = aluno['photoUrl'] as String?;
          final recado = aluno['recadoPersonal'] as String?;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.screenHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SpacingTokens.screenTopPadding),
                  _buildHeader(nome, photoUrl),
                  const SizedBox(height: SpacingTokens.xxl),
                  StreamBuilder<QuerySnapshot>(
                    stream: service.getLogsDaSemanaStream(uid),
                    builder: (context, logsSnap) {
                      List<DateTime>? diasTreinados;

                      if (logsSnap.connectionState != ConnectionState.waiting &&
                          logsSnap.hasData) {
                        diasTreinados = logsSnap.data!.docs
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final ts = data['dataHora'] as Timestamp?;
                              return ts?.toDate();
                            })
                            .whereType<DateTime>()
                            .toList();
                      }

                      return RitmoDaSemanaCard(
                        alunoNome: nome,
                        diasTreinados: diasTreinados,
                        isAlunoView: true,
                      );
                    },
                  ),
                  const SizedBox(height: SpacingTokens.xxl),
                  Text('Sua planilha atual', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
                  rotina != null
                      ? _buildRotinaCard(context, rotina, rotinaId)
                      : _buildSemTreinoCard(),
                  const SizedBox(height: SpacingTokens.xxl),
                  if (recado != null && recado.isNotEmpty) ...[
                    _buildRecadoCard(recado),
                    const SizedBox(height: SpacingTokens.xxl),
                  ],
                  if (rotina != null) ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: service.getUltimoLogStream(uid),
                      builder: (context, ultimoLogSnap) {
                        final sessoes = (rotina['sessoes'] as List? ?? [])
                            .map(
                              (s) => SessaoTreinoModel.fromFirestore(
                                s as Map<String, dynamic>,
                              ),
                            )
                            .toList();

                        if (sessoes.isEmpty) return const SizedBox.shrink();

                        SessaoTreinoModel proxSessao = sessoes.first;

                        if (ultimoLogSnap.hasData &&
                            ultimoLogSnap.data!.docs.isNotEmpty) {
                          final lastLog =
                              ultimoLogSnap.data!.docs.first.data()
                                  as Map<String, dynamic>;
                          final ultimoNome =
                              lastLog['sessaoNome'] as String? ?? '';
                          final idx = sessoes.indexWhere(
                            (s) => s.nome == ultimoNome,
                          );
                          if (idx != -1) {
                            proxSessao = sessoes[(idx + 1) % sessoes.length];
                          }
                        }

                        return _buildProximoTreinoCard(
                          context,
                          proxSessao,
                          sessoes.indexOf(proxSessao),
                          rotinaId!,
                          uid,
                        );
                      },
                    ),
                    const SizedBox(height: SpacingTokens.xxl),
                  ],
                  StreamBuilder<QuerySnapshot>(
                    stream: service.getHistoricoPesoStream(uid),
                    builder: (context, historicoSnap) {
                      final pesoAtual = aluno['pesoAtual'] as double?;
                      final historico = historicoSnap.hasData
                          ? historicoSnap.data!.docs
                                .map(
                                  (doc) => doc.data() as Map<String, dynamic>,
                                )
                                .toList()
                          : null;

                      return PesoHistoricoCard(
                        pesoAtual: pesoAtual,
                        historico: historico,
                        onAdicionarPeso: () =>
                            _abrirEdicaoPeso(context, uid, pesoAtual),
                      );
                    },
                  ),
                  const SizedBox(height: SpacingTokens.screenBottomPadding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _abrirEdicaoPeso(BuildContext context, String uid, double? pesoAtual) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => _PesoEditSheet(
        uid: uid,
        pesoAtual: pesoAtual,
        service: AlunoService(),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildHeader(String nome, String? photoUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: AvatarTokens.lg,
          backgroundColor: AppColors.surfaceLight,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? const Icon(
                  Icons.person_rounded,
                  color: AppColors.labelSecondary,
                  size: 28,
                )
              : null,
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getSaudacao()}, $nome', style: AppTheme.title1),
            const SizedBox(height: SpacingTokens.titleToSubtitle),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: PillTokens.decoration,
              child: Text('Aluno', style: PillTokens.text),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRotinaCard(
    BuildContext context,
    Map<String, dynamic> rotina,
    String? rotinaId,
  ) {
    final nomeRotina = rotina['nome'] as String? ?? 'Meu treino';
    final objetivo = rotina['objetivo'] as String? ?? '';
    final tipoVencimento = rotina['tipoVencimento'] as String? ?? 'data';

    double progressoAtual = 0.0;
    String legendaVencimento = '';

    if (tipoVencimento == 'sessoes') {
      final totalSessoes = (rotina['vencimentoSessoes'] as int?) ?? 1;
      final concluidas = (rotina['sessoesConcluidas'] as int?) ?? 0;
      progressoAtual = (concluidas / totalSessoes).clamp(0.0, 1.0);
      legendaVencimento =
          '$concluidas de $totalSessoes ${totalSessoes == 1 ? 'sessão' : 'sessões'}';
    } else {
      final hoje = DateTime.now();
      final dataCriacao =
          (rotina['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
      final dataVencimento =
          (rotina['dataVencimento'] as Timestamp?)?.toDate() ??
          hoje.add(const Duration(days: 30));
      int totalDias = dataVencimento.difference(dataCriacao).inDays;
      if (totalDias <= 0) totalDias = 1;
      final diasPassados = hoje.difference(dataCriacao).inDays;
      progressoAtual = (diasPassados / totalDias).clamp(0.0, 1.0);
      legendaVencimento =
          'Vencimento em ${DateFormat('dd/MM').format(dataVencimento)}';
    }

    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: rotinaId != null
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlunoRotinaViewPage(
                    rotinaData: rotina,
                    rotinaId: rotinaId,
                    alunoId: uid,
                  ),
                ),
              )
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progressoAtual,
                      strokeWidth: 6,
                      backgroundColor: AppColors.primary.withAlpha(15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeRotina,
                      style: CardTokens.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (objetivo.isNotEmpty)
                      Text(
                        objetivo,
                        style: AppTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      legendaVencimento,
                      style: AppTheme.caption2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.labelSecondary.withAlpha(80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemTreinoCard() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.cardPaddingH,
        vertical: SpacingTokens.xxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 40,
            color: AppColors.labelSecondary.withAlpha(80),
          ),
          const SizedBox(height: SpacingTokens.sm),
          const Text('Nenhum treino atribuído', style: AppTheme.cardTitle),
          const SizedBox(height: SpacingTokens.xs),
          const Text(
            'Aguarde seu personal atribuir uma rotina.',
            style: AppTheme.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildRecadoCard(String recado) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.cardPaddingH,
        vertical: SpacingTokens.cardPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Recado do seu Personal',
                style: AppTheme.caption2.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(recado, style: AppTheme.cardSubtitle),
        ],
      ),
    );
  }

  Widget _buildProximoTreinoCard(
    BuildContext context,
    SessaoTreinoModel sessao,
    int sessaoIndex,
    String rotinaId,
    String alunoId,
  ) {
    final letra = String.fromCharCode(65 + (sessaoIndex % 26));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximo treino', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: AppTheme.cardDecoration,
          padding: CardTokens.padding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                alignment: Alignment.center,
                child: Text(
                  letra,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessao.nome, style: CardTokens.cardTitle),
                    Text(
                      '${sessao.exercicios.length} exercício${sessao.exercicios.length != 1 ? 's' : ''}',
                      style: AppTheme.cardSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              SizedBox(
                width: 80,
                height: 40,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExecutarTreinoPage(
                        sessao: sessao,
                        rotinaId: rotinaId,
                        alunoId: alunoId,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Iniciar',
                          style: AppTheme.caption2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PesoEditSheet extends StatefulWidget {
  final String uid;
  final double? pesoAtual;
  final AlunoService service;

  const _PesoEditSheet({
    required this.uid,
    required this.pesoAtual,
    required this.service,
  });

  @override
  State<_PesoEditSheet> createState() => _PesoEditSheetState();
}

class _PesoEditSheetState extends State<_PesoEditSheet> {
  late TextEditingController _pesoController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pesoController = TextEditingController(
      text: widget.pesoAtual?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _salvarPeso() async {
    final pesoText = _pesoController.text.trim();
    if (pesoText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um peso válido')));
      return;
    }

    final peso = double.tryParse(pesoText);
    if (peso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato inválido. Use números.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.service.registrarPeso(alunoId: widget.uid, peso: peso);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar peso: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        left: SpacingTokens.screenHorizontalPadding,
        right: SpacingTokens.screenHorizontalPadding,
        top: SpacingTokens.lg,
        bottom: keyboardHeight + SpacingTokens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.labelSecondary.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          // Header
          Column(
            children: [
              Text('Registrar peso', style: AppTheme.title1),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                'Seu peso atual será atualizado',
                style: AppTheme.caption.copyWith(
                  color: AppColors.labelSecondary.withAlpha(180),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          // Input field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.pesoAtual != null)
                Text(
                  'Peso atual: ${widget.pesoAtual!.toStringAsFixed(1)} kg',
                  style: AppTheme.caption2.copyWith(
                    color: AppColors.labelSecondary.withAlpha(150),
                  ),
                ),
              const SizedBox(height: SpacingTokens.sm),
              TextField(
                controller: _pesoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: !_isSaving,
                textAlign: TextAlign.center,
                style: AppTheme.title1,
                decoration: InputDecoration(
                  hintText: '0.0',
                  suffixText: 'kg',
                  hintStyle: AppTheme.title1.copyWith(
                    color: AppColors.labelSecondary.withAlpha(100),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    borderSide: const BorderSide(
                      color: AppColors.fillSecondary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    borderSide: const BorderSide(
                      color: AppColors.fillSecondary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          // Buttons
          Column(
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : _salvarPeso,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.labelPrimary,
                          ),
                        ),
                      )
                    : const Text('Salvar'),
              ),
              const SizedBox(height: SpacingTokens.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
