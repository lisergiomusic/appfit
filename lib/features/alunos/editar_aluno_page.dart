import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/aluno_service.dart';
import '../../core/widgets/app_bar_divider.dart';

class EditarAlunoPage extends StatefulWidget {
  final String alunoId;

  const EditarAlunoPage({super.key, required this.alunoId});

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

  // TODO: Atualizar os índices no Firestore para incluir o campo 'genero' quando integrar com backend.
  String? _generoSelecionado;
  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];
  final String _generoPlaceholder = 'Selecione o gênero';

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
      _sobrenomeController = TextEditingController(
        text: data['sobrenome'] ?? '',
      );
      _emailController = TextEditingController(text: data['email'] ?? '');
      _telefoneController = TextEditingController(text: data['telefone'] ?? '');
      _pesoController = TextEditingController(
        text: data['pesoAtual']?.toString() ?? '',
      );

      if (data['dataNascimento'] != null) {
        _dataNascimento = (data['dataNascimento'] as Timestamp).toDate();
      }

      // TODO: Remover este bloco quando a atualização do Firestore for realizada.
      if (data['genero'] != null && _generos.contains(data['genero'])) {
        _generoSelecionado = data['genero'];
      } else {
        _generoSelecionado = _generos.first;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
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
        // TODO: Enviar o campo 'genero' para o backend quando o serviço for atualizado
        // genero: _generoSelecionado,
      );

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
    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSaving) return;
        await _salvar();
        // O _salvar já faz o pop
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
      leadingWidth: 100,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () async {
          if (_isSaving) return;
          await _salvar();
          // O _salvar já faz o pop
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.chevron_back,
              size: 17,
              color: AppColors.primary,
            ),
            SizedBox(width: 4),
            Text('Voltar', style: AppTheme.navBarAction),
          ],
        ),
      ),
      title: const Text('Editar Aluno'),
      bottom: const AppBarDivider(),
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
              _buildTextField(
                controller: _nomeController,
                label: 'NOME',
                icon: Icons.person_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'O nome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _sobrenomeController,
                label: 'SOBRENOME',
                icon: Icons.badge_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v!.isEmpty ? 'O sobrenome é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 20),
              _buildGeneroDropdown(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'E-MAIL DE ACESSO',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'O e-mail é obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _telefoneController,
                label: 'WHATSAPP / CONTATO',
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                hint: '(00) 00000-0000',
              ),
              const SizedBox(height: 56),
              _buildSubmitButton(),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.labelSecondary,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.labelSecondary.withAlpha(80),
              fontSize: 14,
            ),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.redAccent.withAlpha(100),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
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
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'GÊNERO',
            style: TextStyle(
              color: AppColors.labelSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              _generoSelecionado?.isNotEmpty == true &&
                  _generos.contains(_generoSelecionado)
              ? _generoSelecionado
              : null,
          hint: Text(
            _generoPlaceholder,
            style: TextStyle(color: AppColors.labelSecondary.withAlpha(120)),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              enabled: false,
              child: Text(
                _generoPlaceholder,
                style: TextStyle(
                  color: AppColors.labelSecondary.withAlpha(120),
                ),
              ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
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
            'NASCIMENTO',
            style: TextStyle(
              color: AppColors.labelSecondary,
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
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
                    style: TextStyle(
                      color: _dataNascimento != null
                          ? Colors.white
                          : AppColors.labelSecondary.withAlpha(80),
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
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            )
          : const Text('Atualizar Perfil'),
    );
  }
}