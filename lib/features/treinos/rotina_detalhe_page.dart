import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import 'configurar_exercicios_page.dart';
import 'models/exercicio_model.dart';
import 'widgets/rotina_modern_input.dart';
import 'widgets/rotina_input_decoration.dart';

class _TreinoData {
  String nome;
  String? diaSemana;
  String? orientacoes;
  List<ExercicioItem> exercicios;

  _TreinoData({
    required this.nome,
    this.diaSemana,
    this.orientacoes,
    List<ExercicioItem>? exercicios,
  }) : exercicios = exercicios ?? [];
}

class RotinaDetalhePage extends StatefulWidget {
  final Map<String, dynamic>? rotinaData;
  final String? rotinaId;
  final String? alunoId;
  final String? alunoNome;

  const RotinaDetalhePage({
    super.key,
    this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
  });

  @override
  State<RotinaDetalhePage> createState() => _RotinaDetalhePageState();
}

class _RotinaDetalhePageState extends State<RotinaDetalhePage> {
  final List<String> _sugestoesObjetivo = ['Hipertrofia', 'Emagrecimento', 'Força', 'RML', 'Cardio'];
  late TextEditingController nomeCtrl;
  late TextEditingController objCtrl;
  String _tipoVencimento = 'sessoes';
  int _vencimentoSessoes = 20;
  DateTime _vencimentoData = DateTime.now().add(const Duration(days: 30));


  final List<_TreinoData> _treinos = [];
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos os controladores com os dados vindos do Firebase ou vazios
    nomeCtrl = TextEditingController(text: widget.rotinaData?['nome'] ?? '');
    objCtrl = TextEditingController(text: widget.rotinaData?['objetivo'] ?? '');

    _preencherDados();
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    objCtrl.dispose();
    super.dispose();
  }

  void _preencherDados() {
    if (widget.rotinaData != null) {
      _tipoVencimento = widget.rotinaData!['tipoVencimento'] ?? 'data';

      if (_tipoVencimento == 'sessoes') {
        _vencimentoSessoes = widget.rotinaData!['vencimentoSessoes'] ?? 20;
      } else {
        if (widget.rotinaData!['dataVencimento'] != null) {
          _vencimentoData = (widget.rotinaData!['dataVencimento'] as Timestamp).toDate();
        }
      }


      List<dynamic> sessoesRaw = widget.rotinaData!['sessoes'] ?? [];
      for (var sessao in sessoesRaw) {
        List<ExercicioItem> exerciciosList = [];
        for (var ex in (sessao['exercicios'] ?? [])) {
          List<SerieItem> seriesList = [];
          for (var s in (ex['series'] ?? [])) {
            seriesList.add(
              SerieItem(
                tipo: _parseTipoSerie(s['tipo']),
                alvo: s['alvo'] ?? '10',
                carga: s['carga'] ?? '-',
                descanso: s['descanso'] ?? '60s',
              ),
            );
          }

          List<String> grupos = ['Geral'];
          final rawGrupo = ex['grupoMuscular'];
          if (rawGrupo is String) {
            grupos = rawGrupo.split(',').map((e) => e.trim()).toList();
          } else if (rawGrupo is List) {
            grupos = List<String>.from(rawGrupo);
          }

          exerciciosList.add(
            ExercicioItem(
              nome: ex['nome'] ?? 'Exercício',
              grupoMuscular: grupos,
              tipoAlvo: ex['tipoAlvo'] ?? 'Reps',
              imagemUrl: ex['imagemUrl'],
              personalId: ex['personalId'],
              series: seriesList,
            ),
          );
        }
        _treinos.add(
          _TreinoData(
            nome: sessao['nome'],
            diaSemana: sessao['diaSemana'],
            orientacoes: sessao['orientacoes'],
            exercicios: exerciciosList,
          ),
        );
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _exibirModalInfo(context);
      });
    }
  }

  TipoSerie _parseTipoSerie(String? tipo) {
    if (tipo == 'aquecimento' || tipo == 'TipoSerie.aquecimento') return TipoSerie.aquecimento;
    if (tipo == 'feeder' || tipo == 'TipoSerie.feeder') return TipoSerie.feeder;
    return TipoSerie.trabalho;
  }

  void _exibirModalInfo(BuildContext context) {
    // Estados temporários para o modal
    String tipoTemp = _tipoVencimento;
    int sessoesTemp = _vencimentoSessoes;
    DateTime dataTemp = _vencimentoData;

    // Usamos os controllers existentes (nomeCtrl e objCtrl) diretamente
    // ou criamos temporários se quisermos "cancelar" a edição.
    // Aqui usaremos os reais para persistência imediata.

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para o teclado não cobrir
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle de arrastar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Configurações da Planilha',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),

              // 1. NOME DA PLANILHA
              RotinaModernInput(
                label: 'NOME DA PLANILHA',
                icon: Icons.edit_note,
                child: TextField(
                  controller: nomeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: rotinaInputDecoration(hintText: 'Ex: Protocolo Y'),
                ),
              ),
              const SizedBox(height: 20),

              // 2. OBJETIVO COM CHIPS DE SUGESTÃO
              RotinaModernInput(
                label: 'OBJETIVO PRINCIPAL',
                icon: Icons.ads_click,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: objCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: rotinaInputDecoration(hintText: 'Ex: Hipertrofia Máxima'),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _sugestoesObjetivo.map((obj) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(obj),
                            selected: objCtrl.text == obj,
                            onSelected: (selected) {
                              if (selected) setStateModal(() => objCtrl.text = obj);
                            },
                            backgroundColor: AppTheme.surfaceLight,
                            selectedColor: AppTheme.primary,
                            labelStyle: TextStyle(
                              color: objCtrl.text == obj ? Colors.black : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. TIPO DE VENCIMENTO (Sessões vs Data)
              const Text('VALIDADE DA PLANILHA',
                  style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabOption(setStateModal, 'Sessões', 'sessoes', tipoTemp),
                    _buildTabOption(setStateModal, 'Data Fixa', 'data', tipoTemp),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. INPUT DINÂMICO DE VENCIMENTO
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: tipoTemp == 'sessoes'
                    ? TextField(
                  key: const ValueKey('inputSessoes'),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: rotinaInputDecoration(
                    hintText: 'Quantas sessões de treino?',

                  ),
                  onChanged: (v) => sessoesTemp = int.tryParse(v) ?? 20,
                )
                    : ListTile(
                  key: const ValueKey('inputData'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  tileColor: AppTheme.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.calendar_month, color: AppTheme.primary),
                  title: const Text('Vence em:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  trailing: Text(DateFormat('dd/MM/yyyy').format(dataTemp),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataTemp,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setStateModal(() => dataTemp = picked);
                  },
                ),
              ),

              const SizedBox(height: 32),

              // BOTÃO CONFIRMAR
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tipoVencimento = tipoTemp;
                      _vencimentoSessoes = sessoesTemp;
                      _vencimentoData = dataTemp;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('SALVAR CONFIGURAÇÕES',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Widget auxiliar para as abas de Sessão/Data
  Widget _buildTabOption(StateSetter setStateModal, String label, String value, String current) {
    bool isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setStateModal(() => _tipoVencimento = value), // Note: use tipoTemp se estiver usando local
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.background : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : Colors.white38,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _exibirModalSessao({int? index}) {
    final bool isEditing = index != null;
    final sNomeCtrl = TextEditingController(text: isEditing ? _treinos[index].nome : null);
    String? diaSemana = isEditing ? _treinos[index].diaSemana : null;
    final orientCtrl = TextEditingController(text: isEditing ? _treinos[index].orientacoes : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(isEditing ? 'Editar Sessão' : 'Nova Sessão', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            RotinaModernInput(
              label: 'NOME DO TREINO',
              icon: Icons.fitness_center,
              child: TextField(controller: sNomeCtrl, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: rotinaInputDecoration(hintText: 'Ex: Push, Pull...')),
            ),
            const SizedBox(height: 24),
            RotinaModernInput(
              label: 'DIA DA SEMANA',
              icon: Icons.calendar_today,
              child: DropdownButtonFormField<String>(
                initialValue: diaSemana,
                dropdownColor: AppTheme.surfaceLight,
                items: ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => diaSemana = v,
                decoration: rotinaInputDecoration(hintText: 'Sem dia fixo'),
              ),
            ),
            const SizedBox(height: 24),
            RotinaModernInput(
              label: 'NOTAS',
              icon: Icons.notes,
              child: TextField(controller: orientCtrl, maxLines: 3, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: rotinaInputDecoration(hintText: 'Ex: Aquecer...')),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final newName = sNomeCtrl.text.trim().isEmpty ? 'Treino ${String.fromCharCode(65 + _treinos.length)}' : sNomeCtrl.text.trim();
                setState(() {
                  if (isEditing) {
                    _treinos[index].nome = newName;
                    _treinos[index].diaSemana = diaSemana;
                    _treinos[index].orientacoes = orientCtrl.text.trim();
                  } else {
                    _treinos.add(_TreinoData(nome: newName, diaSemana: diaSemana, orientacoes: orientCtrl.text.trim()));
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(isEditing ? 'Salvar' : 'Adicionar', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _excluirTreino(int index) {
    setState(() {
      _treinos.removeAt(index);
    });
  }

  Future<bool> _salvarRotinaCompleta() async {
    final String nomeParaSalvar = nomeCtrl.text.trim();
    final String objetivoParaSalvar = objCtrl.text.trim();

    if (nomeParaSalvar.isEmpty || _treinos.isEmpty) return false;

    try {
      // 1. Mapeamento das sessões para JSON
      List<Map<String, dynamic>> sessoesJson = _treinos.map((t) => {
        'nome': t.nome,
        'diaSemana': t.diaSemana ?? '',
        'orientacoes': t.orientacoes ?? '',
        'exercicios': t.exercicios.map((ex) => {
          'nome': ex.nome,
          'grupoMuscular': ex.grupoMuscular,
          'tipoAlvo': ex.tipoAlvo,
          'series': ex.series.map((s) => {
            'tipo': s.tipo.name,
            'alvo': s.alvo,
            'carga': s.carga,
            'descanso': s.descanso
          }).toList(),
        }).toList(),
      }).toList();

      print('--- [DATABASE] SALVANDO COM TIPO: $_tipoVencimento ---');

      // 2. Chamada do serviço tratando as duas opções
      if (widget.rotinaId != null) {
        // EDIÇÃO
        await RotinaService().atualizarRotina(
          rotinaId: widget.rotinaId!,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: _tipoVencimento, // Passando o tipo escolhido
          sessoesAlvo: _tipoVencimento == 'sessoes' ? _vencimentoSessoes : null,
          dataVencimento: _tipoVencimento == 'data' ? _vencimentoData : null,
        );
      } else {
        // CRIAÇÃO NOVA
        await RotinaService().criarRotina(
          alunoId: widget.alunoId,
          nome: nomeParaSalvar,
          objetivo: objetivoParaSalvar,
          sessoes: sessoesJson,
          tipoVencimento: _tipoVencimento, // Passando o tipo escolhido
          sessoesAlvo: _tipoVencimento == 'sessoes' ? _vencimentoSessoes : null,
          dataVencimento: _tipoVencimento == 'data' ? _vencimentoData : null,
        );
      }

      return true;
    } catch (e) {
      print('Erro ao salvar rotina: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTemplate = widget.rotinaData != null && widget.rotinaData!['alunoId'] == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Tenta salvar ao detectar o gesto de voltar do sistema
        bool salvo = await _salvarRotinaCompleta();
        if (salvo && context.mounted){
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: CupertinoButton(
            padding: const EdgeInsets.only(left: 8),
            child: const Icon(
                CupertinoIcons.back,
                color: AppTheme.textPrimary,
                size: 24
            ),
            onPressed: () async {
              bool salvo = await _salvarRotinaCompleta();
              if (salvo && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('Gerenciar Planilha', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder(
                                valueListenable: nomeCtrl,
                                builder: (context, value, _) {
                                  return Text(value.text.isEmpty ? 'Nova Rotina' : value.text,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w900));
                                }
                            ),
                            const SizedBox(height: 12),
                            ValueListenableBuilder(
                                valueListenable: objCtrl,
                                builder: (context, value, _) {
                                  return Text(value.text.isEmpty ? 'Defina o objetivo' : value.text,
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w500));
                                }
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text('x semanas', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => _exibirModalInfo(context), icon: const Icon(CupertinoIcons.ellipsis_vertical, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (isTemplate) _buildTemplateBadge(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('LISTA DE TREINOS', style: AppTheme.textSectionHeaderDark),
                      if (_treinos.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _isReordering = !_isReordering),
                          icon: Icon(_isReordering ? Icons.check : Icons.swap_vert),
                          label: Text(_isReordering ? 'Concluir' : 'Reordenar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_treinos.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Text('Nenhuma sessão', style: TextStyle(color: AppTheme.textSecondary))))
                  else if (_isReordering)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _treinos.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _treinos.removeAt(oldIndex);
                          _treinos.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) => _buildSessaoCard(_treinos[index], index, isReordering: true, key: ValueKey(_treinos[index])),
                    )
                  else
                    ..._treinos.asMap().entries.map((entry) => _buildSessaoCard(entry.value, entry.key, isReordering: false, key: ValueKey(entry.value))),
                  const SizedBox(height: 8),
                  if (!_isReordering) _buildAddSessaoButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS DE WIDGETS AUXILIARES ---

  Widget _buildAddSessaoButton() {
    return InkWell(
      onTap: () => _exibirModalSessao(),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: Colors.black), SizedBox(width: 8), Text('Novo Treino', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildTemplateBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.primary.withAlpha(15), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.primary.withAlpha(30))),
      child: const Row(children: [Icon(Icons.collections_bookmark, color: AppTheme.primary, size: 18), SizedBox(width: 12), Text('Template de Biblioteca', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _buildSessaoCard(_TreinoData sessao, int index, {required bool isReordering, required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge), side: BorderSide(color: Colors.white.withAlpha(14))),
        child: InkWell(
          onTap: isReordering ? null : () async {
            final dynamic result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigurarExerciciosPage(nomeTreino: sessao.nome, exercicios: sessao.exercicios))
            );

            if (mounted && result is String) {
              setState(() {
                sessao.nome = result;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: AppTheme.surfaceLight, child: Text(String.fromCharCode(65 + index), style: const TextStyle(color: AppTheme.primary))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sessao.nome, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)), Text('${sessao.exercicios.length} exercícios', style: const TextStyle(color: AppTheme.textSecondary))])),
                if (isReordering) const Icon(Icons.drag_indicator, color: AppTheme.textSecondary)
                else PopupMenuButton(
                  onSelected: (v) { if (v == 'edit') _exibirModalSessao(index: index); if (v == 'delete') _excluirTreino(index); },
                  itemBuilder: (c) => [const PopupMenuItem(value: 'edit', child: Text('Editar')), const PopupMenuItem(value: 'delete', child: Text('Excluir'))],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}