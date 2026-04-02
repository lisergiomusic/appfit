import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/app_bar_divider.dart';
import 'widgets/aluno_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/aluno_service.dart';
import 'editar_aluno_page.dart';
import 'financeiro_aluno_page.dart';
import '../../core/widgets/app_nav_back_button.dart';

class GerenciarAlunoPage extends StatefulWidget {
  final String alunoId;
  final String alunoNome;

  const GerenciarAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  State<GerenciarAlunoPage> createState() => _GerenciarAlunoPageState();
}

class _GerenciarAlunoPageState extends State<GerenciarAlunoPage> {
  final AlunoService _alunoService = AlunoService();
  String? _fotoUrl;
  DateTime? _dataCriacao;

  @override
  void initState() {
    super.initState();
    _buscarDadosAluno();
  }

  Future<void> _buscarDadosAluno() async {
    try {
      final doc = await _alunoService.getAluno(widget.alunoId);
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fotoUrl = data['photoUrl'] ?? data['fotoUrl'];
          if (data['dataCriacao'] != null) {
            _dataCriacao = (data['dataCriacao'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados do aluno: $e");
      if (mounted) {}
    }
  }

  // --- FUNÇÕES DE AÇÃO ---

  Future<void> _irParaEditar(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarAlunoPage(alunoId: widget.alunoId),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      _buscarDadosAluno();
    }
  }

  void _irParaFinanceiro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinanceiroAlunoPage(
          alunoId: widget.alunoId,
          alunoNome: widget.alunoNome,
          photoUrl: _fotoUrl,
          dataCriacao: _dataCriacao,
        ),
      ),
    );
  }

  void _enviarConviteApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve: Link de convite copiado/enviado!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _alternarBloqueio(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve: Status alterado para Bloqueado!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _excluirAluno(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: const Text(
          'Excluir Aluno?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja remover ${widget.alunoNome} definitivamente? Todos os treinos e históricos serão perdidos.',
          style: const TextStyle(color: AppColors.labelSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: AppColors.labelSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'REMOVER',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _alunoService.deletarAluno(widget.alunoId);
        if (context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aluno excluído com sucesso.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        debugPrint("Erro ao excluir aluno: $e");
      }
    }
  }

  // --- INTERFACE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: const AppNavBackButton(),
        title: const Text('Gerenciar Aluno'),
        bottom: const AppBarDivider(),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.screenHorizontalPadding,
          SpacingTokens.screenTopPadding,
          SpacingTokens.screenHorizontalPadding,
          SpacingTokens.screenBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: SpacingTokens.sectionGap),
            _buildSectionHeader('Configurações do perfil'),
            _buildActionGroup([
              _ActionItem(
                icon: Icons.edit_rounded,
                title: 'Editar Informações',
                subtitle: 'Informações pessoais e de contato',
                onTap: () => _irParaEditar(context),
              ),
              _ActionItem(
                icon: Icons.send_rounded,
                title: 'Enviar convite do App',
                subtitle: 'Mandar link de acesso para o aluno',
                onTap: () => _enviarConviteApp(context),
              ),
            ]),
            const SizedBox(height: SpacingTokens.sectionGap),
            _buildSectionHeader('Gestão financeira'),
            _buildActionGroup([
              _ActionItem(
                icon: Icons.payments_rounded,
                title: 'Financeiro do Aluno',
                subtitle: 'Faturas, histórico e balanço',
                iconColor: AppColors.primary,
                onTap: () => _irParaFinanceiro(context),
              ),
            ]),
            const SizedBox(height: SpacingTokens.sectionGap),
            _buildSectionHeader('Zona de segurança'),
            _buildActionGroup([
              _ActionItem(
                icon: Icons.block_rounded,
                title: 'Bloquear Acesso',
                subtitle: 'O aluno não poderá fazer login',
                iconColor: Colors.orangeAccent,
                onTap: () => _alternarBloqueio(context),
              ),
              _ActionItem(
                icon: Icons.delete_forever_rounded,
                title: 'Excluir Aluno',
                subtitle: 'Apagar todos os dados',
                iconColor: Colors.redAccent,
                onTap: () => _excluirAluno(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Row(
      children: [
        AlunoAvatar(
          alunoNome: widget.alunoNome,
          photoUrl: _fotoUrl,
          radius: AvatarTokens.lg,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.alunoNome,
                style: CardTokens.cardTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: SpacingTokens.titleToSubtitle),
              Text(
                _dataCriacao != null
                    ? () {
                        String dataFormatada = DateFormat(
                          "MMMM 'de' y",
                          "pt_BR",
                        ).format(_dataCriacao!);
                        return 'Aluno desde ${dataFormatada[0].toUpperCase()}${dataFormatada.substring(1)}';
                      }()
                    : 'Aluno Ativo',
                style: AppTheme.cardSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.labelToField),
      child: Text(title, style: AppTheme.sectionHeader),
    );
  }

  Widget _buildActionGroup(List<_ActionItem> items) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  splashColor: AppColors.splash,
                  borderRadius: BorderRadius.vertical(
                    top: index == 0
                        ? const Radius.circular(AppTheme.radiusLG)
                        : Radius.zero,
                    bottom: isLast
                        ? const Radius.circular(AppTheme.radiusLG)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: CardTokens.padding,
                    // mais compacto estilo iOS
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8), // menor
                          decoration: BoxDecoration(
                            color: (item.iconColor ?? AppColors.labelPrimary)
                                .withAlpha(15),
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // mais sutil
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor ?? AppColors.labelPrimary,
                            size: 20,
                          ), // menor
                        ),
                        const SizedBox(width: 12), // menor
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: CardTokens.cardTitle),
                              const SizedBox(
                                height: SpacingTokens.titleToSubtitle,
                              ),
                              Text(item.subtitle, style: AppTheme.cardSubtitle),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.labelTertiary,
                          size: 18, // menor
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Divider(height: 1, color: Colors.white.withAlpha(10)),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });
}
