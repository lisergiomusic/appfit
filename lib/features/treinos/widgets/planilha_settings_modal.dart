import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import 'rotina_modern_input.dart';
import 'rotina_input_decoration.dart';
import '../../../core/widgets/app_bar_text_button.dart';

class PlanilhaSettingsModal extends StatefulWidget {
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

  const PlanilhaSettingsModal({
    super.key,
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
  State<PlanilhaSettingsModal> createState() => _PlanilhaSettingsModalState();
}

class _PlanilhaSettingsModalState extends State<PlanilhaSettingsModal> {
  late TextEditingController localNomeCtrl;
  late TextEditingController localObjCtrl;
  late FocusNode nomeFocus;
  late FocusNode objFocus;
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
          icon: const Icon(Icons.close, color: AppColors.primary),
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
                      content: Text('Informe uma quantidade válida de sessões.'),
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
                child: DropdownButtonFormField<String>(
                  initialValue: _objetivos.contains(localObjCtrl.text)
                      ? localObjCtrl.text
                      : null,
                  dropdownColor: AppColors.surfaceDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.labelSecondary,
                  ),
                  style: const TextStyle(
                    color: AppColors.labelPrimary,
                    fontSize: 15,
                  ),
                  decoration: rotinaInputDecoration(
                    hintText: 'Selecione o objetivo',
                  ),
                  items: _objetivos.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        localObjCtrl.text = newValue;
                      });
                    }
                  },
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
