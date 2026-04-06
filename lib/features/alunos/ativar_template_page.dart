import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/aluno_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_nav_back_button.dart';
import '../../core/widgets/app_primary_button.dart';
import '../treinos/widgets/rotina_input_decoration.dart';

class AtivarTemplatePage extends StatefulWidget {
  final String templateId;
  final String alunoId;
  final String alunoNome;

  const AtivarTemplatePage({
    super.key,
    required this.templateId,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  State<AtivarTemplatePage> createState() => _AtivarTemplatePageState();
}

class _AtivarTemplatePageState extends State<AtivarTemplatePage> {
  final AlunoService _alunoService = AlunoService();

  String _tipoVencimento = 'sessoes';
  final TextEditingController _sessoesCtrl = TextEditingController();
  DateTime _dataVencimento = DateTime.now().add(const Duration(days: 30));

  bool _salvando = false;

  @override
  void dispose() {
    _sessoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _ativar(Map<String, dynamic> template) async {
    if (_tipoVencimento == 'sessoes' &&
        (int.tryParse(_sessoesCtrl.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um número de sessões válido.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await _alunoService.atribuirTreinoAoAluno(
        alunoId: widget.alunoId,
        templateId: widget.templateId,
        tipoVencimento: _tipoVencimento,
        sessoesAlvo: _tipoVencimento == 'sessoes'
            ? int.parse(_sessoesCtrl.text)
            : null,
        dataVencimento: _tipoVencimento == 'data' ? _dataVencimento : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao ativar rotina: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppNavBackButton(),
        title: const Text('Prescrever Treino'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('rotinas')
            .doc(widget.templateId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Rotina não encontrada.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final template = snapshot.data!.data() as Map<String, dynamic>;
          final sessoes =
              (template['sessoes'] as List?)?.cast<Map<String, dynamic>>() ??
              [];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.paddingScreen),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TemplateInfoCard(
                    template: template,
                    qtdSessoes: sessoes.length,
                  ),
                  const SizedBox(height: SpacingTokens.sectionGap),
                  if (sessoes.isNotEmpty) ...[
                    _SessoesPreview(sessoes: sessoes),
                    const SizedBox(height: SpacingTokens.sectionGap),
                  ],
                  _PeriodizacaoSection(
                    tipoVencimento: _tipoVencimento,
                    sessoesCtrl: _sessoesCtrl,
                    dataVencimento: _dataVencimento,
                    onTipoChanged: (v) => setState(() => _tipoVencimento = v),
                    onDataChanged: (v) => setState(() => _dataVencimento = v),
                  ),
                  const SizedBox(height: SpacingTokens.sectionGap),
                  Opacity(
                    opacity: _salvando ? 0.75 : 1,
                    child: IgnorePointer(
                      ignoring: _salvando,
                      child: AppPrimaryButton(
                        icon: Icons.play_arrow_rounded,
                        label: _salvando
                            ? 'Ativando...'
                            : 'Ativar para ${widget.alunoNome.split(' ').first}',
                        onPressed: () => _ativar(template),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Subwidgets ──────────────────────────────────────────────────────────────

class _TemplateInfoCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final int qtdSessoes;

  const _TemplateInfoCard({required this.template, required this.qtdSessoes});

  @override
  Widget build(BuildContext context) {
    final nome = template['nome'] as String? ?? 'Rotina';
    final objetivo = template['objetivo'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nome, style: AppTheme.title1),
          if (objetivo.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.titleToSubtitle),
            Text(objetivo, style: CardTokens.cardSubtitle),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: AppColors.primary,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text('$qtdSessoes sessões planejadas', style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessoesPreview extends StatelessWidget {
  final List<Map<String, dynamic>> sessoes;

  const _SessoesPreview({required this.sessoes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sessões', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        ...sessoes.asMap().entries.map((entry) {
          final i = entry.key;
          final sessao = entry.value;
          final nomeSessao = sessao['nome'] as String? ?? 'Sessão ${i + 1}';
          final exercicios = (sessao['exercicios'] as List?)?.length ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: SpacingTokens.listItemGap),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(nomeSessao, style: CardTokens.cardTitle)),
                Text('$exercicios exercícios', style: AppTheme.caption),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PeriodizacaoSection extends StatelessWidget {
  final String tipoVencimento;
  final TextEditingController sessoesCtrl;
  final DateTime dataVencimento;
  final ValueChanged<String> onTipoChanged;
  final ValueChanged<DateTime> onDataChanged;

  const _PeriodizacaoSection({
    required this.tipoVencimento,
    required this.sessoesCtrl,
    required this.dataVencimento,
    required this.onTipoChanged,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: SpacingTokens.labelToField),
          child: Text('Vencimento', style: AppTheme.sectionHeader),
        ),
        Container(
          padding: CardTokens.padding,
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Row(
                children: [
                  _TabOption(
                    label: 'Sessões',
                    isSelected: tipoVencimento == 'sessoes',
                    onTap: () => onTipoChanged('sessoes'),
                  ),
                  _TabOption(
                    label: 'Data Fixa',
                    isSelected: tipoVencimento == 'data',
                    onTap: () => onTipoChanged('data'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: tipoVencimento == 'sessoes'
                    ? TextFormField(
                        key: const ValueKey('inputSessoes'),
                        controller: sessoesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: rotinaInputDecoration(
                          hintText: 'Quantas sessões?',
                        ).copyWith(fillColor: AppColors.surfaceLight),
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
                          DateFormat(
                            'dd/MM/yyyy',
                            'pt_BR',
                          ).format(dataVencimento),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dataVencimento,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) onDataChanged(picked);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
