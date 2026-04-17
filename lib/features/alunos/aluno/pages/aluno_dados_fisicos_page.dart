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
    _pesoController.addListener(_onMedidasChanged);
    _alturaController.addListener(_onMedidasChanged);
    _carregarDados();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _objetivosController.dispose();
    super.dispose();
  }

  void _onMedidasChanged() => setState(() {});

  double? get _imc {
    final peso = double.tryParse(_pesoController.text.trim());
    final alturaCm = double.tryParse(_alturaController.text.trim());
    if (peso == null || alturaCm == null || alturaCm == 0) return null;
    final alturaM = alturaCm / 100;
    return peso / (alturaM * alturaM);
  }

  String _classificacaoImc(double imc) {
    if (imc < 18.5) return 'Abaixo do peso';
    if (imc < 25.0) return 'Peso normal';
    if (imc < 30.0) return 'Sobrepeso';
    if (imc < 35.0) return 'Obesidade grau I';
    if (imc < 40.0) return 'Obesidade grau II';
    return 'Obesidade grau III';
  }

  Color _corImc(double imc) {
    if (imc < 18.5) return AppColors.iosBlue;
    if (imc < 25.0) return AppColors.success;
    if (imc < 30.0) return AppColors.accentMetrics;
    return AppColors.systemRed;
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
              // ── Medidas principais ────────────────────────────────
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
              if (_imc != null) ...[
                const SizedBox(height: 12),
                _buildImcCard(_imc!),
              ],
              const SizedBox(height: 20),
              _buildObjetivosField(),

              // ── Medidas corporais (em breve) ──────────────────────
              const SizedBox(height: SpacingTokens.sectionGap + 4),
              _buildEmBreveHeader(),
              const SizedBox(height: SpacingTokens.sm),
              _buildEmBreveGroup([
                _EmBreveField(label: 'Cintura', hint: 'Ex: 80', suffix: 'cm', icon: Icons.radio_button_unchecked_rounded),
                _EmBreveField(label: 'Quadril', hint: 'Ex: 95', suffix: 'cm', icon: Icons.radio_button_unchecked_rounded),
                _EmBreveField(label: 'Peito', hint: 'Ex: 100', suffix: 'cm', icon: Icons.radio_button_unchecked_rounded),
                _EmBreveField(label: 'Braço', hint: 'Ex: 35', suffix: 'cm', icon: Icons.radio_button_unchecked_rounded),
                _EmBreveField(label: 'Coxa', hint: 'Ex: 55', suffix: 'cm', icon: Icons.radio_button_unchecked_rounded),
                _EmBreveField(label: 'Panturrilha', hint: 'Ex: 38', suffix: 'cm', icon: Icons.radio_button_unchecked_rounded),
                _EmBreveField(label: '% Gordura corporal', hint: 'Ex: 18.5', suffix: '%', icon: Icons.percent_rounded),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImcCard(double imc) {
    final classificacao = _classificacaoImc(imc);
    final cor = _corImc(imc);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: cor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, size: 16, color: cor),
          const SizedBox(width: 10),
          Text(
            'IMC  ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
          Text(
            imc.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $classificacao',
            style: TextStyle(
              fontSize: 12,
              color: cor.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmBreveHeader() {
    return Row(
      children: [
        Text('Medidas corporais', style: AppTheme.sectionHeader),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.fillSecondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 10, color: AppColors.labelSecondary),
              const SizedBox(width: 4),
              Text(
                'Em breve',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.labelSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmBreveGroup(List<_EmBreveField> fields) {
    return Column(
      children: fields
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildEmBreveField(f),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmBreveField(_EmBreveField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: AppTheme.formLabel.copyWith(
            color: AppColors.labelSecondary.withAlpha(100),
          ),
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withAlpha(120),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(
                    field.icon,
                    size: 20,
                    color: AppColors.labelSecondary.withAlpha(50),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field.hint,
                      style: AppTheme.inputPlaceHolder.copyWith(
                        color: AppColors.labelSecondary.withAlpha(50),
                      ),
                    ),
                  ),
                  Text(
                    field.suffix,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.labelSecondary.withAlpha(50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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

class _EmBreveField {
  final String label;
  final String hint;
  final String suffix;
  final IconData icon;

  const _EmBreveField({
    required this.label,
    required this.hint,
    required this.suffix,
    required this.icon,
  });
}
