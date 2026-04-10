import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'rotina_modern_input.dart';
import 'rotina_input_decoration.dart';
import '../models/rotina_model.dart';

class SessaoTreinoModal extends StatefulWidget {
  final SessaoTreinoModel? sessao;
  final Function(String, String?, String) onSave;

  const SessaoTreinoModal({super.key, this.sessao, required this.onSave});

  @override
  State<SessaoTreinoModal> createState() => _SessaoTreinoModalState();
}

class _SessaoTreinoModalState extends State<SessaoTreinoModal> {
  late TextEditingController sNomeCtrl;
  late TextEditingController orientCtrl;
  String? diaSemana;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    sNomeCtrl = TextEditingController(text: widget.sessao?.nome);
    orientCtrl = TextEditingController(text: widget.sessao?.orientacoes);
    diaSemana = widget.sessao?.diaSemana;
  }

  @override
  void dispose() {
    sNomeCtrl.dispose();
    orientCtrl.dispose();
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sessao != null ? 'Editar Sessão' : 'Nova Sessão',
          style: AppTheme.pageTitle,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSave(
                  sNomeCtrl.text.trim(),
                  diaSemana,
                  orientCtrl.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingScreen),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RotinaModernInput(
                label: 'Nome da sessão',
                child: TextFormField(
                  controller: sNomeCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: rotinaInputDecoration(
                    hintText: 'Ex: Push, Pull...',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              RotinaModernInput(
                label: 'Instruções gerais (Opcional)',
                child: TextFormField(
                  controller: orientCtrl,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: rotinaInputDecoration(
                    hintText: 'Ex: Aquecer manguito antes...',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
