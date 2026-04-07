import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/aluno_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import '../alunos/models/aluno_perfil_data.dart';
import '../treinos/aluno_rotina_view_page.dart';

class AlunoHomePage extends StatelessWidget {
  final String uid;
  const AlunoHomePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final service = AlunoService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Início'),
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

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SpacingTokens.screenTopPadding),
                  _buildHeader(nome, photoUrl),
                  const SizedBox(height: SpacingTokens.xxl),
                  _buildPesoCard(context, aluno, uid),
                  const SizedBox(height: SpacingTokens.xxl),
                  Text('Sua planilha atual', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
                  rotina != null
                      ? _buildRotinaCard(context, rotina, rotinaId)
                      : _buildSemTreinoCard(),
                  const SizedBox(height: SpacingTokens.screenBottomPadding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPesoCard(BuildContext context, Map<String, dynamic> aluno, String uid) {
    final pesoAtual = aluno['pesoAtual'] as double?;
    final pesoCodigo = pesoAtual != null ? '${pesoAtual.toStringAsFixed(1)} kg' : 'Não registrado';

    return Row(
      children: [
        Icon(
          Icons.monitor_weight_outlined,
          color: AppColors.labelSecondary,
          size: 20,
        ),
        const SizedBox(width: SpacingTokens.md),
        Text(
          'Peso atual: $pesoCodigo',
          style: AppTheme.cardSubtitle,
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _abrirEdicaoPeso(context, uid, pesoAtual),
          icon: const Icon(Icons.edit_outlined),
          iconSize: 20,
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um peso válido')),
      );
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
      final alunoDoc = await widget.service.getAluno(widget.uid);
      final alunoData = alunoDoc.data() as Map<String, dynamic>;

      await widget.service.atualizarAluno(
        alunoId: widget.uid,
        nome: alunoData['nome'] ?? '',
        sobrenome: alunoData['sobrenome'] ?? '',
        email: alunoData['email'] ?? '',
        peso: peso,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar peso: $e')),
        );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Atualizar peso', style: AppTheme.title1),
          const SizedBox(height: SpacingTokens.sectionGap),
          TextField(
            controller: _pesoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: 'Ex: 75.5',
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.sectionGap),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fillSecondary,
                    disabledBackgroundColor: AppColors.fillSecondary.withAlpha(100),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarPeso,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.labelSecondary,
                            ),
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
