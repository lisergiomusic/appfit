import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_thumbnail.dart';

class CopyToOthersSheet extends StatefulWidget {
  final List<ExercicioItem> allExercises;
  final ExercicioItem sourceExercise;

  const CopyToOthersSheet({
    super.key,
    required this.allExercises,
    required this.sourceExercise,
  });

  static Future<List<int>?> show(
    BuildContext context, {
    required List<ExercicioItem> allExercises,
    required ExercicioItem sourceExercise,
  }) {
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CopyToOthersSheet(
        allExercises: allExercises,
        sourceExercise: sourceExercise,
      ),
    );
  }

  @override
  State<CopyToOthersSheet> createState() => _CopyToOthersSheetState();
}

class _CopyToOthersSheetState extends State<CopyToOthersSheet> {
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    // Filtra o exercício de origem da lista de destino
    final otherExercises = widget.allExercises.asMap().entries.where(
      (entry) => entry.value != widget.sourceExercise,
    ).toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(240),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copiar séries para...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Selecione quais exercícios da sessão receberão as '),
                        TextSpan(
                          text: '${widget.sourceExercise.series.length} séries',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' configuradas para '),
                        TextSpan(
                          text: widget.sourceExercise.nome,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: otherExercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = otherExercises[index];
                  final exIndex = entry.key;
                  final ex = entry.value;
                  final isSelected = _selectedIndices.contains(exIndex);

                  return _buildExerciseOption(context, ex, exIndex, isSelected);
                },
              ),
            ),
            
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppPrimaryButton(
                label: _selectedIndices.isEmpty 
                    ? 'Selecione ao menos um' 
                    : 'Copiar para ${_selectedIndices.length} ${_selectedIndices.length == 1 ? 'exercício' : 'exercícios'}',
                onPressed: _selectedIndices.isEmpty 
                    ? () {}
                    : () => Navigator.pop(context, _selectedIndices.toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseOption(BuildContext context, ExercicioItem ex, int index, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(20) : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary.withAlpha(100) : Colors.white.withAlpha(15), 
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              ExercicioThumbnail(
                exercicio: ex,
                width: 52,
                height: 52,
                borderRadius: 12,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white.withAlpha(100),
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${ex.series.length} ${ex.series.length == 1 ? 'série' : 'séries'}',
                            style: TextStyle(
                              color: ex.series.isEmpty 
                                  ? Colors.redAccent.withAlpha(180) 
                                  : AppColors.primary.withAlpha(180),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' • ${ex.grupoMuscular.join(' • ')}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white.withAlpha(40),
                    width: 2,
                  ),
                ),
                child: isSelected 
                    ? const Icon(Icons.check, size: 16, color: Colors.black) 
                    : null,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}