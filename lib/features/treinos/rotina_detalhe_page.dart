import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'criar_rotina_page.dart'; // <-- IMPORTA A TELA DE EDIÇÃO

class RotinaDetalhePage extends StatelessWidget {
  final Map<String, dynamic> rotinaData;
  final String? rotinaId; // <-- ID DA ROTINA
  final String? alunoId; // <-- ID DO ALUNO (Se existir)
  final String? alunoNome; // <-- NOME DO ALUNO (Se existir)

  const RotinaDetalhePage({
    super.key,
    required this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = rotinaData['nome'] ?? 'Rotina';
    final objetivo = rotinaData['objetivo'] ?? 'Sem objetivo definido';
    final List<dynamic> sessoes = rotinaData['sessoes'] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Visão Geral', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          // --- NOVO: BOTÃO DE EDITAR NA APP BAR ---
          if (rotinaId != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              tooltip: 'Editar Rotina',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CriarRotinaPage(
                      rotinaId: rotinaId,
                      rotinaData: rotinaData,
                      alunoId: alunoId,
                      alunoNome: alunoNome,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              objetivo,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'SESSÕES DE TREINO',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            if (sessoes.isEmpty)
              const Text(
                'Nenhuma sessão cadastrada.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ...sessoes.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> sessao =
                    entry.value as Map<String, dynamic>;
                String letra = String.fromCharCode(65 + index);
                return _buildSessaoCard(context, sessao, letra);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSessaoCard(
    BuildContext context,
    Map<String, dynamic> sessao,
    String letra,
  ) {
    List<dynamic> exercicios = sessao['exercicios'] ?? [];
    String nomeSessao = sessao['nome'] ?? 'Sessão $letra';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SessaoVisualizerPage(sessaoData: sessao, letra: letra),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(13), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    letra,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeSessao,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercicios.length} exercícios',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary.withAlpha(150),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// --- TELA: VISUALIZADOR DE SESSÃO (READ-ONLY) REFATORADA ---
// ==============================================================
class SessaoVisualizerPage extends StatelessWidget {
  final Map<String, dynamic> sessaoData;
  final String letra;

  const SessaoVisualizerPage({
    super.key,
    required this.sessaoData,
    required this.letra,
  });

  @override
  Widget build(BuildContext context) {
    String nomeSessao = sessaoData['nome'] ?? 'Treino $letra';
    List<dynamic> exercicios = sessaoData['exercicios'] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          nomeSessao,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: exercicios.isEmpty
          ? const Center(
              child: Text(
                'Nenhum exercício nesta sessão.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercicios.length,
              itemBuilder: (context, index) {
                var ex = exercicios[index];
                return _buildExercicioVisualizerCard(ex);
              },
            ),
    );
  }

  Widget _buildExercicioVisualizerCard(Map<String, dynamic> ex) {
    List<dynamic> series = ex['series'] ?? [];
    String tipoAlvo = ex['tipoAlvo'] ?? 'Reps';

    final aquecimentoSeries = series
        .where((s) => s['tipo'] == 'aquecimento')
        .toList();
    final feederSeries = series.where((s) => s['tipo'] == 'feeder').toList();
    final trabalhoSeries = series
        .where((s) => s['tipo'] == 'trabalho')
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
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
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex['nome'] ?? 'Exercício',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ex['grupoMuscular'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (ex['observacao'] != null &&
              ex['observacao'].toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.primary.withAlpha(150),
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  ex['observacao'],
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(220),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),

          if (series.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 36,
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
                        child: Text(
                          tipoAlvo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (aquecimentoSeries.isNotEmpty) ...[
                    _buildSectionTitle('Aquecimento', Colors.amber),
                    ...aquecimentoSeries.asMap().entries.map(
                      (entry) =>
                          _buildSerieReadOnlyRow(entry.value, entry.key + 1),
                    ),
                  ],

                  if (feederSeries.isNotEmpty) ...[
                    _buildSectionTitle('Feeder Sets', Colors.blueAccent),
                    ...feederSeries.asMap().entries.map(
                      (entry) =>
                          _buildSerieReadOnlyRow(entry.value, entry.key + 1),
                    ),
                  ],

                  if (trabalhoSeries.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Séries de Trabalho',
                      AppTheme.textSecondary,
                    ),
                    ...trabalhoSeries.asMap().entries.map(
                      (entry) =>
                          _buildSerieReadOnlyRow(entry.value, entry.key + 1),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
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

  Widget _buildSerieReadOnlyRow(Map<String, dynamic> serie, int visualNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withAlpha(100),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$visualNumber',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildReadonlyBox(serie['alvo'] ?? '-')),
          const SizedBox(width: 8),
          Expanded(child: _buildReadonlyBox(serie['carga'] ?? '-')),
          const SizedBox(width: 8),
          Expanded(child: _buildReadonlyBox(serie['descanso'] ?? '-')),
        ],
      ),
    );
  }

  Widget _buildReadonlyBox(String text) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
