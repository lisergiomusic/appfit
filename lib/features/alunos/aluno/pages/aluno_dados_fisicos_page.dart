import 'package:flutter/material.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_divider.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';

class AlunoDadosFisicosPage extends StatefulWidget {
  final String uid;

  const AlunoDadosFisicosPage({super.key, required this.uid});

  @override
  State<AlunoDadosFisicosPage> createState() => _AlunoDadosFisicosPageState();
}

class _AlunoDadosFisicosPageState extends State<AlunoDadosFisicosPage> {
  late final AlunoService _service;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _pesoController;
  late TextEditingController _alturaController;
  late TextEditingController _objetivosController;

  // campos read-only necessários para atualizarAluno
  String _nomeAtual = '';
  String _sobrenomeAtual = '';
  String _emailAtual = '';

  double? _pesoOriginal;

  @override
  void initState() {
    super.initState();
    _service = AlunoService();
    _pesoController = TextEditingController();
    _alturaController = TextEditingController();
    _objetivosController = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _objetivosController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final doc = await _service
          .getAluno(widget.uid)
          .timeout(const Duration(seconds: 12));
      if (!doc.exists) throw Exception('Dados não encontrados');

      final data = doc.data() as Map<String, dynamic>;

      _nomeAtual = data['nome'] ?? '';
      _sobrenomeAtual = data['sobrenome'] ?? '';
      _emailAtual = data['email'] ?? '';

      final peso = data['pesoAtual'];
      if (peso != null) {
        _pesoOriginal = (peso as num).toDouble();
        _pesoController.text = _pesoOriginal!.toStringAsFixed(
          _pesoOriginal! % 1 == 0 ? 0 : 1,
        );
      }

      final altura = data['alturaAtual'];
      if (altura != null) {
        _alturaController.text = (altura as num).toInt().toString();
      }

      _objetivosController.text = data['objetivos'] ?? '';

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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final novoPeso = double.tryParse(_pesoController.text.trim());
      final novaAltura = double.tryParse(_alturaController.text.trim());

      // registra no histórico de peso somente se o valor mudou
      if (novoPeso != null && novoPeso != _pesoOriginal) {
        await _service.registrarPeso(alunoId: widget.uid, peso: novoPeso);
      }

      await _service
          .atualizarAluno(
            alunoId: widget.uid,
            nome: _nomeAtual,
            sobrenome: _sobrenomeAtual,
            email: _emailAtual,
            peso: novoPeso,
            altura: novaAltura,
            objetivos: _objetivosController.text.trim(),
          )
          .timeout(const Duration(seconds: 12));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados físicos atualizados!'),
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
      title: const Text('Dados físicos'),
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
                controller: _pesoController,
                label: 'Peso',
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Ex: 75.5',
                suffix: 'kg',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _alturaController,
                label: 'Altura',
                icon: Icons.straighten_rounded,
                keyboardType: TextInputType.number,
                hint: 'Ex: 175',
                suffix: 'cm',
              ),
              const SizedBox(height: 20),
              _buildObjetivosField(),
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
    String? hint,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      suffix,
                      style: const TextStyle(
                        color: AppColors.labelSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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

  Widget _buildObjetivosField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Objetivo', style: AppTheme.formLabel),
        const SizedBox(height: SpacingTokens.labelToField),
        TextFormField(
          controller: _objetivosController,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: AppTheme.inputText,
          decoration: InputDecoration(
            hintText: 'Ex: Perder peso, ganhar massa muscular...',
            hintStyle: AppTheme.inputPlaceHolder,
            filled: true,
            fillColor: AppColors.surfaceDark,
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
        ),
      ],
    );
  }
}
