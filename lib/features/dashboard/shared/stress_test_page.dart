import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _addLog('🚀 INICIANDO TESTE DE FLUXO PESADO');

    try {
      // 1. CRIAR ALUNO
      final email = 'stress_${DateTime.now().millisecondsSinceEpoch}@test.com';
      _addLog('Passo 1: Criando aluno ($email)...');
      await _alunoService.salvarAluno('Stress', 'Test', email);
      
      final alunoSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      final alunoId = alunoSnap.docs.first.id;
      _addLog('✅ Aluno criado com ID: $alunoId');

      // 2. ABRIR STREAM (Simula entrada no perfil)
      _addLog('Passo 2: Abrindo Stream Reativa...');
      _profileSub = _alunoService.getAlunoPerfilCompletoStream(alunoId).listen((data) {
        _lastProfileData = data;
        _addLog('📺 [STREAM UPDATE] Rotina: ${data.rotinaAtiva?['nome'] ?? 'Nenhuma'}');
      });

      // 3. CRIAR ROTINA PESADA (Simula Personal montando treino do zero)
      _addLog('Passo 3: Criando Rotina com 3 sessões e 15 exercícios...');
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
      _addLog('✅ Rotina V1 criada em ${stopwatch.elapsedMilliseconds}ms');

      // 4. SIMULAR NAVEGAÇÃO (Pequeno delay)
      _addLog('Passo 4: Simulando navegação entre telas (2s wait)...');
      await Future.delayed(const Duration(seconds: 2));

      // 5. ATUALIZAÇÃO LEVE (Teste de sanidade do cano de upload)
      _addLog('Passo 5: Editando Rotina (MÍNIMO POSSÍVEL)...');
      
      // Enviamos apenas 1 sessão com 1 exercício para ver se o gRPC aceita o upload
      final sessoesMinimas = [{
        'nome': 'Treino Mínimo',
        'diaSemana': 'Segunda',
        'exercicios': [{
          'nome': 'Exercicio de Teste',
          'series': [{'carga': '1kg', 'alvo': '1', 'descanso': '0s', 'tipo': 'trabalho'}]
        }]
      }];

      await _rotinaService.atualizarRotina(
        rotinaId: rotinaId,
        nome: 'Rotina de Stress FINAL',
        objetivo: 'Teste Mínimo',
        sessoes: sessoesMinimas,
      );
      _addLog('✅ Rotina enviada (Upload rápido)');

      // 6. AGUARDAR REATIVIDADE
      _addLog('Passo 6: Aguardando reatividade no Stream...');
      int waitLimit = 0;
      
      // Listener temporário para diagnóstico de reatividade
      final diagSub = FirebaseFirestore.instance.snapshotsInSync().listen((_) {
        debugPrint('[STRESS-DIAG] SNAPSHOTS IN SYNC: Servidor confirmou o dado.');
      });

      while (waitLimit < 60) {
        final currentNome = _lastProfileData?.rotinaAtiva?['nome'];
        debugPrint('[STRESS-DEBUG] Esperando "Rotina de Stress FINAL". Atual: $currentNome');
        
        if (currentNome == 'Rotina de Stress FINAL') break;
        
        await Future.delayed(const Duration(seconds: 1));
        waitLimit++;
      }
      
      diagSub.cancel();

      if (waitLimit < 60) {
        _addLog('🏆 TESTE CONCLUÍDO COM SUCESSO!');
      } else {
        _addLog('❌ FALHA: O stream não atualizou após 60 segundos.');
        _addLog('DICA: Verifique se o log mostra "SNAPSHOTS IN SYNC".');
      }

    } catch (e) {
      _addLog('💥 ERRO CRÍTICO: $e');
    } finally {
      await _profileSub?.cancel();
      setState(() => _isRunning = false);
      _addLog('⏱️ Tempo total de execução: ${stopwatch.elapsed.inSeconds}s');
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
        actions: [
          if (!_isRunning)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
              onPressed: _runHeavyFlow,
            )
        ],
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
                  const Text(
                    'Este teste criará um aluno real e disparará múltiplas escritas pesadas para validar se o seu gRPC trava.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_isRunning)
                    const CircularProgressIndicator(color: AppColors.primary)
                  else
                    ElevatedButton(
                      onPressed: _runHeavyFlow,
                      child: const Text('EXECUTAR FLUXO PESADO'),
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
                final isError = log.contains('❌') || log.contains('💥');
                final isSuccess = log.contains('🏆') || log.contains('✅');
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isError ? Colors.redAccent : (isSuccess ? Colors.greenAccent : Colors.white60),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}