import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/services/rotina_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../alunos/shared/models/aluno_perfil_data.dart';

class StressTestPage extends StatefulWidget {
  const StressTestPage({super.key});

  @override
  State<StressTestPage> createState() => _StressTestPageState();
}

class _StressTestPageState extends State<StressTestPage> {
  final AlunoService _alunoService = AlunoService();
  final RotinaService _rotinaService = RotinaService();
  final List<String> _logs = [];
  bool _isRunning = false;
  
  StreamSubscription? _profileSub;
  AlunoPerfilData? _lastProfileData;

  void _addLog(String msg) {
    final time = DateTime.now().toString().split(' ').last.substring(0, 8);
    setState(() {
      _logs.insert(0, '[$time] $msg');
    });
    debugPrint('[STRESS-TEST] $msg');
  }

  Future<void> _runHeavyFlow() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    final stopwatch = Stopwatch()..start();
    _addLog('🚀 INICIANDO TESTE NO SUPABASE');

    try {
      // 1. CRIAR ALUNO
      final email = 'stress_${DateTime.now().millisecondsSinceEpoch}@test.com';
      _addLog('Passo 1: Criando aluno ($email)...');
      await _alunoService.salvarAluno('Stress', 'Test', email);
      
      final alunoRes = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('email', email)
          .single();
      final alunoId = alunoRes['id'];
      _addLog('✅ Aluno criado com ID: $alunoId');

      // 2. ABRIR STREAM
      _addLog('Passo 2: Abrindo Stream Reativa...');
      _profileSub = _alunoService.getAlunoPerfilCompletoStream(alunoId).listen((data) {
        _lastProfileData = data;
        _addLog('📺 [STREAM UPDATE] Rotina: ${data.rotinaAtiva?['nome'] ?? 'Nenhuma'}');
      });

      // 3. CRIAR ROTINA
      _addLog('Passo 3: Criando Rotina...');
      final sessoesIniciais = List.generate(3, (sIdx) => {
        'nome': 'Treino $sIdx',
        'diaSemana': 'Segunda',
        'exercicios': List.generate(5, (eIdx) => {
          'nome': 'Exercicio $eIdx',
          'series': List.generate(4, (serIdx) => {
            'tipo': 'trabalho',
            'alvo': '12',
            'carga': '20kg',
            'descanso': '60s'
          })
        })
      });

      final String rotinaId = await _rotinaService.criarRotina(
        alunoId: alunoId,
        nome: 'Rotina de Stress V1',
        objetivo: 'Testar Limites',
        tipoVencimento: 'data',
        sessoes: sessoesIniciais,
      );
      _addLog('✅ Rotina V1 criada.');

      // 4. ATUALIZAÇÃO
      _addLog('Passo 4: Atualizando Rotina...');
      await _rotinaService.atualizarRotina(
        rotinaId: rotinaId,
        nome: 'Rotina de Stress FINAL',
        objetivo: 'Teste Mínimo',
        sessoes: [],
      );
      _addLog('✅ Rotina enviada.');

      _addLog('🏆 TESTE CONCLUÍDO!');
    } catch (e) {
      _addLog('💥 ERRO: $e');
    } finally {
      await _profileSub?.cancel();
      setState(() => _isRunning = false);
      _addLog('⏱️ Tempo total: ${stopwatch.elapsed.inSeconds}s');
      stopwatch.stop();
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnóstico de Stress'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(10)),
              ),
              child: Column(
                children: [
                  if (_isRunning)
                    const CircularProgressIndicator(color: AppColors.primary)
                  else
                    ElevatedButton(
                      onPressed: _runHeavyFlow,
                      child: const Text('EXECUTAR TESTE SUPABASE'),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Text(
                  log,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white60),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}