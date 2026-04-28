import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';

class AlunoEditarPerfilPage extends StatefulWidget {
  final String uid;

  const AlunoEditarPerfilPage({super.key, required this.uid});

  @override
  State<AlunoEditarPerfilPage> createState() => _AlunoEditarPerfilPageState();
}

class _AlunoEditarPerfilPageState extends State<AlunoEditarPerfilPage> {
  late final UserService _service;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _telefoneController;
  DateTime? _dataNascimento;
  String? _generoSelecionado;

  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];

  String _emailAtual = '';

  // valores originais para detectar alterações
  String _nomeOriginal = '';
  String _sobrenomeOriginal = '';
  String _telefoneOriginal = '';
  DateTime? _dataNascimentoOriginal;
  String? _generoOriginal;

  @override
  void initState() {
    super.initState();
    _service = UserService();
    _nomeController = TextEditingController();
    _sobrenomeController = TextEditingController();
    _telefoneController = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final data = await _service
          .getProfile(widget.uid)
          .timeout(const Duration(seconds: 12));
      
      if (data.isEmpty) throw Exception('Dados não encontrados');

      _nomeOriginal = data['nome'] ?? '';
      _sobrenomeOriginal = data['sobrenome'] ?? '';
      _telefoneOriginal = data['telefone'] ?? '';
      _emailAtual = data['email'] ?? '';

      _nomeController.text = _nomeOriginal;
      _sobrenomeController.text = _sobrenomeOriginal;
      _telefoneController.text = _telefoneOriginal;

      if (data['dataNascimento'] != null) {
        _dataNascimentoOriginal = DateTime.tryParse(data['dataNascimento'].toString());
        _dataNascimento = _dataNascimentoOriginal;
      }
      if (data['genero'] != null && _generos.contains(data['genero'])) {
        _generoOriginal = data['genero'];
        _generoSelecionado = _generoOriginal;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  bool _houveAlteracao() {
    if (_nomeController.text.trim() != _nomeOriginal) return true;
    if (_sobrenomeController.text.trim() != _sobrenomeOriginal) return true;
    if (_telefoneController.text.trim() != _telefoneOriginal) return true;
    if (_generoSelecionado != _generoOriginal) return true;
    final dataDifere = _dataNascimento?.toIso8601String() !=
        _dataNascimentoOriginal?.toIso8601String();
    if (dataDifere) return true;
    return false;
  }

  Future<void> _salvar() async {
    if (!_houveAlteracao()) {
      Navigator.pop(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _service
          .updateProfile(
            uid: widget.uid,
            data: {
              'nome': _nomeController.text.trim(),
              'sobrenome': _sobrenomeController.text.trim(),
              'email': _emailAtual,
              'telefone': _telefoneController.text.trim(),
              'data_nascimento': _dataNascimento?.toIso8601String(),
              'genero': _generoSelecionado,
            },
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving) return;
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
      title: const Text('Editar perfil'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AppBarTextButton(
            label: 'Salvar',
            isLoading: _isSaving,
            onPressed: _salvar,
          ),
        ),
      ],
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
                validator: (v) => v!.trim().isEmpty ? 'O nome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _sobrenomeController,
                label: 'Sobrenome',
                icon: Icons.badge_rounded,
                textCapitalization: TextCapitalization.words,
                hint: 'Ex: Silva',
                validator: (v) => v!.trim().isEmpty ? 'O sobrenome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 20),
              _buildGeneroDropdown(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _telefoneController,
                label: 'WhatsApp / contato',
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data de nascimento', style: AppTheme.formLabel),
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
            if (picked != null) setState(() => _dataNascimento = picked);
          },
          splashColor: AppColors.splash,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataNascimento!)
                        : 'Selecionar',
                    style: _dataNascimento != null
                        ? AppTheme.inputText
                        : AppTheme.inputPlaceHolder,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.labelSecondary.withAlpha(80),
                  size: 18,
                ),
              ],
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
          initialValue: _generoSelecionado,
          hint: Text('Selecione o gênero', style: AppTheme.inputPlaceHolder),
          items: _generos
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (value) => setState(() => _generoSelecionado = value),
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
          ),
          style: AppTheme.inputText,
          dropdownColor: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ],
    );
  }
}