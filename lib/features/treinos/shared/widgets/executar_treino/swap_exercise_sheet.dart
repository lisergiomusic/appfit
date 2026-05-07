import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import '../exercicio_thumbnail.dart';

class SwapExerciseSheet extends StatelessWidget {
  final List<ExercicioItem> selecionados;
  final ExercicioItem atual;

  const SwapExerciseSheet({
    super.key,
    required this.selecionados,
    required this.atual,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Trocar exercício',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 32),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ...selecionados.map((ex) {
                    final isAtual = ex.nome == atual.nome;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: isAtual ? null : () => Navigator.pop(context, ex),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ExercicioThumbnail(
                                exercicio: ex,
                                width: 48,
                                height: 48,
                                borderRadius: 4, // More technical corners
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.nome,
                                      style: TextStyle(
                                        color: isAtual ? AppColors.primary : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ex.grupoMuscular.join(' • '),
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(100),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAtual)
                                const Icon(Icons.check, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  // Spotify "CANCELAR" Pill Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: SpacingTokens.screenBottomPadding + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}