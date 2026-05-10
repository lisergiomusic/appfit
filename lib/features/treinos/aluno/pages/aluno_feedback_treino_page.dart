import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:appfit/core/widgets/app_premium_fab.dart';
import 'package:appfit/core/widgets/sliver_safe_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';

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
      floatingActionButton: AppPremiumFAB(
        label: 'Salvar Feedback',
        icon: Icons.check_circle_outline_rounded,
        onPressed: _confirmar,
        isFullWidth: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          AppFitSliverAppBar(
            title: 'Feedback do Treino',
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _pular,
                  child: Text(
                    'PULAR',
                    style: AppTheme.navBarAction.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
            background: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TREINO CONCLUÍDO',
                    style: AppTheme.sectionHeader.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Feedback do Treino',
                    style: AppTheme.pageTitle.copyWith(fontSize: 28),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.screenHorizontalPadding,
              24,
              SpacingTokens.screenHorizontalPadding,
              120, // Space for FAB
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SessaoResumo(
                  nome: widget.sessaoNome,
                  duracao: widget.duracaoMinutos,
                ),
                const SizedBox(height: 40),
                const _SectionLabel(text: 'COMO FOI O ESFORÇO?'),
                const SizedBox(height: 16),
                _EsforcoGrid(
                  selecionado: esforcoSelecionado,
                  onSelect: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _esforco = v);
                  },
                  colorMapper: _getEsforcoColor,
                ),
                if (temEsforco) ...[
                  const SizedBox(height: 16),
                  _EsforcoIndicador(
                    valor: esforcoSelecionado,
                    label: _esforcoLabel(esforcoSelecionado),
                    color: _getEsforcoColor(esforcoSelecionado),
                  ),
                ],
                const SizedBox(height: 40),
                const _SectionLabel(text: 'OBSERVAÇÕES (OPCIONAL)'),
                const SizedBox(height: 16),
                _ObservacoesField(
                  controller: _obsController,
                  maxChars: _maxChars,
                ),
              ]),
            ),
          ),
        ],
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: onSurface.withAlpha(12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: onSurface.withAlpha(20), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(40),
                  AppColors.primary.withAlpha(10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: AppTheme.cardTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  '$duracao MINUTOS DE ATIVIDADE',
                  style: AppTheme.cardSubtitle.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
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
        fontSize: 12,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w900,
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: 10,
      itemBuilder: (context, i) {
        final valor = i + 1;
        final ativo = selecionado == valor;
        final abaixo = selecionado != null && valor <= selecionado!;

        return _TactileItem(
          onTap: () => onSelect(valor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: abaixo
                  ? colorMapper(selecionado!).withAlpha(ativo ? 255 : 60)
                  : onSurface.withAlpha(12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(
                color: ativo ? Colors.white.withAlpha(60) : onSurface.withAlpha(15),
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$valor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: ativo ? FontWeight.w900 : FontWeight.w700,
                color: abaixo ? (ativo ? Colors.black : Colors.white) : onSurface.withAlpha(100),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TactileItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileItem({required this.child, required this.onTap});

  @override
  State<_TactileItem> createState() => _TactileItemState();
}

class _TactileItemState extends State<_TactileItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 14, color: color.withAlpha(60)),
            const SizedBox(width: 12),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: onSurface.withAlpha(12),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: onSurface.withAlpha(20), width: 0.5),
          ),
          child: TextField(
            controller: widget.controller,
            maxLength: widget.maxChars,
            maxLines: 5,
            minLines: 5,
            buildCounter: (_,
                    {required currentLength,
                    required isFocused,
                    maxLength}) =>
                null,
            style: AppTheme.bodyText.copyWith(fontSize: 16, height: 1.5),
            decoration: InputDecoration(
              hintText: 'COMO VOCÊ SE SENTIU HOJE?',
              hintStyle: TextStyle(
                fontSize: 12,
                color: onSurface.withAlpha(60),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              contentPadding: const EdgeInsets.all(20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_count / ${widget.maxChars}',
          style: AppTheme.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: onSurface.withAlpha(100),
          ),
        ),
      ],
    );
  }
}