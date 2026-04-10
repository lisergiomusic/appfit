import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';

class CadastroAlunoModal extends StatefulWidget {
  final Future<void> Function(
    BuildContext context,
    String nome,
    String sobrenome,
    String email,
    String whatsapp,
    String? genero,
    DateTime? dataNascimento,
  )
  onSalvar;

  const CadastroAlunoModal({super.key, required this.onSalvar});

  @override
  State<CadastroAlunoModal> createState() => _CadastroAlunoModalState();
}

class _CadastroAlunoModalState extends State<CadastroAlunoModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  String? _generoSelecionado;
  DateTime? _dataNascimentoSelecionada;
  bool _tentouCadastrar = false;

  Future<void> _validarECadastrar() async {
    setState(() => _tentouCadastrar = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSalvar(
      context,
      _nomeController.text.trim(),
      _sobrenomeController.text.trim(),
      _emailController.text.trim(),
      _whatsappController.text.trim(),
      _generoSelecionado,
      _dataNascimentoSelecionada,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
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
      child: Form(
        key: _formKey,
        autovalidateMode: _tentouCadastrar
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
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
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.labelSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  fillColor: AppColors.surfaceLight,
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome obrigatorio';
                  }
                  return null;
                },
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
                initialValue: _generoSelecionado,
                items: ['Masculino', 'Feminino', 'Outro']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
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
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  fillColor: AppColors.surfaceLight,
                  labelText: 'E-mail de Acesso',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-mail obrigatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SpacingTokens.listItemGap),
              TextField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                  fillColor: AppColors.surfaceLight,
                  labelText: 'Whatsapp',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              AppPrimaryButton(
                label: 'Cadastrar aluno',
                onPressed: _validarECadastrar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
