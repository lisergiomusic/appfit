import 'package:appfit/core/widgets/app_bar_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class FeedbackTreino {
  final int esforco;
  final String observacoes;

  const FeedbackTreino({required this.esforco, required this.observacoes});
}

class AlunoFeedbackTreinoPage extends StatefulWidget {
  final String sessaoNome;
  final int duracaoMinutos;

  const AlunoFeedbackTreinoPage({
    super.key,
    required this.sessaoNome,
    required this.duracaoMinutos,
  });

  @override
  State<AlunoFeedbackTreinoPage> createState() =>
      _AlunoFeedbackTreinoPageState();
}

class _AlunoFeedbackTreinoPageState extends State<AlunoFeedbackTreinoPage> {
  static const int _maxChars = 280;

  int? _esforco;
  final _obsController = TextEditingController();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  void _confirmar() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      FeedbackTreino(
        esforco: _esforco ?? 0,
        observacoes: _obsController.text.trim(),
      ),
    );
  }

  void _pular() {
    Navigator.of(context).pop(
      const FeedbackTreino(esforco: 0, observacoes: ''),
    );
  }

  String _esforcoLabel(int valor) {
    if (valor <= 3) return 'Fácil';
    if (valor <= 5) return 'Moderado';
    if (valor <= 7) return 'Intenso';
    if (valor <= 9) return 'Muito intenso';
    return 'Exaustivo';
  }

  Color _getEsforcoColor(int valor) {
    if (valor <= 3) return AppColors.primary;
    if (valor <= 5) return AppColors.primary;
    if (valor <= 7) return AppColors.accentMetrics;
    if (valor <= 9) return const Color(0xFFFF6B35);
    return AppColors.systemRed;
  }

  @override
  Widget build(BuildContext context) {
    final esforcoSelecionado = _esforco;
    final temEsforco = esforcoSelecionado != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Treino concluído', style: AppTheme.pageTitle),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _pular,
              child: Text(
                'PULAR',
                style: AppTheme.navBarAction.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.screenHorizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: SpacingTokens.screenTopPadding),
                _SessaoResumo(
                  nome: widget.sessaoNome,
                  duracao: widget.duracaoMinutos,
                ),
                const SizedBox(height: SpacingTokens.sectionGap),
                _SectionLabel(text: 'COMO FOI O ESFORÇO?'),
                const SizedBox(height: SpacingTokens.labelToField),
                _EsforcoGrid(
                  selecionado: esforcoSelecionado,
                  onSelect: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _esforco = v);
                  },
                  colorMapper: _getEsforcoColor,
                ),
                if (temEsforco) ...[
                  const SizedBox(height: 12),
                  _EsforcoIndicador(
                    valor: esforcoSelecionado,
                    label: _esforcoLabel(esforcoSelecionado),
                    color: _getEsforcoColor(esforcoSelecionado),
                  ),
                ],
                const SizedBox(height: 40),
                _SectionLabel(text: 'OBSERVAÇÕES (OPCIONAL)'),
                const SizedBox(height: SpacingTokens.labelToField),
                _ObservacoesField(
                  controller: _obsController,
                  maxChars: _maxChars,
                ),
                const SizedBox(height: 40),
                _ConfirmarButton(onPressed: _confirmar),
                const SizedBox(height: SpacingTokens.screenBottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessaoResumo extends StatelessWidget {
  final String nome;
  final int duracao;

  const _SessaoResumo({required this.nome, required this.duracao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: AppTheme.cardTitle),
                const SizedBox(height: 4),
                Text(
                  '$duracao minutos de atividade',
                  style: AppTheme.cardSubtitle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.sectionHeader.copyWith(
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _EsforcoGrid extends StatelessWidget {
  final int? selecionado;
  final ValueChanged<int> onSelect;
  final Color Function(int) colorMapper;

  const _EsforcoGrid({
    required this.selecionado,
    required this.onSelect,
    required this.colorMapper,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(10, (i) {
        final valor = i + 1;
        final ativo = selecionado == valor;
        final abaixo = selecionado != null && valor <= selecionado!;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(valor),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 9 ? 6 : 0),
              height: 44,
              decoration: BoxDecoration(
                color: abaixo
                    ? colorMapper(selecionado!).withAlpha(ativo ? 255 : 80)
                    : AppColors.surfaceLight.withAlpha(100),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: ativo ? Colors.white.withAlpha(50) : Colors.white.withAlpha(10),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$valor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: ativo ? FontWeight.w800 : FontWeight.w600,
                  color: abaixo ? Colors.white : AppColors.labelTertiary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EsforcoIndicador extends StatelessWidget {
  final int valor;
  final String label;
  final Color color;

  const _EsforcoIndicador({
    required this.valor,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: color.withAlpha(40), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$valor/10',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 10, color: color.withAlpha(60)),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservacoesField extends StatefulWidget {
  final TextEditingController controller;
  final int maxChars;

  const _ObservacoesField({
    required this.controller,
    required this.maxChars,
  });

  @override
  State<_ObservacoesField> createState() => _ObservacoesFieldState();
}

class _ObservacoesFieldState extends State<_ObservacoesField> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _count = widget.controller.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: Colors.white.withAlpha(15), width: 0.5),
          ),
          child: TextField(
            controller: widget.controller,
            maxLength: widget.maxChars,
            maxLines: 4,
            minLines: 4,
            buildCounter: (_,
                    {required currentLength,
                    required isFocused,
                    maxLength}) =>
                null,
            style: AppTheme.bodyText.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Como você se sentiu hoje?',
              hintStyle: TextStyle(
                fontSize: 15,
                color: AppColors.labelTertiary.withAlpha(150),
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_count/${widget.maxChars}',
          style: AppTheme.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _ConfirmarButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConfirmarButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ),
        child: const Text(
          'SALVAR FEEDBACK',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}