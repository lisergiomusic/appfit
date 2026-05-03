import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

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
  bool _canSave = false;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _telefoneController;
  late final FocusNode _phoneFocusNode;
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
    _nomeController = TextEditingController()..addListener(_onFieldChanged);
    _sobrenomeController = TextEditingController()..addListener(_onFieldChanged);
    _telefoneController = TextEditingController()..addListener(_onFieldChanged);
    _phoneFocusNode = FocusNode()..addListener(() => setState(() {}));
    _carregarDados();
  }

  void _onFieldChanged() {
    final hasChanges = _houveAlteracao();
    if (hasChanges != _canSave) {
      setState(() => _canSave = hasChanges);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _telefoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      var data = await _service
          .getProfile(widget.uid)
          .timeout(const Duration(seconds: 12));
      
      // Fallback: Se não encontrou pelo ID (widget.uid), tenta pelo e-mail do usuário atual
      // Isso resolve casos onde o ID no banco difere do Auth UID (comum em migrações ou cadastros manuais)
      if (data.isEmpty) {
        final currentUser = _service.currentUser;
        if (currentUser != null && currentUser.id == widget.uid && currentUser.email != null) {
          final response = await Supabase.instance.client
              .from('profiles')
              .select()
              .ilike('email', currentUser.email!.trim())
              .maybeSingle();
          
          if (response != null) {
            data = response;
          }
        }
      }
      
      if (data.isEmpty) throw Exception('Dados não encontrados');

      _nomeOriginal = data['nome'] ?? '';
      _sobrenomeOriginal = data['sobrenome'] ?? '';
      _telefoneOriginal = data['telefone'] ?? '';
      _emailAtual = data['email'] ?? '';

      _nomeController.text = _nomeOriginal;
      _sobrenomeController.text = _sobrenomeOriginal;
      _telefoneController.text = _telefoneOriginal;

      final rawDataNascimento = data['data_nascimento'] ?? data['dataNascimento'];
      if (rawDataNascimento != null) {
        _dataNascimentoOriginal = DateTime.tryParse(rawDataNascimento.toString());
        _dataNascimento = _dataNascimentoOriginal;
      }
      if (data['genero'] != null && _generos.contains(data['genero'])) {
        _generoOriginal = data['genero'];
        _generoSelecionado = _generoOriginal;
      }

      setState(() {
        _isLoading = false;
        _canSave = false;
      });
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
    HapticFeedback.lightImpact();
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
            onPressed: _canSave ? _salvar : null,
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
              _buildPhoneField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WhatsApp / contato', style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        IntlPhoneField(
          controller: _telefoneController,
          focusNode: _phoneFocusNode,
          initialCountryCode: 'BR',
          dropdownTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          showDropdownIcon: false,
          flagsButtonPadding: const EdgeInsets.only(left: 12, right: 8),
          textAlignVertical: TextAlignVertical.center,
          style: AppTheme.inputText,
          pickerDialogStyle: PickerDialogStyle(
            backgroundColor: AppColors.surfaceDark,
            countryCodeStyle: const TextStyle(color: Colors.white),
            countryNameStyle: const TextStyle(color: Colors.white),
            searchFieldInputDecoration: InputDecoration(
              hintText: 'Buscar país',
              hintStyle: AppTheme.inputPlaceHolder,
              prefixIcon: const Icon(Icons.search, color: AppColors.labelSecondary),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          decoration: InputDecoration(
            counterText: _phoneFocusNode.hasFocus ? null : "",
            hintText: '00 00000-0000',
            hintStyle: AppTheme.inputPlaceHolder,
            filled: true,
            fillColor: AppColors.surfaceDark,
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 1,
              height: 24,
              color: Colors.white.withAlpha(30),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              maxHeight: 24,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
          languageCode: "pt",
          onChanged: (phone) {
            // No AlunoEditarPerfilPage, usamos setState nos builds para detectar mudanças
          },
          invalidNumberMessage: 'Número inválido',
        ),
      ],
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
            if (picked != null) {
              setState(() {
                _dataNascimento = picked;
                _onFieldChanged();
              });
            }
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
          onChanged: (value) {
            setState(() {
              _generoSelecionado = value;
              _onFieldChanged();
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