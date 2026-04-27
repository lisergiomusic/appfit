import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/widgets/app_bar_divider.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';

class PersonalEditarAlunoPage extends StatefulWidget {
  final String alunoId;
  final AlunoService? alunoService;

  const PersonalEditarAlunoPage({
    super.key,
    required this.alunoId,
    this.alunoService,
  });

  @override
  State<PersonalEditarAlunoPage> createState() =>
      _PersonalEditarAlunoPageState();
}

class _PersonalEditarAlunoPageState extends State<PersonalEditarAlunoPage> {
  late final AlunoService _alunoService;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _pesoController;
  DateTime? _dataNascimento;

  String? _generoSelecionado;
  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];
  final String _generoPlaceholder = 'Selecione o gênero';

  @override
  void initState() {
    super.initState();
    _alunoService = widget.alunoService ?? AlunoService();
    _nomeController = TextEditingController();
    _sobrenomeController = TextEditingController();
    _emailController = TextEditingController();
    _telefoneController = TextEditingController();
    _pesoController = TextEditingController();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final data = await _alunoService
          .getAluno(widget.alunoId)
          .timeout(const Duration(seconds: 12));
      
      if (data.isEmpty) throw Exception("Aluno não encontrado");

      _nomeController.text = data['nome'] ?? '';
      _sobrenomeController.text = data['sobrenome'] ?? '';
      _emailController.text = data['email'] ?? '';
      _telefoneController.text = data['telefone'] ?? '';
      _pesoController.text = data['pesoAtual']?.toString() ?? '';

      if (data['dataNascimento'] != null) {
        _dataNascimento = DateTime.tryParse(data['dataNascimento'].toString());
      }

      if (data['genero'] != null && _generos.contains(data['genero'])) {
        _generoSelecionado = data['genero'];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _alunoService
          .atualizarAluno(
            alunoId: widget.alunoId,
            nome: _nomeController.text.trim(),
            sobrenome: _sobrenomeController.text.trim(),
            email: _emailController.text.trim(),
            telefone: _telefoneController.text.trim(),
            peso: double.tryParse(_pesoController.text),
            dataNascimento: _dataNascimento,
            genero: _generoSelecionado,
          )
          .timeout(const Duration(seconds: 12));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSaving) return;
        await _salvar();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: AppNavBackButton(
        onPressed: () async {
          if (_isSaving) return;
          await _salvar();
        },
      ),
      title: const Text('Editar Aluno'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AppBarTextButton(
            label: 'Salvar',
            isLoading: _isSaving,
            onPressed: _salvar,
          ),
        ),
      ],
      bottom: const AppBarDivider(),
    );
  }

  Widget _buildBody() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.screenHorizontalPadding,
          SpacingTokens.screenTopPadding,
          SpacingTokens.screenHorizontalPadding,
          SpacingTokens.screenBottomPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nomeController,
                label: 'Nome',
                icon: Icons.person_rounded,
                textCapitalization: TextCapitalization.words,
                hint: 'Ex: João',
                validator: (v) => v!.isEmpty ? 'O nome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _sobrenomeController,
                label: 'Sobrenome',
                icon: Icons.badge_rounded,
                textCapitalization: TextCapitalization.words,
                hint: 'Ex: Silva',
                validator: (v) =>
                    v!.isEmpty ? 'O sobrenome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 20),
              _buildGeneroDropdown(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _pesoController,
                label: 'Peso',
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                hint: 'Ex: 75.5',
                suffix: const Text(
                  'kg',
                  style: TextStyle(
                    color: AppColors.labelSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail de acesso',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                hint: 'exemplo@email.com',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _telefoneController,
                label: 'Whatsapp / contato',
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                hint: '(00) 00000-0000',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    String? hint,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: AppTheme.inputText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.inputPlaceHolder,
            prefixIcon: Icon(
              icon,
              color: AppColors.labelSecondary.withAlpha(120),
              size: 20,
            ),
            suffixIcon: suffix != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [suffix],
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: BorderSide(
                color: Colors.redAccent.withAlpha(100),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneroDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gênero', style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              _generoSelecionado?.isNotEmpty == true &&
                  _generos.contains(_generoSelecionado)
              ? _generoSelecionado
              : null,
          hint: Text(_generoPlaceholder, style: AppTheme.inputPlaceHolder),
          items: [
            DropdownMenuItem<String>(
              value: null,
              enabled: false,
              child: Text(_generoPlaceholder, style: AppTheme.inputPlaceHolder),
            ),
            ..._generos.map((g) => DropdownMenuItem(value: g, child: Text(g))),
          ],
          onChanged: (value) {
            setState(() {
              _generoSelecionado = value;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceDark,
            prefixIcon: Icon(
              Icons.wc_rounded,
              color: AppColors.labelSecondary.withAlpha(120),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: BorderSide.none,
            ),
          ),
          style: AppTheme.inputText,
          dropdownColor: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nascimento', style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dataNascimento ?? DateTime(2000),
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: Colors.black,
                      surface: AppColors.surfaceDark,
                      onSurface: Colors.white,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _dataNascimento = picked);
            }
          },
          splashColor: AppColors.splash,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.labelSecondary.withAlpha(120),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dataNascimento != null
                        ? DateFormat('dd/MM/yyyy').format(_dataNascimento!)
                        : 'Selecionar',
                    style: _dataNascimento != null
                        ? AppTheme.inputText
                        : AppTheme.inputPlaceHolder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}