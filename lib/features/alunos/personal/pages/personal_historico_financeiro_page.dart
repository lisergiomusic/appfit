import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/financeiro_service.dart';

class PersonalHistoricoFinanceiroPage extends StatelessWidget {
  final String alunoId;
  final String alunoNome;

  const PersonalHistoricoFinanceiroPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    final FinanceiroService financeiroService = FinanceiroService();
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.labelPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Histórico de Pagamentos', style: AppTheme.pageTitle),
      ),
      body: StreamBuilder<List<FaturaModel>>(
        stream: financeiroService.getFaturasStream(alunoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final historico = (snapshot.data ?? [])
              .where((f) => f.status == 'pago')
              .toList();

          if (historico.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: Colors.white.withValues(alpha: 0.05),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum pagamento registrado',
                    style: TextStyle(
                      color: AppColors.labelSecondary.withValues(alpha: 0.3),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.paddingScreen),
            itemCount: historico.length,
            itemBuilder: (context, index) {
              final fatura = historico[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.cardDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
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
                              'Pago em ${DateFormat('dd/MM/yyyy').format(fatura.dataPagamento ?? DateTime.now())}',
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
                        currencyFormat.format(fatura.valor),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
