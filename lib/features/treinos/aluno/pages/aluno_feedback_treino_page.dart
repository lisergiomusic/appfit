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

  Color _esforcoColor(int valor) {
    if (valor <= 3) return const Color(0xFF30D158);
    if (valor <= 5) return const Color(0xFF30D158);
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
        automaticallyImplyLeading: false,
        title: Text('Treino concluído', style: AppTheme.pageTitle),
        centerTitle: true,
        actions: [AppBarTextButton(label: 'Pular', onPressed: _pular)],
      ),
      body: SafeArea(
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
              _SectionLabel(text: 'Como foi o esforço?'),
              const SizedBox(height: SpacingTokens.labelToField),
              _EsforcoGrid(
                selecionado: esforcoSelecionado,
                onSelect: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _esforco = v);
                },
              ),
              if (temEsforco) ...[
                const SizedBox(height: SpacingTokens.sm),
                _EsforcoIndicador(
                  valor: esforcoSelecionado,
                  label: _esforcoLabel(esforcoSelecionado),
                  color: _esforcoColor(esforcoSelecionado),
                ),
              ],
              const SizedBox(height: SpacingTokens.xxl),
              _SectionLabel(text: 'Observações (Opcional)'),
              const SizedBox(height: SpacingTokens.labelToField),
              _ObservacoesField(
                controller: _obsController,
                maxChars: _maxChars,
              ),
              const Spacer(),
              _ConfirmarButton(onPressed: _confirmar),
              const SizedBox(height: SpacingTokens.screenBottomPadding),
            ],
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
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
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
              const SizedBox(height: SpacingTokens.xs),
              Text(
                '$duracao min',
                style: AppTheme.cardSubtitle,
              ),
            ],
          ),
        ),
      ],
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.08,
        color: AppColors.labelSecondary,
      ),
    );
  }
}

class _EsforcoGrid extends StatelessWidget {
  final int? selecionado;
  final ValueChanged<int> onSelect;

  const _EsforcoGrid({required this.selecionado, required this.onSelect});

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
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: i < 9 ? 4 : 0),
              height: 40,
              decoration: BoxDecoration(
                color: abaixo
                    ? _barColor(selecionado!).withValues(alpha: ativo ? 1.0 : 0.45)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              alignment: Alignment.center,
              child: Text(
                '$valor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                  color: abaixo ? Colors.white : AppColors.labelTertiary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _barColor(int valor) {
    if (valor <= 3) return const Color(0xFF30D158);
    if (valor <= 5) return const Color(0xFF30D158);
    if (valor <= 7) return AppColors.accentMetrics;
    if (valor <= 9) return const Color(0xFFFF6B35);
    return AppColors.systemRed;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$valor/10',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          '· $label',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
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
            style: AppTheme.bodyText,
            decoration: InputDecoration(
              hintText: 'Como foi o treino de hoje?',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: AppColors.labelTertiary,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.cardPaddingH,
                vertical: SpacingTokens.cardPaddingV,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          '$_count/${widget.maxChars}',
          style: AppTheme.caption,
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
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
        child: const Text(
          'Salvar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
    );
  }
}