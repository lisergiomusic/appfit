import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'exercicios_library_page.dart';

// --- MODELOS DE DADOS REFINADOS ---
class SerieItem {
  bool isAquecimento;
  String
  alvo; // <-- NOVO: Mudamos de 'reps' para 'alvo', pois pode ser repetição ou tempo
  String carga;
  String descanso;

  SerieItem({
    this.isAquecimento = false,
    this.alvo = '10',
    this.carga = '-',
    this.descanso = '60s',
  });
}

class ExercicioItem {
  String nome;
  String observacao;
  String tipoAlvo; // <-- NOVO: 'Reps' ou 'Tempo'
  List<SerieItem> series;

  ExercicioItem({
    required this.nome,
    this.observacao = '',
    this.tipoAlvo = 'Reps', // O padrão é Repetições
    required this.series,
  });
}

class ConfigurarExerciciosPage extends StatefulWidget {
  final String nomeTreino;

  const ConfigurarExerciciosPage({super.key, required this.nomeTreino});

  @override
  State<ConfigurarExerciciosPage> createState() =>
      _ConfigurarExerciciosPageState();
}

class _ConfigurarExerciciosPageState extends State<ConfigurarExerciciosPage> {
  // Mock atualizado com um exercício de TEMPO (Prancha)
  final List<ExercicioItem> _exercicios = [
    ExercicioItem(
      nome: 'Supino Reto com Barra',
      observacao: 'Focar na cadência 3010. Não esticar totalmente o cotovelo.',
      tipoAlvo: 'Reps',
      series: [
        SerieItem(
          isAquecimento: true,
          alvo: '15',
          carga: '10kg',
          descanso: '45s',
        ),
        SerieItem(
          isAquecimento: false,
          alvo: '12',
          carga: '30kg',
          descanso: '90s',
        ),
        SerieItem(
          isAquecimento: false,
          alvo: '10',
          carga: '35kg',
          descanso: '90s',
        ),
      ],
    ),
    ExercicioItem(
      nome: 'Prancha Isométrica', // Exemplo de exercício por tempo
      observacao: 'Manter a contração do abdômen e glúteos.',
      tipoAlvo: 'Tempo', // Já nasce configurado para tempo
      series: [
        SerieItem(
          isAquecimento: false,
          alvo: '60s',
          carga: '-',
          descanso: '30s',
        ),
        SerieItem(
          isAquecimento: false,
          alvo: '60s',
          carga: '-',
          descanso: '30s',
        ),
        SerieItem(
          isAquecimento: false,
          alvo: '60s',
          carga: '-',
          descanso: '30s',
        ),
      ],
    ),
  ];

  // --- LÓGICA DE ADICIONAR SÉRIE COM PERGUNTA (MANTIDA) ---
  Future<void> _adicionarSerie(int exIndex) async {
    final bool? isAquecimento = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Adicionar Nova Série',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withAlpha(50)),
                    ),
                    child: const Center(
                      child: Text(
                        'AQ',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: const Text(
                    'Série de Aquecimento',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Preparação com carga reduzida',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: const Text(
                    'Série de Trabalho',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Série principal para o volume do treino',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (isAquecimento != null) {
      setState(() {
        String alvoToClone = '10';
        String cargaToClone = '-';
        String descansoToClone = '60s';

        if (_exercicios[exIndex].series.isNotEmpty) {
          final ultimaSerie = _exercicios[exIndex].series.last;
          alvoToClone = ultimaSerie.alvo;
          cargaToClone = ultimaSerie.carga;
          descansoToClone = ultimaSerie.descanso;
        }

        _exercicios[exIndex].series.add(
          SerieItem(
            isAquecimento: isAquecimento,
            alvo: alvoToClone,
            carga: cargaToClone,
            descanso: descansoToClone,
          ),
        );
      });
    }
  }

  void _removerSerie(int exIndex, int serieIndex) {
    setState(() {
      _exercicios[exIndex].series.removeAt(serieIndex);
    });
  }

  void _alternarTipoSerie(int exIndex, int serieIndex) {
    setState(() {
      final serie = _exercicios[exIndex].series[serieIndex];
      serie.isAquecimento = !serie.isAquecimento;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.nomeTreino,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _exercicios.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: _exercicios.length,
                    itemBuilder: (context, index) => _buildExercicioCard(index),
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.white.withAlpha(26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum exercício adicionado',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(int exIndex) {
    final ex = _exercicios[exIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABEÇALHO DO EXERCÍCIO
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ex.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.note_add_outlined,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Adicionar observação',
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),

          // CAMPO DE OBSERVAÇÃO (Se houver)
          if (ex.observacao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withAlpha(50)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primary.withAlpha(200),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex.observacao,
                        style: TextStyle(
                          color: AppTheme.primary.withAlpha(200),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // TABELA DE SÉRIES (CABEÇALHO)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Text(
                    'Série',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // --- A MÁGICA ACONTECE AQUI: CABEÇALHO CLICÁVEL ---
                Expanded(
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          // Alterna o tipo de Alvo entre Reps e Tempo
                          ex.tipoAlvo = ex.tipoAlvo == 'Reps'
                              ? 'Tempo'
                              : 'Reps';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Meta alterada para ${ex.tipoAlvo}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ex.tipoAlvo == 'Tempo' ? 'Tempo' : 'Reps',
                              style: const TextStyle(
                                color: AppTheme.primary, // Cor de destaque
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.swap_vert,
                              color: AppTheme.primary,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Carga',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Pausa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // LINHAS DAS SÉRIES
          ...List.generate(ex.series.length, (serieIndex) {
            return _buildSerieRow(exIndex, serieIndex);
          }),

          // BOTÃO ADICIONAR SÉRIE
          InkWell(
            onTap: () => _adicionarSerie(exIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(10)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: AppTheme.textSecondary.withAlpha(200),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Adicionar Série',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(200),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieRow(int exIndex, int serieIndex) {
    final serie = _exercicios[exIndex].series[serieIndex];

    int numeroSerieTrabalho = 0;
    for (int i = 0; i <= serieIndex; i++) {
      if (!_exercicios[exIndex].series[i].isAquecimento) {
        numeroSerieTrabalho++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // TIPO DE SÉRIE (Clicável para alternar entre AQ e Número)
          GestureDetector(
            onTap: () => _alternarTipoSerie(exIndex, serieIndex),
            child: Container(
              width: 36,
              height: 28,
              decoration: BoxDecoration(
                color: serie.isAquecimento
                    ? Colors.amber.withAlpha(30)
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: serie.isAquecimento
                    ? Border.all(color: Colors.amber.withAlpha(50))
                    : null,
              ),
              child: Center(
                child: serie.isAquecimento
                    ? const Text(
                        'AQ',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      )
                    : Text(
                        '$numeroSerieTrabalho',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ALVO INPUT (Reps ou Tempo)
          Expanded(child: _buildMiniInput(serie.alvo)),
          const SizedBox(width: 8),

          // CARGA INPUT
          Expanded(child: _buildMiniInput(serie.carga)),
          const SizedBox(width: 8),

          // DESCANSO INPUT
          Expanded(child: _buildMiniInput(serie.descanso)),
          const SizedBox(width: 8),

          // REMOVER SÉRIE
          GestureDetector(
            onTap: () => _removerSerie(exIndex, serieIndex),
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cria aqueles inputs minimalistas da tabela
  Widget _buildMiniInput(String initialValue) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withAlpha(150),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(13))),
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExerciciosLibraryPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Adicionar Exercício',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
