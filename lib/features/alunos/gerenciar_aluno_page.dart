import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/aluno_service.dart';
import 'editar_aluno_page.dart';
import 'financeiro_aluno_page.dart';

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
  bool _isLoadingData = true;

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
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados do aluno: $e");
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
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
        backgroundColor: AppTheme.success,
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
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text(
          'Excluir Aluno?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja remover ${widget.alunoNome} definitivamente? Todos os treinos e históricos serão perdidos.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
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
              backgroundColor: AppTheme.primary,
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gerenciar Aluno',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 0.5,
            color: Colors.white.withAlpha(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.paddingScreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildSectionHeader('CONFIGURAÇÕES DO PERFIL'),
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
            const SizedBox(height: 32),
            _buildSectionHeader('GESTÃO FINANCEIRA'),
            _buildActionGroup([
              _ActionItem(
                icon: Icons.payments_rounded,
                title: 'Financeiro do Aluno',
                subtitle: 'Faturas, histórico e balanço',
                iconColor: AppTheme.primary,
                onTap: () => _irParaFinanceiro(context),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('ZONA DE SEGURANÇA'),
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
                subtitle: 'Apagar todos os dados permanentemente',
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withAlpha(50), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.surfaceLight,
              backgroundImage: _fotoUrl != null && _fotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(_fotoUrl!)
                : null,
              child: (_fotoUrl == null || _fotoUrl!.isEmpty) && !_isLoadingData
                  ? Text(
                widget.alunoNome.isNotEmpty ? widget.alunoNome[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.alunoNome,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                Text(
                  _dataCriacao != null
                    ? () {
                        String dataFormatada = DateFormat("MMMM 'de' y", "pt_BR").format(_dataCriacao!);
                        return 'Aluno desde ${dataFormatada[0].toUpperCase()}${dataFormatada.substring(1)}';
                      }()
                    : 'Aluno Ativo',
                  style: AppTheme.cardSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
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
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(AppTheme.radiusMedium) : Radius.zero,
                    bottom: isLast ? const Radius.circular(AppTheme.radiusMedium) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // mais compacto estilo iOS
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8), // menor
                          decoration: BoxDecoration(
                            color: (item.iconColor ?? AppTheme.textPrimary).withAlpha(15),
                            borderRadius: BorderRadius.circular(10), // mais sutil
                          ),
                          child: Icon(item.icon, color: item.iconColor ?? AppTheme.textPrimary, size: 20), // menor
                        ),
                        const SizedBox(width: 12), // menor
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTheme.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w600), // menor
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                style: AppTheme.cardSubtitle.copyWith(fontSize: 12), // menor
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textTertiary,
                          size: 18, // menor
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 52), // alinhado ao novo ícone
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