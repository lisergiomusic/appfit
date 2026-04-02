import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CadastroAlunoModal extends StatefulWidget {
  final Future<void> Function(
    BuildContext context,
    String nome,
    String sobrenome,
    String email,
    String? genero,
    DateTime? dataNascimento,
  )
  onSalvar;

  const CadastroAlunoModal({super.key, required this.onSalvar});

  @override
  State<CadastroAlunoModal> createState() => _CadastroAlunoModalState();
}

class _CadastroAlunoModalState extends State<CadastroAlunoModal> {
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  String? _generoSelecionado;
  DateTime? _dataNascimentoSelecionada;

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _emailController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final now = DateTime.now();
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimentoSelecionada ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataNascimentoSelecionada = dataSelecionada;
        _dataNascimentoController.text =
            '${dataSelecionada.day.toString().padLeft(2, '0')}/'
            '${dataSelecionada.month.toString().padLeft(2, '0')}/'
            '${dataSelecionada.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Novo Aluno',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Preencha os dados do aluno abaixo',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.labelSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.labelSecondary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              fillColor: AppColors.surfaceLight,
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: SpacingTokens.listItemGap),
          TextField(
            controller: _sobrenomeController,
            decoration: const InputDecoration(
              fillColor: AppColors.surfaceLight,
              labelText: 'Sobrenome',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: SpacingTokens.listItemGap),
          DropdownButtonFormField<String>(
            dropdownColor: AppColors.surfaceDark,
            items: [
              'Masculino',
              'Feminino',
              'Outro',
            ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (val) => setState(() => _generoSelecionado = val),
            decoration: const InputDecoration(
              labelText: 'Gênero',
              fillColor: AppColors.surfaceLight,
              prefixIcon: Icon(Icons.people_outline),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: SpacingTokens.listItemGap),
          TextField(
            controller: _dataNascimentoController,
            readOnly: true,
            decoration: const InputDecoration(
              fillColor: AppColors.surfaceLight,
              labelText: 'Data de Nascimento',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: _selecionarData,
          ),
          const SizedBox(height: SpacingTokens.listItemGap),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              fillColor: AppColors.surfaceLight,
              labelText: 'E-mail de Acesso',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => widget.onSalvar(
                context,
                _nomeController.text,
                _sobrenomeController.text,
                _emailController.text,
                _generoSelecionado,
                _dataNascimentoSelecionada,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'CADASTRAR ALUNO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
