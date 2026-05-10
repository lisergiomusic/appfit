import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_text_button.dart';

class PlanilhaSettingsModal extends StatefulWidget {
  final String? rotinaId;
  final String nomeInicial;
  final String objetivoInicial;
  final String tipoVencimento;
  final int vencimentoSessoes;
  final DateTime vencimentoData;
  final bool hasTreinos;
  final bool isGlobalTemplate;
  final Function(String, String, String, int, DateTime) onSave;
  final VoidCallback onDelete;
  final Future<bool> Function() showDescartarDialog;

  const PlanilhaSettingsModal({
    super.key,
    required this.rotinaId,
    required this.nomeInicial,
    required this.objetivoInicial,
    required this.tipoVencimento,
    required this.vencimentoSessoes,
    required this.vencimentoData,
    required this.hasTreinos,
    this.isGlobalTemplate = false,
    required this.onSave,
    required this.onDelete,
    required this.showDescartarDialog,
  });

  @override
  State<PlanilhaSettingsModal> createState() => _PlanilhaSettingsModalState();
}

class _PlanilhaSettingsModalState extends State<PlanilhaSettingsModal> {
  late TextEditingController localNomeCtrl;
  late TextEditingController localObjCtrl;
  late FocusNode nomeFocus;
  late FocusNode objFocus;
  late FocusNode sessoesFocus;
  late String tipoTemp;
  late String sessoesInput;
  late DateTime dataTemp;
  final _formKey = GlobalKey<FormState>();

  final List<String> _objetivos = [
    'Hipertrofia',
    'Emagrecimento',
    'Condicionamento Físico',
    'Ganho de Força',
    'Resistência Muscular',
    'Definição Muscular',
    'Saúde e Bem-estar',
    'Performance Atleta',
    'Reabilitação',
  ];

  @override
  void initState() {
    super.initState();
    localNomeCtrl = TextEditingController(text: widget.nomeInicial);
    localObjCtrl = TextEditingController(text: widget.objetivoInicial);

    if (widget.objetivoInicial.isNotEmpty &&
        !_objetivos.contains(widget.objetivoInicial)) {
      _objetivos.insert(0, widget.objetivoInicial);
    }

    nomeFocus = FocusNode();
    objFocus = FocusNode();
    sessoesFocus = FocusNode();

    nomeFocus.addListener(() => setState(() {}));
    objFocus.addListener(() => setState(() {}));
    sessoesFocus.addListener(() => setState(() {}));

    tipoTemp = widget.tipoVencimento;
    sessoesInput = widget.rotinaId == null ? '' : widget.vencimentoSessoes.toString();
    dataTemp = widget.vencimentoData;
  }

  @override
  void dispose() {
    localNomeCtrl.dispose();
    localObjCtrl.dispose();
    nomeFocus.dispose();
    objFocus.dispose();
    sessoesFocus.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      final sessoes = int.tryParse(sessoesInput) ?? 0;
      widget.onSave(
        localNomeCtrl.text.trim(),
        localObjCtrl.text.trim(),
        tipoTemp,
        sessoes,
        dataTemp,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: AppColors.labelSecondary, size: 22),
          onPressed: () async {
            if (localNomeCtrl.text.trim().isNotEmpty && localObjCtrl.text.trim().isNotEmpty) {
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
            onPressed: _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('NOME DA PLANILHA'),
              const SizedBox(height: 8),
              _buildFieldContainer(
                isFocused: nomeFocus.hasFocus,
                child: TextFormField(
                  controller: localNomeCtrl,
                  focusNode: nomeFocus,
                  autofocus: widget.nomeInicial.isEmpty,
                  maxLength: 40,
                  style: const TextStyle(
                    color: AppColors.labelPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ex: Protocolo Alpha',
                    hintStyle: TextStyle(color: AppColors.labelTertiary, fontWeight: FontWeight.w400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    counterText: '',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('OBJETIVO PRINCIPAL'),
              const SizedBox(height: 8),
              _buildFieldContainer(
                isFocused: objFocus.hasFocus,
                child: DropdownButtonFormField<String>(
                  value: _objetivos.contains(localObjCtrl.text) ? localObjCtrl.text : null,
                  focusNode: objFocus,
                  dropdownColor: AppColors.surfaceDark,
                  icon: const Icon(CupertinoIcons.chevron_down, color: AppColors.labelSecondary, size: 16),
                  style: const TextStyle(
                    color: AppColors.labelPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Selecione...',
                    hintStyle: TextStyle(color: AppColors.labelTertiary, fontWeight: FontWeight.w400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  items: _objetivos.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => localObjCtrl.text = val);
                  },
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Obrigatório' : null,
                ),
              ),
              if (!widget.isGlobalTemplate) ...[
                const SizedBox(height: 32),
                _buildSectionLabel('VENCIMENTO'),
                const SizedBox(height: 12),
                _buildVencimentoCard(),
              ],
              if (widget.rotinaId != null) ...[
                const SizedBox(height: 48),
                Center(
                  child: _buildDeleteButton(),
                ),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: AppTheme.sectionHeader),
    );
  }

  Widget _buildFieldContainer({required Widget child, required bool isFocused}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? AppColors.primary.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  Widget _buildVencimentoCard() {
    final bool isFocused = sessoesFocus.hasFocus && tipoTemp == 'sessoes';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused ? AppColors.primary.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: tipoTemp == 'sessoes' ? Alignment.centerLeft : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildTab('SESSÕES', tipoTemp == 'sessoes', () => setState(() => tipoTemp = 'sessoes')),
                    _buildTab('DATA FIXA', tipoTemp == 'data', () => setState(() => tipoTemp = 'data')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content Switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: tipoTemp == 'sessoes' ? _buildSessoesInput() : _buildDataInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessoesInput() {
    return Container(
      key: const ValueKey('sessoes_input_container'),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(CupertinoIcons.number, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              focusNode: sessoesFocus,
              keyboardType: TextInputType.number,
              initialValue: sessoesInput,
              style: const TextStyle(
                color: AppColors.labelPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              decoration: const InputDecoration(
                hintText: 'Quantidade...',
                hintStyle: TextStyle(color: AppColors.labelTertiary, fontSize: 14, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) => sessoesInput = v,
            ),
          ),
          Text(
            'TREINOS',
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataInput() {
    return Container(
      key: const ValueKey('data_input_container'),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final picked = await showDatePicker(
            context: context,
            initialDate: dataTemp,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) setState(() => dataTemp = picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(CupertinoIcons.calendar, color: AppColors.primary, size: 18),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd/MM/yyyy').format(dataTemp),
                style: const TextStyle(
                  color: AppColors.labelPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.labelTertiary.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            HapticFeedback.selectionClick();
            onTap();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.labelPrimary : AppColors.labelSecondary,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onDelete();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              'REMOVER PLANILHA',
              style: AppTheme.sectionHeader.copyWith(color: Colors.redAccent, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
