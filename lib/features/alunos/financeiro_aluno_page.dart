import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/financeiro_service.dart';

class FinanceiroAlunoPage extends StatefulWidget {
  final String alunoId;
  final String alunoNome;

  const FinanceiroAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  State<FinanceiroAlunoPage> createState() => _FinanceiroAlunoPageState();
}

class _FinanceiroAlunoPageState extends State<FinanceiroAlunoPage> {
  final FinanceiroService _financeiroService = FinanceiroService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Financeiro',
          style: AppTheme.pageTitle,
        ),
      ),
      body: StreamBuilder<List<FaturaModel>>(
        stream: _financeiroService.getFaturasStream(widget.alunoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final faturas = snapshot.data ?? [];
          final faturasPuras = faturas.where((f) => f.status != 'pago').toList();
          final historico = faturas.where((f) => f.status == 'pago').toList();
          final totalLucro = historico.fold(0.0, (sum, f) => sum + f.valor);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildEarningsCard(totalLucro),
                const SizedBox(height: 32),
                _buildSectionHeader('FATURAS EM ABERTO'),
                if (faturasPuras.isEmpty)
                  _buildEmptyState('Nenhuma fatura pendente')
                else
                  ...faturasPuras.map((f) => _buildFaturaItem(f, isActionable: true)),
                const SizedBox(height: 32),
                _buildSectionHeader('HISTÓRICO DE PAGAMENTOS'),
                if (historico.isEmpty)
                  _buildEmptyState('Nenhum pagamento registrado')
                else
                  ...historico.map((f) => _buildFaturaItem(f, isActionable: false)),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNovaFaturaModal(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'NOVA FATURA',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildEarningsCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lucro total com o aluno',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(total),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFaturaItem(FaturaModel fatura, {required bool isActionable}) {
    final bool isAtrasado = fatura.status == 'atrasado' ||
        (fatura.status == 'pendente' && fatura.dataVencimento.isBefore(DateTime.now()));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActionable ? () => _showFaturaActions(fatura) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isActionable ? (isAtrasado ? Colors.redAccent : Colors.orangeAccent) : AppTheme.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isActionable ? Icons.receipt_long_rounded : Icons.check_circle_rounded,
                    color: isActionable ? (isAtrasado ? Colors.redAccent : Colors.orangeAccent) : AppTheme.success,
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
                        isActionable
                            ? 'Vence em ${DateFormat('dd/MM/yyyy').format(fatura.dataVencimento)}'
                            : 'Pago em ${DateFormat('dd/MM/yyyy').format(fatura.dataPagamento ?? DateTime.now())}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.history_rounded, color: Colors.white.withValues(alpha: 0.05), size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFaturaActions(FaturaModel fatura) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
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
              color: AppTheme.success,
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2)),
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
            color: AppTheme.surfaceDark,
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                title: const Text('Vencimento', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(dataVencimento),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dataVencimento,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primary,
                          onPrimary: Colors.black,
                          surface: AppTheme.surfaceDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModalState(() => dataVencimento = picked);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (valorController.text.isNotEmpty && descricaoController.text.isNotEmpty) {
                      final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
                      _financeiroService.criarFatura(FaturaModel(
                        id: '',
                        alunoId: widget.alunoId,
                        valor: valor,
                        dataVencimento: dataVencimento,
                        status: 'pendente',
                        descricao: descricaoController.text,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CRIAR COBRANÇA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}