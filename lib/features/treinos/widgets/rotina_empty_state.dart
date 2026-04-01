import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';

class RotinaEmptyState extends StatelessWidget {
  final VoidCallback onCreateSession;

  const RotinaEmptyState({super.key, required this.onCreateSession});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.paddingScreen,
        0,
        AppTheme.paddingScreen,
        SpacingTokens.screenBottomPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.square_list,
              size: 48,
              color: AppColors.primary.withAlpha(150),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sua planilha está vazia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione as sessões de treino (ex: Treino A, Treino B)\npara começar a configurar os exercícios.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.labelSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            label: 'Criar sessão',
            icon: CupertinoIcons.add_circled,
            onPressed: onCreateSession,
          ),
        ],
      ),
    );
  }
}
