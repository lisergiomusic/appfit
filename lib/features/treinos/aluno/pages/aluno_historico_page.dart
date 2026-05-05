import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/aluno/widgets/peso_historico_card.dart';
import '../controllers/historico_controller.dart';

class AlunoHistoricoPage extends StatelessWidget {
  final String uid;
  const AlunoHistoricoPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoricoController(uid: uid),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('Meu histórico'),
          ),
        ),
        body: const _HistoricoContent(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conteúdo principal
// ─────────────────────────────────────────────────────────────────────────────

class _HistoricoContent extends StatelessWidget {
  const _HistoricoContent();

  void _abrirEdicaoPeso(BuildContext context, double? pesoAtual) {
    final controller = context.read<HistoricoController>();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => _PesoEditSheet(
        pesoAtual: pesoAtual,
        onSalvar: (peso) => controller.registrarPeso(peso),
      ),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoricoController>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SpacingTokens.lg),
          const _CalendarioFrequenciaCard(),
          const SizedBox(height: SpacingTokens.xxl),
          StreamBuilder<dynamic>(
            stream: controller.pesoStream,
            builder: (context, historicoSnap) {
              if (historicoSnap.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Erro ao carregar histórico de peso',
                      style: TextStyle(color: AppColors.labelTertiary),
                    ),
                  ),
                );
              }

              if (historicoSnap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final List<Map<String, dynamic>>? historico =
                  historicoSnap.hasData
                      ? List<Map<String, dynamic>>.from(historicoSnap.data!)
                      : null;
              final double? pesoAtual =
                  historico != null && historico.isNotEmpty
                      ? (historico.first['peso'] as num?)?.toDouble()
                      : null;
              return PesoHistoricoCard(
                pesoAtual: pesoAtual,
                historico: historico,
                onAdicionarPeso: () => _abrirEdicaoPeso(context, pesoAtual),
              );
            },
          ),
          const SizedBox(height: SpacingTokens.screenBottomPadding),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendário mensal de frequência
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarioFrequenciaCard extends StatelessWidget {
  const _CalendarioFrequenciaCard();

  void _onDiaTapped(
    BuildContext context,
    List<Map<String, dynamic>> logs,
    DateTime data,
  ) {
    if (logs.length == 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _TreinoDetalheSheet(log: logs.first),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DiaTreinosSheet(logs: logs, data: data),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoricoController>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.logsStream,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final logsPorDia = controller.processarLogs(logs);
        final isCarregando =
            snapshot.connectionState == ConnectionState.waiting;

        final hoje = DateTime.now();
        final mesAtual = controller.mesAtual;
        final isUltimoMes = controller.isUltimoMes;

        final nomeMesRaw = DateFormat('MMMM', 'pt_BR').format(mesAtual);
        final nomeMes = nomeMesRaw[0].toUpperCase() + nomeMesRaw.substring(1);
        final diasNoMes =
            DateUtils.getDaysInMonth(mesAtual.year, mesAtual.month);
        final primeiroDia = DateTime(mesAtual.year, mesAtual.month, 1);
        final offsetInicio = (primeiroDia.weekday - 1) % 7;

        final treinosNoMes = logsPorDia.keys
            .where(
              (d) => d.year == mesAtual.year && d.month == mesAtual.month,
            )
            .length;

        return Container(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              // ── Cabeçalho ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$nomeMes ${mesAtual.year}',
                                style: CardTokens.cardTitle,
                              ),
                              if (isCarregando) ...[
                                const SizedBox(width: 8),
                                const SizedBox(
                                  height: 12,
                                  width: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            treinosNoMes == 0
                                ? 'Nenhum treino neste mês'
                                : treinosNoMes == 1
                                    ? '1 treino neste mês'
                                    : '$treinosNoMes treinos neste mês',
                            style: AppTheme.caption.copyWith(
                              color: treinosNoMes > 0
                                  ? AppColors.primary
                                  : AppColors.labelTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => controller.irParaMesAnterior(),
                    ),
                    const SizedBox(width: 4),
                    _NavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: isUltimoMes ? null : () => controller.irParaProximoMes(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Labels dias da semana ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']
                      .asMap()
                      .entries
                      .map(
                        (e) => Expanded(
                          child: Text(
                            e.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: e.key == 6
                                  ? AppColors.systemRed.withAlpha(150)
                                  : AppColors.labelTertiary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              // ── Grade de dias ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 0,
                    childAspectRatio: 1,
                  ),
                  itemCount: offsetInicio + diasNoMes,
                  itemBuilder: (context, index) {
                    if (index < offsetInicio) return const SizedBox.shrink();

                    final dia = index - offsetInicio + 1;
                    final data = DateTime(mesAtual.year, mesAtual.month, dia);
                    final logsNoDia = logsPorDia[data];
                    final treinado = logsNoDia != null && logsNoDia.isNotEmpty;
                    final ehHoje =
                        data.year == hoje.year &&
                        data.month == hoje.month &&
                        data.day == hoje.day;
                    final futuro = data.isAfter(hoje);
                    final isDomingo = index % 7 == 6;

                    return _DiaCelula(
                      dia: dia,
                      treinado: treinado,
                      ehHoje: ehHoje,
                      futuro: futuro,
                      isDomingo: isDomingo,
                      onTap: treinado
                          ? () => _onDiaTapped(context, logsNoDia, data)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ativo = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: ativo ? 1.0 : 0.3,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.fillSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Icon(icon, size: 18, color: AppColors.labelPrimary),
        ),
      ),
    );
  }
}

class _DiaCelula extends StatelessWidget {
  final int dia;
  final bool treinado;
  final bool ehHoje;
  final bool futuro;
  final bool isDomingo;
  final VoidCallback? onTap;

  const _DiaCelula({
    required this.dia,
    required this.treinado,
    required this.ehHoje,
    required this.futuro,
    required this.isDomingo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    FontWeight fontWeight;
    BoxBorder? border;

    if (treinado) {
      bgColor = AppColors.primary;
      textColor = Colors.black;
      fontWeight = FontWeight.w700;
      border = null;
    } else if (ehHoje) {
      bgColor = AppColors.primary.withAlpha(20);
      textColor = AppColors.primary;
      fontWeight = FontWeight.w700;
      border = Border.all(color: AppColors.primary, width: 1.5);
    } else if (futuro) {
      bgColor = Colors.transparent;
      textColor = AppColors.labelQuaternary;
      fontWeight = FontWeight.w400;
      border = null;
    } else {
      bgColor = Colors.transparent;
      textColor = isDomingo
          ? AppColors.systemRed.withAlpha(140)
          : AppColors.labelSecondary;
      fontWeight = FontWeight.w400;
      border = null;
    }

    final cell = Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          '$dia',
          style: TextStyle(
            fontSize: 12,
            fontWeight: fontWeight,
            color: textColor,
            letterSpacing: -0.2,
            height: 1,
          ),
        ),
      ),
    );

    if (onTap == null) return cell;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: múltiplos treinos no mesmo dia
// ─────────────────────────────────────────────────────────────────────────────

class _DiaTreinosSheet extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final DateTime data;

  const _DiaTreinosSheet({required this.logs, required this.data});

  @override
  Widget build(BuildContext context) {
    final dataLabel =
        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(data);
    final dataCapitalizada =
        dataLabel[0].toUpperCase() + dataLabel.substring(1);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.labelSecondary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(dataCapitalizada, style: CardTokens.cardTitle),
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.labelSecondary.withAlpha(20),
          ),
          ...List.generate(logs.length, (i) {
            final log = logs[i];
            final sessaoNome = log['sessaoNome'] as String? ?? '—';
            final tsRaw = log['dataHora'];
            final dt = tsRaw != null ? DateTime.tryParse(tsRaw.toString()) : null;
            final horaFormatada =
                dt != null ? DateFormat('HH:mm').format(dt) : '';
            final letra =
                sessaoNome.isNotEmpty ? sessaoNome[0].toUpperCase() : '?';
            final isLast = i == logs.length - 1;

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _TreinoDetalheSheet(log: log),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.cardPaddingH,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(18),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letra,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sessaoNome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.labelPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (horaFormatada.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            horaFormatada,
                            style: AppTheme.caption.copyWith(
                              color: AppColors.labelSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.labelSecondary.withAlpha(80),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.labelSecondary.withAlpha(20),
                    indent: 56,
                  ),
              ],
            );
          }),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + SpacingTokens.lg,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet com detalhe do treino
// ─────────────────────────────────────────────────────────────────────────────

class _TreinoDetalheSheet extends StatelessWidget {
  final Map<String, dynamic> log;
  const _TreinoDetalheSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final sessaoNome = log['sessaoNome'] as String? ?? '—';
    final tsRaw = log['dataHora'];
    final ts = tsRaw != null ? DateTime.tryParse(tsRaw.toString()) : null;
    final dt = ts;
    final exercicios = log['exercicios'] as List? ?? [];

    final dataFormatada = dt != null
        ? DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR').format(dt)
        : '—';
    final horaFormatada = dt != null ? DateFormat('HH:mm').format(dt) : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXXL),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.labelSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sessaoNome.isNotEmpty
                            ? sessaoNome[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sessaoNome,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.labelPrimary,
                              letterSpacing: -0.4,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dataFormatada · $horaFormatada',
                            style: AppTheme.caption.copyWith(
                              color: AppColors.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.labelSecondary.withAlpha(20),
              ),

              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: exercicios.length,
                  separatorBuilder: (_, index) =>
                      const SizedBox(height: SpacingTokens.sm),
                  itemBuilder: (context, i) {
                    final ex = exercicios[i] as Map<String, dynamic>;
                    return _ExercicioLogCard(exercicio: ex);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet para registrar peso
// ─────────────────────────────────────────────────────────────────────────────

class _PesoEditSheet extends StatefulWidget {
  final double? pesoAtual;
  final Future<void> Function(double peso) onSalvar;

  const _PesoEditSheet({
    required this.pesoAtual,
    required this.onSalvar,
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
      await widget.onSalvar(peso);

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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      padding: EdgeInsets.only(
        left: SpacingTokens.screenHorizontalPadding,
        right: SpacingTokens.screenHorizontalPadding,
        top: SpacingTokens.lg,
        bottom: keyboardHeight + SpacingTokens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.labelSecondary.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text('Registrar peso', style: AppTheme.title1),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Seu peso atual será atualizado',
            style: AppTheme.caption.copyWith(
              color: AppColors.labelSecondary.withAlpha(180),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          if (widget.pesoAtual != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Peso atual: ${widget.pesoAtual!.toStringAsFixed(1)} kg',
                style: AppTheme.caption2.copyWith(
                  color: AppColors.labelSecondary.withAlpha(150),
                ),
              ),
            ),
          const SizedBox(height: SpacingTokens.sm),
          TextField(
            controller: _pesoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de exercício dentro do detalhe
// ─────────────────────────────────────────────────────────────────────────────

class _ExercicioLogCard extends StatelessWidget {
  final Map<String, dynamic> exercicio;
  const _ExercicioLogCard({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final nome = exercicio['nome'] as String? ?? 'Exercício';
    final series = exercicio['series'] as List? ?? [];

    final concluidas = series.where((s) => s['concluida'] == true).toList();
    final totalSeries = series.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelPrimary,
                    letterSpacing: -0.2,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: concluidas.length == totalSeries && totalSeries > 0
                      ? AppColors.primary.withAlpha(20)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${concluidas.length}/$totalSeries séries',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: concluidas.length == totalSeries && totalSeries > 0
                        ? AppColors.primary
                        : AppColors.labelSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),

          if (concluidas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: const [
                SizedBox(width: 24),
                Expanded(
                  child: Text(
                    'REPS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'PESO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(concluidas.length, (i) {
              final serie = concluidas[i] as Map<String, dynamic>;
              final peso = serie['pesoRealizado'] as String? ?? '—';
              final reps = serie['repsRealizadas'] as String? ?? '—';
              final tipo = serie['tipo'] as String? ?? 'trabalho';
              final isTrabalho = tipo == 'trabalho';

              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isTrabalho
                              ? AppColors.labelSecondary
                              : AppColors.labelTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        reps.isNotEmpty ? '$reps reps' : '—',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isTrabalho
                              ? AppColors.labelPrimary
                              : AppColors.labelSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        peso.isNotEmpty ? '$peso kg' : '—',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isTrabalho
                              ? AppColors.labelPrimary
                              : AppColors.labelSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}