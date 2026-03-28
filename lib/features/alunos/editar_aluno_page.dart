import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/aluno_service.dart';

class EditarAlunoPage extends StatefulWidget {
  final String alunoId;

  const EditarAlunoPage({
    super.key,
    required this.alunoId,
  });

  @override
  State<EditarAlunoPage> createState() => _EditarAlunoPageState();
}

class _EditarAlunoPageState extends State<EditarAlunoPage> {
  final AlunoService _alunoService = AlunoService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _pesoController;
  DateTime? _dataNascimento;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final doc = await _alunoService.getAluno(widget.alunoId);
      if (!doc.exists) throw Exception("Aluno não encontrado");

      final data = doc.data() as Map<String, dynamic>;

      _nomeController = TextEditingController(text: data['nome'] ?? '');
      _sobrenomeController = TextEditingController(text: data['sobrenome'] ?? '');
      _emailController = TextEditingController(text: data['email'] ?? '');
      _telefoneController = TextEditingController(text: data['telefone'] ?? '');
      _pesoController = TextEditingController(text: data['pesoAtual']?.toString() ?? '');

      if (data['dataNascimento'] != null) {
        _dataNascimento = (data['dataNascimento'] as Timestamp).toDate();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
        Navigator.pop(context);
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
      await _alunoService.atualizarAluno(
        alunoId: widget.alunoId,
        nome: _nomeController.text.trim(),
        sobrenome: _sobrenomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim(),
        peso: double.tryParse(_pesoController.text),
        dataNascimento: _dataNascimento,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Editar Aluno',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _salvar,
              child: Text(
                'Salvar',
                style: TextStyle(
                  color: _isSaving ? AppTheme.textSecondary : AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
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
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Informações básicas'),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nomeController,
                label: 'Nome',
                icon: Icons.person_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'O nome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _sobrenomeController,
                label: 'Sobrenome',
                icon: Icons.badge_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'O sobrenome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail de acesso',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'O e-mail é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _telefoneController,
                label: 'WhatsApp / contato',
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                hint: '(00) 00000-0000',
              ),

              const SizedBox(height: 40),
              _buildSectionHeader('Biometria e saúde'),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pesoController,
                      label: 'Peso atual',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffix: const Text('kg', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(),
                  ),
                ],
              ),

              const SizedBox(height: 56),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
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
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textSecondary.withAlpha(80), fontSize: 14),
            prefixIcon: Icon(icon, color: AppTheme.textSecondary.withAlpha(120), size: 20),
            suffixIcon: suffix != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [suffix],
                  )
                : null,
            filled: true,
            fillColor: AppTheme.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.redAccent.withAlpha(100), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Nascimento',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
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
                      primary: AppTheme.primary,
                      onPrimary: Colors.black,
                      surface: AppTheme.surfaceDark,
                      onSurface: Colors.white,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary.withAlpha(120), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dataNascimento != null
                        ? DateFormat('dd/MM/yyyy').format(_dataNascimento!)
                        : 'Selecionar',
                    style: TextStyle(
                      color: _dataNascimento != null ? Colors.white : AppTheme.textSecondary.withAlpha(80),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _salvar,
      child: _isSaving
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
          )
        : const Text(
            'Atualizar Perfil',
          ),
    );
  }
}