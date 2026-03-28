import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/aluno_service.dart';

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
  bool _isLoading = false;

  // --- FUNÇÕES DE AÇÃO ---

  Future<void> _editarInformacoes(BuildContext context) async {
    setState(() => _isLoading = true);
    
    try {
      final doc = await _alunoService.getAluno(widget.alunoId);
      if (!doc.exists) {
        throw Exception("Aluno não encontrado.");
      }
      final data = doc.data() as Map<String, dynamic>;
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      final nomeController = TextEditingController(text: data['nome'] ?? '');
      final sobrenomeController = TextEditingController(text: data['sobrenome'] ?? '');
      final emailController = TextEditingController(text: data['email'] ?? '');
      final telefoneController = TextEditingController(text: data['telefone'] ?? '');
      final pesoController = TextEditingController(text: data['pesoAtual']?.toString() ?? '');
      
      DateTime? dataNascimento;
      if (data['dataNascimento'] != null) {
        dataNascimento = (data['dataNascimento'] as Timestamp).toDate();
      }

      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              left: 24,
              right: 24,
              top: 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Editar Aluno',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                          ),
                          Text(
                            'Atualize os dados do aluno abaixo',
                            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sobrenomeController,
                    decoration: const InputDecoration(
                      labelText: 'Sobrenome',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail de Acesso',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: telefoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '(00) 00000-0000',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pesoController,
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            prefixIcon: Icon(Icons.monitor_weight_outlined),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dataNascimento ?? DateTime(2000),
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
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() => dataNascimento = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Nascimento',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              dataNascimento != null 
                                ? DateFormat('dd/MM/yyyy').format(dataNascimento!)
                                : 'Selecionar',
                              style: TextStyle(
                                color: dataNascimento != null ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _alunoService.atualizarAluno(
                            alunoId: widget.alunoId,
                            nome: nomeController.text,
                            sobrenome: sobrenomeController.text,
                            email: emailController.text,
                            telefone: telefoneController.text,
                            peso: double.tryParse(pesoController.text),
                            dataNascimento: dataNascimento,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dados atualizados com sucesso!'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao atualizar: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('SALVAR ALTERAÇÕES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
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
        backgroundColor: Colors.transparent,
        title: const Text(
          'Gerenciar Aluno',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : SingleChildScrollView(
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
                    widget.alunoNome,
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
              subtitle: 'Nome, e-mail, idade e peso',
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