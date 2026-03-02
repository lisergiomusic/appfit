import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'exercicios_library_page.dart';

// --- MODELOS DE DADOS REFINADOS ---
enum TipoSerie { aquecimento, feeder, trabalho }

class SerieItem {
  TipoSerie tipo;
  String alvo;
  String carga;
  String descanso;

  SerieItem({
    this.tipo = TipoSerie.trabalho,
    this.alvo = '10',
    this.carga = '-',
    this.descanso = '60s',
  });
}

class ExercicioItem {
  String nome;
  String grupoMuscular;
  String observacao;
  String tipoAlvo;
  String? imagemUrl;
  List<SerieItem> series;

  ExercicioItem({
    required this.nome,
    this.grupoMuscular = 'Peito',
    this.observacao = '',
    this.tipoAlvo = 'Reps',
    this.imagemUrl,
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
  final List<ExercicioItem> _exercicios = [
    ExercicioItem(
      nome: 'Supino Reto com Barra',
      grupoMuscular: 'Peito • Barra',
      observacao: 'Focar na cadência 3010. Não esticar totalmente o cotovelo.',
      tipoAlvo: 'Reps',
      series: [
        SerieItem(
          tipo: TipoSerie.aquecimento,
          alvo: '15',
          carga: '10kg',
          descanso: '45s',
        ),
        SerieItem(
          tipo: TipoSerie.feeder,
          alvo: '3',
          carga: '26kg',
          descanso: '60s',
        ),
        SerieItem(
          tipo: TipoSerie.trabalho,
          alvo: '12',
          carga: '30kg',
          descanso: '90s',
        ),
        SerieItem(
          tipo: TipoSerie.trabalho,
          alvo: '10',
          carga: '35kg',
          descanso: '90s',
        ),
      ],
    ),
    ExercicioItem(
      nome: 'Prancha Isométrica',
      grupoMuscular: 'Core • Peso Corporal',
      observacao: '',
      tipoAlvo: 'Tempo',
      series: [
        SerieItem(
          tipo: TipoSerie.trabalho,
          alvo: '60s',
          carga: '-',
          descanso: '30s',
        ),
        SerieItem(
          tipo: TipoSerie.trabalho,
          alvo: '60s',
          carga: '-',
          descanso: '30s',
        ),
      ],
    ),
  ];

  Future<void> _adicionarSerie(int exIndex) async {
    final TipoSerie? tipoEscolhido = await showModalBottomSheet<TipoSerie>(
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
                      child: Icon(Icons.whatshot, color: Colors.amber),
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
                  onTap: () => Navigator.pop(context, TipoSerie.aquecimento),
                ),
                const SizedBox(height: 8),

                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueAccent.withAlpha(50),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.flash_on, color: Colors.blueAccent),
                    ),
                  ),
                  title: const Text(
                    'Feeder Set',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Aproximação de carga sem gerar fadiga',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, TipoSerie.feeder),
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
                  onTap: () => Navigator.pop(context, TipoSerie.trabalho),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (tipoEscolhido != null) {
      setState(() {
        String alvoToClone = '10';
        String cargaToClone = '-';
        String descansoToClone = '60s';

        // Tenta clonar a última série do mesmo tipo, ou a última geral
        if (_exercicios[exIndex].series.isNotEmpty) {
          final ultimaSerie = _exercicios[exIndex].series.lastWhere(
            (s) => s.tipo == tipoEscolhido,
            orElse: () => _exercicios[exIndex].series.last,
          );
          alvoToClone = ultimaSerie.alvo;
          cargaToClone = ultimaSerie.carga;
          descansoToClone = ultimaSerie.descanso;
        }

        _exercicios[exIndex].series.add(
          SerieItem(
            tipo: tipoEscolhido,
            alvo: alvoToClone,
            carga: cargaToClone,
            descanso: descansoToClone,
          ),
        );
      });
    }
  }

  void _removerSerie(int exIndex, int realIndex) {
    setState(() {
      _exercicios[exIndex].series.removeAt(realIndex);
    });
  }

  void _alternarTipoSerie(int exIndex, int realIndex) {
    setState(() {
      final serie = _exercicios[exIndex].series[realIndex];
      if (serie.tipo == TipoSerie.trabalho) {
        serie.tipo = TipoSerie.aquecimento;
      } else if (serie.tipo == TipoSerie.aquecimento) {
        serie.tipo = TipoSerie.feeder;
      } else {
        serie.tipo = TipoSerie.trabalho;
      }
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

    // Agrupamento das séries por tipo (com os seus índices reais mantidos)
    final aquecimentoSeries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.aquecimento)
        .toList();
    final feederSeries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.feeder)
        .toList();
    final trabalhoSeries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.trabalho)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CABEÇALHO DO EXERCÍCIO
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    image: ex.imagemUrl != null
                        ? DecorationImage(
                            image: NetworkImage(ex.imagemUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: ex.imagemUrl == null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: AppTheme.textSecondary.withAlpha(100),
                              size: 28,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(100),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        )
                      : const SizedBox(),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ex.grupoMuscular,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 2. CAMPO DE OBSERVAÇÃO
          if (ex.observacao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes,
                    color: AppTheme.textSecondary.withAlpha(150),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ex.observacao,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 3. TABELA DE SÉRIES (CABEÇALHO ÚNICO)
          if (ex.series.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 40,
                    child: Text(
                      'Série',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: InkWell(
                        onTap: () => setState(
                          () => ex.tipoAlvo = ex.tipoAlvo == 'Reps'
                              ? 'Tempo'
                              : 'Reps',
                        ),
                        borderRadius: BorderRadius.circular(6),
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
                                ex.tipoAlvo,
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
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
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Carga',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pausa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

          // 4. SUBDIVISÕES RENDEREIZADAS DINAMICAMENTE
          if (aquecimentoSeries.isNotEmpty) ...[
            _buildSectionTitle('Aquecimento', Colors.amber),
            ...aquecimentoSeries.asMap().entries.map(
              (entry) => _buildSerieRow(
                exIndex,
                entry.value.key,
                entry.value.value,
                entry.key + 1,
                Colors.amber,
              ),
            ),
          ],

          if (feederSeries.isNotEmpty) ...[
            _buildSectionTitle('Feeder Sets', Colors.blueAccent),
            ...feederSeries.asMap().entries.map(
              (entry) => _buildSerieRow(
                exIndex,
                entry.value.key,
                entry.value.value,
                entry.key + 1,
                Colors.blueAccent,
              ),
            ),
          ],

          if (trabalhoSeries.isNotEmpty) ...[
            _buildSectionTitle('Séries de Trabalho', AppTheme.textSecondary),
            ...trabalhoSeries.asMap().entries.map(
              (entry) => _buildSerieRow(
                exIndex,
                entry.value.key,
                entry.value.value,
                entry.key + 1,
                Colors.white,
              ),
            ),
          ],

          const SizedBox(height: 8),

          // 5. BOTÃO ADICIONAR SÉRIE
          TextButton(
            onPressed: () => _adicionarSerie(exIndex),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppTheme.primary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Adicionar Série',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Design limpo para o título da subdivisão
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: color.withAlpha(200),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieRow(
    int exIndex,
    int realIndex,
    SerieItem serie,
    int visualNumber,
    Color themeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // TIPO DE SÉRIE (Apenas o número, sem letras!)
          GestureDetector(
            onTap: () => _alternarTipoSerie(exIndex, realIndex),
            child: Container(
              width: 36,
              height: 28,
              decoration: BoxDecoration(
                color: themeColor == Colors.white
                    ? AppTheme.surfaceLight.withAlpha(100)
                    : themeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: themeColor != Colors.white
                    ? Border.all(color: themeColor.withAlpha(50))
                    : null,
              ),
              child: Center(
                child: Text(
                  '$visualNumber',
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // INPUTS SUTIS COM GRAVAÇÃO REAL DOS DADOS (onChanged)
          Expanded(
            child: _buildCleanInput(serie.alvo, (val) => serie.alvo = val),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCleanInput(serie.carga, (val) => serie.carga = val),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCleanInput(
              serie.descanso,
              (val) => serie.descanso = val,
            ),
          ),
          const SizedBox(width: 8),

          // BOTÃO REMOVER
          GestureDetector(
            onTap: () => _removerSerie(exIndex, realIndex),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.close,
                color: AppTheme.textSecondary.withAlpha(150),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Atualizado para TextFormField para poder gravar o que se digita
  Widget _buildCleanInput(String initialValue, ValueChanged<String> onChanged) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 9),
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
