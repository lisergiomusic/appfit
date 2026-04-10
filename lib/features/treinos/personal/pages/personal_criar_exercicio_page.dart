import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../shared/models/exercicio_model.dart';

class PersonalCriarExercicioPage extends StatefulWidget {
  const PersonalCriarExercicioPage({super.key});

  @override
  State<PersonalCriarExercicioPage> createState() =>
      _PersonalCriarExercicioPageState();
}

class _PersonalCriarExercicioPageState
    extends State<PersonalCriarExercicioPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final AuthService _authService = AuthService();

  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _midiaCtrl =
      TextEditingController(); // Link do Youtube/GIF

  // Lista de grupos musculares engessada (O utilizador não pode criar novos)
  final List<String> _gruposDisponiveis = [
    'Peito',
    'Costas',
    'Pernas',
    'Deltóides',
    'Bíceps',
    'Tríceps',
    'Glúteos',
    'Panturrilhas',
    'Abdômen',
  ];
  final Set<String> _gruposSelecionados = {};
  bool _isSaving = false;
  bool _isAdmin = false;
  bool _isPublico = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  void _salvarExercicio() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dê um nome ao exercício.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_gruposSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um grupo muscular.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final novoEx = ExercicioItem(
      nome: _nomeCtrl.text.trim(),
      grupoMuscular: _gruposSelecionados.toList(),
      imagemUrl: _midiaCtrl.text.trim().isNotEmpty
          ? _midiaCtrl.text.trim()
          : null,
      series: [],
    );

    try {
      await _exerciseService.criarExercicioCustomizado(
        novoEx,
        forPublico: _isAdmin && _isPublico,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercício criado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(
          context,
          novoEx,
        ); // Retorna 'novoEx' para a biblioteca saber que deve adicioná-lo automaticamente
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- WIDGET AUXILIAR PARA INPUTS ---
  Widget _buildSectionLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Novo Exercício',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. NOME
                    _buildSectionLabel(
                      'NOME DO EXERCÍCIO',
                      Icons.fitness_center,
                    ),
                    TextField(
                      controller: _nomeCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Ex: Supino Reto com Halteres',
                        hintStyle: TextStyle(
                          color: AppColors.labelSecondary.withAlpha(100),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 2. GRUPO MUSCULAR (SELEÇÃO)
                    _buildSectionLabel(
                      'MÚSCULOS ALVO (Selecione um ou mais)',
                      Icons.accessibility_new,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: _gruposDisponiveis.map((grupo) {
                        final isSelected = _gruposSelecionados.contains(grupo);
                        return FilterChip(
                          label: Text(grupo),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _gruposSelecionados.add(grupo);
                              } else {
                                _gruposSelecionados.remove(grupo);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withAlpha(40),
                          checkmarkColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceDark,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.labelSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // 4. MÍDIA (VÍDEO/GIF)
                    _buildSectionLabel(
                      'VÍDEO DEMONSTRATIVO (OPCIONAL)',
                      Icons.play_circle_outline,
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha(10),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _midiaCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cole o link do YouTube ou GIF...',
                              hintStyle: TextStyle(
                                color: AppColors.labelSecondary.withAlpha(100),
                              ),
                              filled: true,
                              fillColor: Colors.black.withAlpha(50),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: AppColors.labelSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Upload de dispositivo em breve! Use o link por enquanto.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.upload_file,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              label: const Text(
                                'Enviar mídia do telemóvel',
                                style: TextStyle(color: AppColors.primary),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: AppColors.primary.withAlpha(50),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 5. BOTÃO SECRETO (ADMIN ONLY)
                    if (_isAdmin)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isPublico
                                ? AppColors.primary.withAlpha(100)
                                : Colors.white.withAlpha(10),
                            width: 1,
                          ),
                        ),
                        child: SwitchListTile(
                          value: _isPublico,
                          onChanged: (val) => setState(() => _isPublico = val),
                          activeThumbColor: AppColors.primary,
                          title: const Text(
                            'Salvar como Exercício Público (Global)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Este exercício ficará visível para todos os utilizadores da plataforma.',
                            style: TextStyle(
                              color: AppColors.labelSecondary.withAlpha(150),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // BOTÃO SALVAR FIXO NO RODAPÉ
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(10)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarExercicio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Salvar Exercício',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
