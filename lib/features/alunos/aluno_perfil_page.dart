import 'package:flutter/material.dart';
import '../../core/services/aluno_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import '../../main.dart';

class AlunoPerfliPage extends StatefulWidget {
  final String uid;

  const AlunoPerfliPage({super.key, required this.uid});

  @override
  State<AlunoPerfliPage> createState() => _AlunoPerfliPageState();
}

class _AlunoPerfliPageState extends State<AlunoPerfliPage> {
  late final AlunoService _service;
  bool _carregando = true;
  Map<String, dynamic>? _alunoData;
  String? _erro;
  late TextEditingController _recadoController;
  bool _savingRecado = false;

  @override
  void initState() {
    super.initState();
    _service = AlunoService();
    _recadoController = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    _recadoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final doc = await _service.getAluno(widget.uid);
      if (mounted) {
        setState(() {
          _alunoData = doc.data() as Map<String, dynamic>?;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Erro ao carregar perfil: $e';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _sair(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirma ?? false) {
      await AuthService().signOut();
      if (mounted && context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ChecagemPagina()),
          (route) => false,
        );
      }
    }
  }

  void _abrirEdicaoPeso() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => _PesoEditSheet(
        uid: widget.uid,
        pesoAtual: _alunoData?['pesoAtual'] as double?,
        service: _service,
        onPesoAtualizado: (novoPeso) {
          setState(() {
            if (_alunoData != null) {
              _alunoData!['pesoAtual'] = novoPeso;
            }
          });
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Perfil'),
          bottom: const AppBarDivider(),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_erro != null || _alunoData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Perfil'),
          bottom: const AppBarDivider(),
        ),
        body: Center(
          child: Text(
            _erro ?? 'Erro ao carregar perfil',
            style: const TextStyle(color: AppColors.labelSecondary),
          ),
        ),
      );
    }

    final nome = _alunoData!['nome'] as String? ?? 'Aluno';
    final sobrenome = _alunoData!['sobrenome'] as String? ?? '';
    final nomeCompleto = '$nome $sobrenome'.trim();
    final pesoAtual = _alunoData!['pesoAtual'] as double?;
    final photoUrl = _alunoData!['photoUrl'] as String?;
    final recadoAtual = _alunoData!['recadoPersonal'] as String? ?? '';

    if (_recadoController.text.isEmpty && recadoAtual.isNotEmpty) {
      _recadoController.text = recadoAtual;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        bottom: const AppBarDivider(),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingScreen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: SpacingTokens.screenTopPadding),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              color: AppColors.labelSecondary,
                              size: 50,
                            )
                          : null,
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    Text(nomeCompleto, style: AppTheme.title1),
                  ],
                ),
              ),
              const SizedBox(height: SpacingTokens.xxl),
              Text('Dados físicos', style: AppTheme.sectionHeader),
              const SizedBox(height: SpacingTokens.labelToField),
              _buildPesoSection(pesoAtual),
              const SizedBox(height: SpacingTokens.xxl),
              _buildRecadoSection(),
              const SizedBox(height: SpacingTokens.screenBottomPadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _sair(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.systemRed.withAlpha(20),
                  ),
                  child: const Text(
                    'Sair',
                    style: TextStyle(color: AppColors.systemRed),
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.screenBottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPesoSection(double? pesoAtual) {
    final pesoCodigo =
        pesoAtual != null ? '${pesoAtual.toStringAsFixed(1)} kg' : 'Não registrado';

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
      child: Row(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            color: AppColors.labelSecondary,
            size: 24,
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peso atual', style: AppTheme.caption2),
                const SizedBox(height: SpacingTokens.xs),
                Text(pesoCodigo, style: AppTheme.cardTitle),
              ],
            ),
          ),
          IconButton(
            onPressed: _abrirEdicaoPeso,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecadoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recado para o aluno', style: AppTheme.sectionHeader),
            const Spacer(),
            if (_savingRecado)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        TextField(
          controller: _recadoController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          enabled: !_savingRecado,
          decoration: InputDecoration(
            hintText: 'Ex: Foco no alongamento pós-treino!',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: const BorderSide(color: AppColors.fillSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: const BorderSide(color: AppColors.fillSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _savingRecado ? null : _salvarRecado,
            child: const Text('Salvar recado'),
          ),
        ),
      ],
    );
  }

  Future<void> _salvarRecado() async {
    final texto = _recadoController.text.trim();
    setState(() => _savingRecado = true);
    try {
      final doc = await _service.getAluno(widget.uid);
      final d = doc.data() as Map<String, dynamic>;
      await _service.atualizarAluno(
        alunoId: widget.uid,
        nome: d['nome'] ?? '',
        sobrenome: d['sobrenome'] ?? '',
        email: d['email'] ?? '',
        recadoPersonal: texto,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recado salvo!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingRecado = false);
      }
    }
  }
}

class _PesoEditSheet extends StatefulWidget {
  final String uid;
  final double? pesoAtual;
  final AlunoService service;
  final Function(double) onPesoAtualizado;

  const _PesoEditSheet({
    required this.uid,
    required this.pesoAtual,
    required this.service,
    required this.onPesoAtualizado,
  });

  @override
  State<_PesoEditSheet> createState() => _PesoEditSheetState();
}

class _PesoEditSheetState extends State<_PesoEditSheet> {
  late TextEditingController _pesoController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pesoController = TextEditingController(
      text: widget.pesoAtual?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _salvarPeso() async {
    final pesoText = _pesoController.text.trim();
    if (pesoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um peso válido')),
      );
      return;
    }

    final peso = double.tryParse(pesoText);
    if (peso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato inválido. Use números.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final alunoDoc = await widget.service.getAluno(widget.uid);
      final alunoData = alunoDoc.data() as Map<String, dynamic>;

      await widget.service.atualizarAluno(
        alunoId: widget.uid,
        nome: alunoData['nome'] ?? '',
        sobrenome: alunoData['sobrenome'] ?? '',
        email: alunoData['email'] ?? '',
        peso: peso,
      );

      widget.onPesoAtualizado(peso);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar peso: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        left: SpacingTokens.screenHorizontalPadding,
        right: SpacingTokens.screenHorizontalPadding,
        top: SpacingTokens.lg,
        bottom: keyboardHeight + SpacingTokens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Atualizar peso', style: AppTheme.title1),
          const SizedBox(height: SpacingTokens.sectionGap),
          TextField(
            controller: _pesoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: 'Ex: 75.5',
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.sectionGap),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fillSecondary,
                    disabledBackgroundColor: AppColors.fillSecondary.withAlpha(100),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarPeso,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.labelSecondary,
                            ),
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
