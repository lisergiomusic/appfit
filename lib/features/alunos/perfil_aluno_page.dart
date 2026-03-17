import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../treinos/rotina_detalhe_page.dart';
import 'gerenciar_aluno_page.dart';
import 'feedback_historico_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PerfilAlunoPage extends StatelessWidget {
  final String alunoId;
  final String alunoNome;

  const PerfilAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  Future<void> _atribuirTreinoAoAluno(
    BuildContext context,
    String templateId,
    String nomeRotina,
    int duracaoSemanas,
  ) async {
    try {
      final templateDoc = await FirebaseFirestore.instance
          .collection('rotinas')
          .doc(templateId)
          .get();
      if (!templateDoc.exists) return;

      final rotinasAntigas = await FirebaseFirestore.instance
          .collection('rotinas')
          .where('alunoId', isEqualTo: alunoId)
          .where('ativa', isEqualTo: true)
          .get();

      for (var doc in rotinasAntigas.docs) {
        await doc.reference.update({'ativa': false});
      }

      final rotinaData = templateDoc.data() as Map<String, dynamic>;

      rotinaData['alunoId'] = alunoId;
      rotinaData['ativa'] = true;
      rotinaData['dataCriacao'] = FieldValue.serverTimestamp();
      rotinaData['dataVencimento'] = Timestamp.fromDate(
        DateTime.now().add(Duration(days: duracaoSemanas * 7)),
      );

      await FirebaseFirestore.instance.collection('rotinas').add(rotinaData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rotina "$nomeRotina" ativada com sucesso!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao vincular rotina: $e");
    }
  }

  void _confirmarAtivacaoTemplate(
    BuildContext context,
    String templateId,
    String titulo,
  ) {
    int semanasSelecionadas = 4;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Ativar Rotina',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Defina a duração da rotina "$titulo" para $alunoNome:',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: semanasSelecionadas,
                  dropdownColor: AppTheme.surfaceLight,
                  style: const TextStyle(color: Colors.white),
                  items: [4, 5, 6, 8, 10, 12]
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text('$w semanas'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => semanasSelecionadas = v!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  _atribuirTreinoAoAluno(
                    context,
                    templateId,
                    titulo,
                    semanasSelecionadas,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ativar Ficha',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removerFichaAtiva(BuildContext context, String docId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remover Ficha?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'O aluno ficará sem nenhuma rotina ativa no momento. Deseja continuar?',
          style: TextStyle(color: AppTheme.textSecondary),
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
              'Sim, Remover',
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
            .collection('rotinas')
            .doc(docId)
            .update({'ativa': false});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rotina arquivada com sucesso.'),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint("Erro ao remover ficha: $e");
      }
    }
  }

  void _exibirOpcoesVincularTreino(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Nova Rotina Semanal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RotinaDetalhePage(
                        alunoId: alunoId,
                        alunoNome: alunoNome,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_to_photos, color: Colors.white),
                label: const Text(
                  'Criar Nova Ficha Completa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              const Text(
                'Ou escolha da sua Biblioteca de Fichas:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rotinas')
                      .where('personalId', isEqualTo: personalId)
                      .where('alunoId', isNull: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Sua biblioteca de rotinas está vazia.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var rotina = doc.data() as Map<String, dynamic>;
                        int qtdSessoes = rotina['sessoes'] != null
                            ? (rotina['sessoes'] as List).length
                            : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withAlpha(128),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              rotina['nome'] ?? 'Rotina',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Template • $qtdSessoes sessões',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.add_circle,
                              color: AppTheme.primary,
                            ),
                            onTap: () => _confirmarAtivacaoTemplate(
                              context,
                              doc.id,
                              rotina['nome'] ?? 'Rotina',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _chamarWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve: Abrir conversa no WhatsApp!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Gestão do Aluno',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GerenciarAlunoPage(
                    alunoId: alunoId,
                    alunoNome: alunoNome,
                  ),
                ),
              );
            },
            tooltip: 'Gerenciar Aluno',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(alunoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final alunoData =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final photoUrl = alunoData['photoUrl'] as String?;
          final status =
              (alunoData['status']?.toString().toLowerCase() ?? 'ativo');
          final isAtivo = status == 'ativo';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAtivo
                                ? AppTheme.success
                                : AppTheme.textSecondary.withAlpha(100),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.surfaceLight,
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Text(
                                  alunoNome.isNotEmpty
                                      ? alunoNome[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              alunoNome,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '28 anos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton.icon(
                    onPressed: () => _chamarWhatsApp(context),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text(
                      'Enviar Mensagem',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success.withAlpha(38),
                      foregroundColor: AppTheme.success,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildRitmoDaSemana(),
                const SizedBox(height: 32),

                _buildFichaAtivaHeroCard(context),

                const SizedBox(height: 24),
                _buildMenuOption(
                  icon: Icons.calendar_month_outlined,
                  title: 'Histórico de Feedbacks',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FeedbackHistoricoPage(alunoNome: alunoNome),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  icon: Icons.assignment_outlined,
                  title: 'Avaliação Física',
                  onTap: () {},
                ),
                _buildMenuOption(
                  icon: Icons.payments_outlined,
                  title: 'Situação Financeira',
                  onTap: () {},
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRitmoDaSemana() {
    final dias = [
      {'dia': 'S', 'status': 'feito'},
      {'dia': 'T', 'status': 'feito'},
      {'dia': 'Q', 'status': 'futuro'},
      {'dia': 'Q', 'status': 'feito'},
      {'dia': 'S', 'status': 'feito'},
      {'dia': 'S', 'status': 'futuro'},
      {'dia': 'D', 'status': 'futuro'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FREQUÊNCIA SEMANAL',
                style: AppTheme.textSectionHeaderDark,
              ),
              Text(
                'Semana Atual',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(10)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dias.map((d) {
                  final isFeito = d['status'] == 'feito';
                  final isFalta = d['status'] == 'falta';
                  return Column(
                    children: [
                      Text(
                        d['dia']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isFeito
                              ? AppTheme.primary
                              : (isFalta
                                    ? AppTheme.surfaceLight
                                    : AppTheme.surfaceDark),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isFeito
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: .18,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                          border: Border.all(
                            color: isFeito
                                ? AppTheme.primary
                                : (isFalta
                                      ? Colors.redAccent.withAlpha(77)
                                      : AppTheme.textSecondary.withAlpha(26)),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isFeito
                              ? Icon(
                                  Icons.check,
                                  color: AppTheme.surfaceDark,
                                  size: 26,
                                )
                              : (isFalta
                                    ? Icon(
                                        Icons.close,
                                        color: Colors.redAccent.withAlpha(204),
                                        size: 22,
                                      )
                                    : Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppTheme.textSecondary
                                              .withAlpha(51),
                                          shape: BoxShape.circle,
                                        ),
                                      )),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFichaAtivaHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rotinas')
            .where('alunoId', isEqualTo: alunoId)
            .where('ativa', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return InkWell(
              onTap: () => _exibirOpcoesVincularTreino(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(77),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_to_photos,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nenhuma Rotina Ativa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toque para montar ou vincular rotina',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          var treinoDoc = snapshot.data!.docs.first;
          var rotina = treinoDoc.data() as Map<String, dynamic>;

          DateTime hoje = DateTime.now();
          DateTime dataCriacao =
              (rotina['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
          DateTime dataVencimento =
              (rotina['dataVencimento'] as Timestamp?)?.toDate() ??
              hoje.add(const Duration(days: 28));

          int totalDias = dataVencimento.difference(dataCriacao).inDays;
          if (totalDias <= 0) totalDias = 1;

          int diasPassados = hoje.difference(dataCriacao).inDays;
          int diasRestantes = totalDias - diasPassados;

          double progressoAtual = (diasPassados / totalDias).clamp(0.0, 1.0);

          bool alertaVencimento = diasRestantes <= 7 && diasRestantes >= 0;
          Color corProgresso = AppTheme.success;

          String textoRestante;
          if (diasRestantes < 0) {
            textoRestante = 'Vencida há ${diasRestantes.abs()} dias';
            corProgresso = Colors.redAccent;
          } else if (diasRestantes == 0) {
            textoRestante = 'Vence hoje';
            corProgresso = Colors.orangeAccent;
          } else if (alertaVencimento) {
            textoRestante = 'Vence em $diasRestantes dias';
            corProgresso = Colors.orangeAccent;
          } else {
            textoRestante = '$diasRestantes dias restantes';
          }

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RotinaDetalhePage(
                    rotinaData: rotina,
                    rotinaId: treinoDoc.id,
                    alunoId: alunoId,
                    alunoNome: alunoNome,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surfaceDark,
                    AppTheme.surfaceLight.withAlpha(204),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: alertaVencimento
                      ? Colors.orangeAccent.withAlpha(50)
                      : (diasRestantes < 0
                            ? Colors.redAccent.withAlpha(50)
                            : Colors.white.withAlpha(13)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.style,
                            size: 16,
                            color: diasRestantes < 0
                                ? Colors.redAccent
                                : AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            diasRestantes < 0
                                ? 'ROTINA EXPIRADA'
                                : 'ROTINA ATUAL',
                            style: TextStyle(
                              color: diasRestantes < 0
                                  ? Colors.redAccent
                                  : AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _removerFichaAtiva(context, treinoDoc.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.archive_outlined,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _exibirOpcoesVincularTreino(context),
                            child: const Text(
                              'Trocar',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    rotina['nome'] ?? 'Projeto Hipertrofia',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toque para ver e editar treinos',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        textoRestante,
                        style: TextStyle(
                          color: corProgresso,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(progressoAtual * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressoAtual,
                      backgroundColor: Colors.black.withAlpha(77),
                      color: corProgresso,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppTheme.textSecondary,
    Color textColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}