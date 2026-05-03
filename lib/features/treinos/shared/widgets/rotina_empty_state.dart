import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';

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
          const Spacer(flex: 2),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.square_list,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Estruture a planilha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Adicione as sessões de treino (ex: Treino A, Treino B)\npara começar a organizar a rotina.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.labelSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const Spacer(flex: 2),
          AppPrimaryButton(
            label: 'Criar Primeira Sessão',
            icon: CupertinoIcons.add_circled,
            onPressed: onCreateSession,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}