import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _abrirWhatsApp(String telefone) async {
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$numeroLimpo');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            return const Center(
              child: Text(
                'Erro ao carregar perfil',
                style: TextStyle(color: AppColors.labelSecondary),
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

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(
                  nomeCompleto: nomeCompleto,
                  photoUrl: photoUrl,
                  idade: idade,
                  nomePersonal: data.nomePersonal,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingScreen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: SpacingTokens.xxl),
                      if (data.nomePersonal != null) ...[
                        _buildPersonalCard(
                          nome: data.nomePersonal!,
                          especialidade: data.especialidadePersonal,
                          photoUrl: data.photoUrlPersonal,
                          telefone: data.telefonePersonal,
                        ),
                        const SizedBox(height: SpacingTokens.xxl),
                      ],
                      _buildPesoCard(pesoAtual, alunoData),
                      const SizedBox(height: 48),
                      _buildSairButton(context),
                      const SizedBox(height: SpacingTokens.screenBottomPadding),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero({
    required String nomeCompleto,
    required String? photoUrl,
    required int? idade,
    required String? nomePersonal,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow behind avatar
          Positioned(
            top: 16,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
            child: Column(
              children: [
                AlunoAvatar(
                  alunoNome: nomeCompleto,
                  photoUrl: photoUrl,
                  radius: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  nomeCompleto,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.labelPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (nomePersonal != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    'Aluno de $nomePersonal',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.labelSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (idade != null) ...[
                  const SizedBox(height: 20),
                  _buildAgePill(idade),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgePill(int idade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cake_outlined, size: 13, color: AppColors.labelSecondary),
          const SizedBox(width: 6),
          Text(
            '$idade anos',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Personal card ──────────────────────────────────────────────────────────

  Widget _buildPersonalCard({
    required String nome,
    String? especialidade,
    String? photoUrl,
    String? telefone,
  }) {
    final hasPhone = telefone != null && telefone.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green accent bar
            Container(
              width: 3,
              color: AppColors.primary,
            ),
            const SizedBox(width: 14),
            // Avatar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: AlunoAvatar(
                alunoNome: nome,
                photoUrl: photoUrl,
                radius: AvatarTokens.md,
              ),
            ),
            const SizedBox(width: 12),
            // Name + specialty
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(nome, style: AppTheme.cardTitle),
                    if (especialidade != null) ...[
                      const SizedBox(height: 3),
                      Text(especialidade, style: AppTheme.caption2),
                    ],
                  ],
                ),
              ),
            ),
            // WhatsApp button
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: hasPhone ? () => _abrirWhatsApp(telefone) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasPhone
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.fillSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 15,
                        color: hasPhone
                            ? AppColors.primary
                            : AppColors.labelSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Chamar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasPhone
                              ? AppColors.primary
                              : AppColors.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Peso ───────────────────────────────────────────────────────────────────

  Widget _buildPesoCard(double? pesoAtual, Map<String, dynamic> alunoData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peso atual',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: AppColors.labelSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pesoAtual != null
                      ? '${pesoAtual.toStringAsFixed(1)} kg'
                      : '— kg',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    height: 1,
                    color: AppColors.labelPrimary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _abrirEdicaoPeso(alunoData),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────

  Widget _buildSairButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _sair(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.systemRed.withAlpha(12),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: AppColors.systemRed.withAlpha(35),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.systemRed, size: 18),
            SizedBox(width: 8),
            Text(
              'Sair da conta',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.systemRed,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet de edição de peso ─────────────────────────────────────────

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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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
