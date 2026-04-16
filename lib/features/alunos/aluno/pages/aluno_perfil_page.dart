import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_divider.dart';
import '../../../../main.dart';
import '../../shared/models/aluno_perfil_data.dart';
import '../../shared/widgets/aluno_avatar.dart';

class AlunoPerfilPage extends StatefulWidget {
  final String uid;

  const AlunoPerfilPage({super.key, required this.uid});

  @override
  State<AlunoPerfilPage> createState() => _AlunoPerfilPageState();
}

class _AlunoPerfilPageState extends State<AlunoPerfilPage> {
  late final AlunoService _service;

  @override
  void initState() {
    super.initState();
    _service = AlunoService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int? _calcularIdade(dynamic dataNascimento) {
    if (dataNascimento == null) return null;
    final nascimento = dataNascimento is Timestamp
        ? dataNascimento.toDate()
        : dataNascimento as DateTime;
    final hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }
    return idade;
  }

  void _abrirEdicaoPeso(Map<String, dynamic> alunoData) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => _PesoEditSheet(
        uid: widget.uid,
        pesoAtual: alunoData['pesoAtual'] as double?,
        service: _service,
        onPesoAtualizado: (_) {},
      ),
      isScrollControlled: true,
    );
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ChecagemPagina()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        bottom: const AppBarDivider(),
      ),
      body: StreamBuilder<AlunoPerfilData>(
        stream: _service.getAlunoPerfilCompletoStream(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Erro ao carregar perfil',
                style: const TextStyle(color: AppColors.labelSecondary),
              ),
            );
          }

          final data = snapshot.data!;
          final alunoData = data.aluno;

          final nome = alunoData['nome'] as String? ?? 'Aluno';
          final sobrenome = alunoData['sobrenome'] as String? ?? '';
          final nomeCompleto = '$nome $sobrenome'.trim();
          final photoUrl = alunoData['photoUrl'] as String?;
          final pesoAtual = alunoData['pesoAtual'] as double?;
          final idade = _calcularIdade(alunoData['dataNascimento']);
          final nomePersonal = data.nomePersonal;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SpacingTokens.screenTopPadding),
                  _buildHeader(
                    nomeCompleto: nomeCompleto,
                    photoUrl: photoUrl,
                    pesoAtual: pesoAtual,
                    idade: idade,
                    nomePersonal: nomePersonal,
                  ),
                  const SizedBox(height: SpacingTokens.xxl),
                  Text('Dados físicos', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
                  _buildPesoSection(pesoAtual, alunoData),
                  const SizedBox(height: SpacingTokens.xxl),
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
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required String nomeCompleto,
    required String? photoUrl,
    required double? pesoAtual,
    required int? idade,
    required String? nomePersonal,
  }) {
    return Center(
      child: Column(
        children: [
          AlunoAvatar(
            alunoNome: nomeCompleto,
            photoUrl: photoUrl,
            radius: 52,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(nomeCompleto, style: AppTheme.title1),
          const SizedBox(height: SpacingTokens.titleToSubtitle),
          if (idade != null || pesoAtual != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (idade != null) _buildBadge(Icons.cake_outlined, '$idade anos'),
                if (idade != null && pesoAtual != null)
                  const SizedBox(width: SpacingTokens.sm),
                if (pesoAtual != null)
                  _buildBadge(
                    Icons.fitness_center_rounded,
                    '${pesoAtual.toStringAsFixed(1)} kg',
                  ),
              ],
            ),
          if (nomePersonal != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            Text('Aluno de $nomePersonal', style: AppTheme.sectionHeader),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: PillTokens.radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.labelSecondary),
          const SizedBox(width: 6),
          Text(label, style: PillTokens.text),
        ],
      ),
    );
  }

  Widget _buildPesoSection(double? pesoAtual, Map<String, dynamic> alunoData) {
    final pesoCodigo = pesoAtual != null
        ? '${pesoAtual.toStringAsFixed(1)} kg'
        : 'Não registrado';

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
            onPressed: () => _abrirEdicaoPeso(alunoData),
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um peso válido')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar peso: $e')));
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
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
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
                    disabledBackgroundColor: AppColors.fillSecondary.withAlpha(
                      100,
                    ),
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