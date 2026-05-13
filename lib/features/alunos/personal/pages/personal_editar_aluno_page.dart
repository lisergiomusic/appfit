import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/personal_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';
import '../../../../core/widgets/app_tappable.dart';

/// Página de edição cadastral do aluno com estética Neo-Industrial Form.
/// Centraliza os campos em um console de vidro único para uma experiência focada e premium.
class PersonalEditarAlunoPage extends StatefulWidget {
  final String alunoId;
  final PersonalService? personalService;
  final UserService? userService;

  const PersonalEditarAlunoPage({
    super.key,
    required this.alunoId,
    this.personalService,
    this.userService,
  });

  @override
  State<PersonalEditarAlunoPage> createState() =>
      _PersonalEditarAlunoPageState();
}

class _PersonalEditarAlunoPageState extends State<PersonalEditarAlunoPage> {
  late final PersonalService _personalService;
  late final UserService _userService;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _canSave = false;
  Map<String, dynamic>? _dadosIniciais;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _pesoController;
  DateTime? _dataNascimento;

  String? _generoSelecionado;
  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];
  final String _generoPlaceholder = 'SELECIONE O GÊNERO';

  @override
  void initState() {
    super.initState();
    _personalService = widget.personalService ?? PersonalService();
    _userService = widget.userService ?? UserService();
    _nomeController = TextEditingController()..addListener(_onFieldChanged);
    _sobrenomeController = TextEditingController()..addListener(_onFieldChanged);
    _emailController = TextEditingController()..addListener(_onFieldChanged);
    _telefoneController = TextEditingController()..addListener(_onFieldChanged);
    _pesoController = TextEditingController()..addListener(_onFieldChanged);
    _carregarDados();
  }

  /// Monitora mudanças nos campos para habilitar/desabilitar o botão salvar.
  void _onFieldChanged() {
    final hasChanges = _temAlteracoes();
    if (hasChanges != _canSave) {
      setState(() => _canSave = hasChanges);
    }
  }

  /// Recupera os dados atuais do aluno para popular o formulário.
  Future<void> _carregarDados() async {
    try {
      final data = await _userService
          .getProfile(widget.alunoId)
          .timeout(const Duration(seconds: 12));

      if (data.isEmpty) throw Exception("Aluno não encontrado");

      _nomeController.text = data['nome'] ?? '';
      _sobrenomeController.text = data['sobrenome'] ?? '';
      _emailController.text = data['email'] ?? '';
      _telefoneController.text = data['telefone'] ?? '';
      _pesoController.text = (data['peso_atual'] ?? data['pesoAtual'])?.toString() ?? '';

      final rawDataNascimento = data['data_nascimento'] ?? data['dataNascimento'];
      if (rawDataNascimento != null) {
        _dataNascimento = DateTime.tryParse(rawDataNascimento.toString());
      }

      if (data['genero'] != null && _generos.contains(data['genero'])) {
        _generoSelecionado = data['genero'];
      }

      _dadosIniciais = Map.from(data);
      setState(() {
        _isLoading = false;
        _canSave = false;
      });
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

  /// Verifica se houve qualquer alteração em relação aos dados originais.
  bool _temAlteracoes() {
    if (_isLoading || _dadosIniciais == null) return false;

    String norm(dynamic v) => (v?.toString() ?? '').trim();

    final nomeMudou = norm(_nomeController.text) != norm(_dadosIniciais!['nome']);
    final sobrenomeMudou = norm(_sobrenomeController.text) != norm(_dadosIniciais!['sobrenome']);
    final emailMudou = norm(_emailController.text) != norm(_dadosIniciais!['email']);
    final telefoneMudou = norm(_telefoneController.text) != norm(_dadosIniciais!['telefone']);

    final pesoIni = double.tryParse(norm(_dadosIniciais!['peso_atual'] ?? _dadosIniciais!['pesoAtual'])) ?? 0.0;
    final pesoAtu = double.tryParse(_pesoController.text.replaceAll(',', '.')) ?? 0.0;
    final pesoMudou = (pesoIni - pesoAtu).abs() > 0.01;

    final dIniRaw = _dadosIniciais!['data_nascimento'] ?? _dadosIniciais!['dataNascimento'];
    final dIni = dIniRaw != null ? DateTime.tryParse(dIniRaw.toString()) : null;
    final dataMudou = dIni?.millisecondsSinceEpoch != _dataNascimento?.millisecondsSinceEpoch;

    final gIni = norm(_dadosIniciais!['genero']);
    final gAtu = norm(_generoSelecionado);
    final generoMudou = gAtu != gIni && (gAtu.isNotEmpty || gIni.isNotEmpty);

    return nomeMudou || sobrenomeMudou || emailMudou || telefoneMudou || pesoMudou || dataMudou || generoMudou;
  }

  /// Persiste as alterações no backend.
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_temAlteracoes()) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _personalService
          .atualizarDadosAluno(
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
            backgroundColor: AppColors.primary,
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
    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSaving) return;
        await _salvar();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Atmosfera Superior
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: SpacingTokens.atmosphereHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: GlassTokens.opacityAtmosphere),
                      AppColors.primary.withValues(alpha: GlassTokens.opacityAtmosphereSubtle),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _buildBody(),

            // Header Customizado (Substituindo AppBar para garantir transparência real sobre a Stack)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Título Centralizado Absoluto
                            Text(
                              'Editar Aluno',
                              textAlign: TextAlign.center,
                              style: AppTheme.pageTitle,
                            ),
                            // Ações Laterais
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppNavBackButton(
                                  onPressed: () async {
                                    if (_isSaving) return;
                                    await _salvar();
                                  },
                                ),
                                AppBarTextButton(
                                  label: 'Salvar',
                                  isLoading: _isSaving,
                                  onPressed: _canSave ? _salvar : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o corpo da página com o Glass Form Console.
  Widget _buildBody() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: true,
            child: Container(
              margin: EdgeInsets.fromLTRB(
                GlassTokens.consoleMarginH,
                SpacingTokens.xxxl + MediaQuery.of(context).padding.top + 56, // Compensação do Header customizado
                GlassTokens.consoleMarginH,
                0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(GlassTokens.consoleRadius),
                  topRight: Radius.circular(GlassTokens.consoleRadius),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('DADOS IDENTIFICADORES'),
                    _buildTextField(
                      controller: _nomeController,
                      label: 'NOME',
                      icon: CupertinoIcons.person,
                      textCapitalization: TextCapitalization.words,
                      hint: 'EX: JOÃO',
                      validator: (v) => v!.isEmpty ? 'O nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _sobrenomeController,
                      label: 'SOBRENOME',
                      icon: CupertinoIcons.person_2,
                      textCapitalization: TextCapitalization.words,
                      hint: 'EX: SILVA',
                      validator: (v) => v!.isEmpty ? 'O sobrenome é obrigatório' : null,
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader('BIOMETRIA E PERFIL'),
                    _buildDatePicker(),
                    const SizedBox(height: 24),
                    _buildGeneroDropdown(),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _pesoController,
                      label: 'PESO ATUAL',
                      icon: CupertinoIcons.gauge,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hint: 'EX: 75.5',
                      suffix: Text(
                        'KG',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader('CONTATO E ACESSO'),
                    _buildTextField(
                      controller: _emailController,
                      label: 'E-MAIL DE ACESSO',
                      icon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      hint: 'EXEMPLO@EMAIL.COM',
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _telefoneController,
                      label: 'WHATSAPP / CONTATO',
                      icon: CupertinoIcons.phone,
                      keyboardType: TextInputType.phone,
                      hint: '(00) 00000-0000',
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um cabeçalho de seção técnica.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Text(
        title,
        style: AppTheme.sectionHeader.copyWith(
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Constrói um campo de texto "In-Glass" com tipografia técnica.
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
        Text(label, style: AppTheme.technicalLabel.copyWith(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 13),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.2),
              size: 18,
            ),
            suffixIcon: suffix != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [suffix],
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói o seletor de gênero com estilo "In-Glass".
  Widget _buildGeneroDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GÊNERO', style: AppTheme.technicalLabel.copyWith(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              _generoSelecionado?.isNotEmpty == true &&
                  _generos.contains(_generoSelecionado)
              ? _generoSelecionado
              : null,
          hint: Text(_generoPlaceholder, style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 13)),
          items: [
            ..._generos.map((g) => DropdownMenuItem(
              value: g,
              child: Text(g.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
            )),
          ],
          onChanged: (value) {
            setState(() {
              _generoSelecionado = value;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            prefixIcon: Icon(
              CupertinoIcons.person_2,
              color: Colors.white.withValues(alpha: 0.2),
              size: 18,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          dropdownColor: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
        ),
      ],
    );
  }

  /// Constrói o seletor de data de nascimento com estilo "In-Glass".
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NASCIMENTO', style: AppTheme.technicalLabel.copyWith(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 10),
        AppTappable(
          onPressed: () async {
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
                      surface: Color(0xFF1A1A1A),
                      onSurface: Colors.white,
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dataNascimento != null
                        ? DateFormat('dd/MM/yyyy').format(_dataNascimento!)
                        : 'SELECIONAR DATA',
                    style: TextStyle(
                      color: _dataNascimento != null ? Colors.white : Colors.white.withValues(alpha: 0.15),
                      fontSize: 14,
                      fontWeight: _dataNascimento != null ? FontWeight.w500 : FontWeight.normal,
                    ),
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