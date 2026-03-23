import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class GerenciarAlunoPage extends StatelessWidget {
  final String alunoId;
  final String alunoNome;

  const GerenciarAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  // --- FUNÇÕES DE AÇÃO (Mocks) ---

  void _editarInformacoes(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Em breve: Abrir formulário de edição!')),
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
    // Aqui usamos um Diálogo de Confirmação crítico antes de deletar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Excluir Aluno?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja remover $alunoNome definitivamente? Todos os treinos e históricos serão perdidos.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sim, Excluir',
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
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(alunoId)
            .delete();
        if (context.mounted) {
          // Volta duas telas (fecha gerenciar e fecha perfil) para voltar à lista de alunos
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
        backgroundColor: Colors.transparent,
        title: const Text(
          'Gerenciar Aluno',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Identificação Rápida
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.surfaceLight,
                  child: Icon(Icons.person, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    alunoNome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // SEÇÃO 1: Ações Gerais
            const Text(
              'AÇÕES GERAIS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.edit_outlined,
              title: 'Editar Informações',
              subtitle: 'Nome, e-mail, idade e objetivos',
              onTap: () => _editarInformacoes(context),
            ),
            _buildSettingsItem(
              icon: Icons.send_outlined,
              title: 'Enviar convite do App',
              subtitle: 'Mandar link de acesso para o aluno',
              onTap: () => _enviarConviteApp(context),
            ),

            const SizedBox(height: 40),

            // SEÇÃO 2: Zona de Perigo (Segurança e Exclusão)
            const Text(
              'ZONA DE PERIGO',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.block,
              title: 'Bloquear Acesso',
              subtitle: 'O aluno não poderá fazer login',
              iconColor: Colors.orangeAccent,
              titleColor: Colors.orangeAccent,
              onTap: () => _alternarBloqueio(context),
            ),
            _buildSettingsItem(
              icon: Icons.delete_outline,
              title: 'Excluir Aluno',
              subtitle: 'Apagar todos os dados permanentemente',
              iconColor: Colors.redAccent,
              titleColor: Colors.redAccent,
              onTap: () => _excluirAluno(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppTheme.textSecondary,
    Color titleColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}