import 'package:appfit/core/widgets/app_nav_back_button.dart';
import '../../core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/financeiro_service.dart';
import 'historico_financeiro_page.dart';
import 'widgets/aluno_avatar.dart';

class FinanceiroAlunoPage extends StatefulWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;
  final DateTime? dataCriacao;

  const FinanceiroAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
    this.dataCriacao,
  });

  @override
  State<FinanceiroAlunoPage> createState() => _FinanceiroAlunoPageState();
}

class _FinanceiroAlunoPageState extends State<FinanceiroAlunoPage> {
  final FinanceiroService _financeiroService = FinanceiroService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: AppNavBackButton(),
        title: const Text('Financeiro'),
      ),
      body: StreamBuilder<List<FaturaModel>>(
        stream: _financeiroService.getFaturasStream(widget.alunoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final faturas = snapshot.data ?? [];
          final faturasAbertas = faturas
              .where((f) => f.status != 'pago')
              .toList();
          final historico = faturas.where((f) => f.status == 'pago').toList();
          final totalLucro = historico.fold(0.0, (sum, f) => sum + f.valor);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingScreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildStudentHeader(),
                const SizedBox(height: 24),
                _buildEarningsCard(totalLucro),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('FATURAS EM ABERTO'),
                    _buildHistoryButton(),
                  ],
                ),
                const SizedBox(height: 8),
                if (faturasAbertas.isEmpty)
                  _buildEmptyState('Nenhuma fatura pendente')
                else
                  ...faturasAbertas.map((f) => _buildFaturaItem(f)),
                const SizedBox(height: 100),
                AppPrimaryButton(
                  label: 'Nova Fatura',
                  icon: Icons.add,
                  onPressed: () => _showNovaFaturaModal(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentHeader() {
    final String tempoAluno = widget.dataCriacao != null
        ? () {
            String dataFormatada = DateFormat(
              "MMMM 'de' y",
              "pt_BR",
            ).format(widget.dataCriacao!);
            return 'Aluno desde ${dataFormatada[0].toUpperCase()}${dataFormatada.substring(1)}';
          }()
        : 'Aluno Ativo';

    return Row(
      children: [
        AlunoAvatar(
          alunoNome: widget.alunoNome,
          photoUrl: widget.photoUrl,
          radius: 28,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.alunoNome,
              style: const TextStyle(
                color: AppColors.labelPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              tempoAluno,
              style: TextStyle(
                color: AppColors.labelSecondary.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL RECEBIDO',
                style: TextStyle(
                  color: AppColors.labelSecondary.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.labelSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildHistoryButton() {
    return TextButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoricoFinanceiroPage(
              alunoId: widget.alunoId,
              alunoNome: widget.alunoNome,
            ),
          ),
        );
      },
      icon: const Icon(
        Icons.history_rounded,
        size: 16,
        color: AppColors.primary,
      ),
      label: const Text(
        'Ver Histórico',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFaturaItem(FaturaModel fatura) {
    final bool isAtrasado =
        fatura.status == 'atrasado' ||
        (fatura.status == 'pendente' &&
            fatura.dataVencimento.isBefore(DateTime.now()));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFaturaActions(fatura),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isAtrasado ? Colors.redAccent : Colors.orangeAccent)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: isAtrasado ? Colors.redAccent : Colors.orangeAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fatura.descricao,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vence em ${DateFormat('dd/MM/yyyy').format(fatura.dataVencimento)}',
                        style: TextStyle(
                          color: AppColors.labelSecondary.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currencyFormat.format(fatura.valor),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      width: double.infinity,
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            color: Colors.white.withValues(alpha: 0.05),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.labelSecondary.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFaturaActions(FaturaModel fatura) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionTile(
              onTap: () {
                Navigator.pop(context);
                _financeiroService.marcarComoPaga(fatura.id);
              },
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
              title: 'Marcar como paga',
              subtitle: 'Confirmar recebimento deste valor',
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              onTap: () {
                Navigator.pop(context);
                _financeiroService.excluirFatura(fatura.id);
              },
              icon: Icons.delete_outline_rounded,
              color: Colors.redAccent,
              title: 'Excluir Fatura',
              subtitle: 'Remover esta cobrança permanentemente',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.labelSecondary.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNovaFaturaModal(BuildContext context) {
    final TextEditingController valorController = TextEditingController();
    final TextEditingController descricaoController = TextEditingController();
    DateTime dataVencimento = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nova Fatura',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descricaoController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descrição (Ex: Mensalidade)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Vencimento',
                  style: TextStyle(
                    color: AppColors.labelSecondary,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(dataVencimento),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dataVencimento,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: Colors.black,
                          surface: AppColors.surfaceDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setModalState(() => dataVencimento = picked);
                  }
                },
              ),
              const SizedBox(height: 32),
              AppPrimaryButton(
                label: 'Criar Cobrança',
                onPressed: () {
                  if (valorController.text.isNotEmpty &&
                      descricaoController.text.isNotEmpty) {
                    final valor =
                        double.tryParse(
                          valorController.text.replaceAll(',', '.'),
                        ) ??
                        0.0;
                    _financeiroService.criarFatura(
                      FaturaModel(
                        id: '',
                        alunoId: widget.alunoId,
                        valor: valor,
                        dataVencimento: dataVencimento,
                        status: 'pendente',
                        descricao: descricaoController.text,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
