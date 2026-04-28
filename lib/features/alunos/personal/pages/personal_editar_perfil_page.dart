import 'package:flutter/material.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

class PersonalEditarPerfilPage extends StatefulWidget {
  final String uid;

  const PersonalEditarPerfilPage({super.key, required this.uid});

  @override
  State<PersonalEditarPerfilPage> createState() => _PersonalEditarPerfilPageState();
}

class _PersonalEditarPerfilPageState extends State<PersonalEditarPerfilPage> {
  late final UserService _service;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _canSave = false;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _especialidadeController;
  late TextEditingController _telefoneController;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _especialidadeFocusNode;

  String _emailAtual = '';

  // valores originais para detectar alterações
  String _nomeOriginal = '';
  String _sobrenomeOriginal = '';
  String _especialidadeOriginal = '';
  String _telefoneOriginal = '';

  @override
  void initState() {
    super.initState();
    _service = UserService();
    _nomeController = TextEditingController()..addListener(_onFieldChanged);
    _sobrenomeController = TextEditingController()..addListener(_onFieldChanged);
    _especialidadeController = TextEditingController()..addListener(_onFieldChanged);
    _telefoneController = TextEditingController()..addListener(_onFieldChanged);
    _phoneFocusNode = FocusNode()..addListener(() => setState(() {}));
    _especialidadeFocusNode = FocusNode()..addListener(() => setState(() {}));
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
    _especialidadeController.dispose();
    _telefoneController.dispose();
    _phoneFocusNode.dispose();
    _especialidadeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final data = await _service
          .getProfile(widget.uid) // getProfile na verdade pega da tabela profiles, serve para personal também
          .timeout(const Duration(seconds: 12));
      
      if (data.isEmpty) throw Exception('Dados não encontrados');

      _nomeOriginal = data['nome'] ?? '';
      _sobrenomeOriginal = data['sobrenome'] ?? '';
      _especialidadeOriginal = data['especialidade'] ?? '';
      _telefoneOriginal = data['telefone'] ?? '';
      _emailAtual = data['email'] ?? '';

      _nomeController.text = _nomeOriginal;
      _sobrenomeController.text = _sobrenomeOriginal;
      _especialidadeController.text = _especialidadeOriginal;
      _telefoneController.text = _telefoneOriginal;

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
    if (_isLoading) return false;

    String norm(String? v) => (v ?? '').trim();

    final nomeMudou = norm(_nomeController.text) != norm(_nomeOriginal);
    final sobrenomeMudou = norm(_sobrenomeController.text) != norm(_sobrenomeOriginal);
    final especialidadeMudou = norm(_especialidadeController.text) != norm(_especialidadeOriginal);
    final telefoneMudou = norm(_telefoneController.text) != norm(_telefoneOriginal);

    return nomeMudou || sobrenomeMudou || especialidadeMudou || telefoneMudou;
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
          .updatePersonalProfile(
            uid: widget.uid,
            nome: _nomeController.text.trim(),
            sobrenome: _sobrenomeController.text.trim(),
            email: _emailAtual,
            especialidade: _especialidadeController.text.trim(),
            telefone: _telefoneController.text.trim(),
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
        // Não salvamos automaticamente no pop para evitar saves indesejados se o usuário apenas quiser sair
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
        onPressed: () {
          if (_isSaving) return;
          Navigator.pop(context);
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
              _buildTextField(
                controller: _especialidadeController,
                focusNode: _especialidadeFocusNode,
                label: 'Especialidade / Bio curta',
                icon: Icons.workspace_premium_rounded,
                textCapitalization: TextCapitalization.sentences,
                hint: 'Ex: Especialista em Hipertrofia',
                maxLength: 120,
                maxLines: 3,
                minLines: 1,
                validator: (v) => v!.trim().isEmpty ? 'A especialidade é obrigatória' : null,
              ),
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
            // O listener de _telefoneController já dispara _onFieldChanged
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
    void Function(String)? onChanged,
    FocusNode? focusNode,
    int? maxLength,
    int? maxLines = 1,
    int? minLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.formLabel),
            if (focusNode != null && focusNode.hasFocus)
              GestureDetector(
                onTap: () => focusNode.unfocus(),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Concluir',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          style: AppTheme.inputText,
          decoration: InputDecoration(
            counterText: focusNode != null
                ? (focusNode.hasFocus ? null : "")
                : (maxLength != null ? "" : null),
            hintText: hint,
            hintStyle: AppTheme.inputPlaceHolder,
            prefixIcon: Container(
              margin: EdgeInsets.only(
                bottom: (maxLines ?? 1) > 1 ? 44 : 0, // Compensa a altura extra das linhas
              ),
              child: Icon(
                icon,
                color: AppColors.labelSecondary.withAlpha(120),
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.surfaceDark,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              maxHeight: 24,
            ),
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
}