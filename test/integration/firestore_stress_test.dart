import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../lib/core/config/firebase_options.dart';
import '../../lib/core/services/aluno_service.dart';
import '../../lib/core/services/rotina_service.dart';

/// TESTE DE INTEGRAÇÃO REAL COM FIRESTORE (SEM MOCKS)
/// 
/// Objetivo: Validar estabilidade da conexão, índices e reatividade sob fluxo pesado.
/// ATENÇÃO: Este teste usa o banco de dados real. Certifique-se de estar em ambiente de dev.
void main() {
  group('Stress Test - Fluxo Pesado de Personal', () {
    late AlunoService alunoService;
    late RotinaService rotinaService;
    final String testPersonalId = 'wbFNhTIQLYUCCse67k8G2VQ3ypl1'; // Seu ID de teste

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Logging ativado para capturar gRPC
      FirebaseFirestore.setLoggingEnabled(true);
      
      alunoService = AlunoService();
      rotinaService = RotinaService();
    });

    test('Carga e Reatividade: Criar aluno, rotina e validar stream instantâneo', () async {
      print('\n[STRESS-TEST] Iniciando fluxo pesado...');
      final stopwatch = Stopwatch()..start();

      // 1. Criar Aluno de Teste (Escrita)
      final String alunoEmail = 'test_stress_${DateTime.now().millisecondsSinceEpoch}@test.com';
      print('[STEP 1] Criando novo aluno: $alunoEmail');
      
      await alunoService.salvarAluno(
        'Stress', 
        'Test', 
        alunoEmail,
      );
      print('[STEP 1] Aluno criado em ${stopwatch.elapsedMilliseconds}ms');

      // 2. Localizar ID do Aluno criado
      final alunoSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: alunoEmail)
          .limit(1)
          .get();
      
      expect(alunoSnap.docs.isNotEmpty, true);
      final String alunoId = alunoSnap.docs.first.id;
      print('[STEP 2] ID capturado: $alunoId');

      // 3. Abrir Stream de Perfil (Início da Observação gRPC)
      print('[STEP 3] Abrindo Stream Reativa (Simulando entrada na tela de perfil)');
      final profileStream = alunoService.getAlunoPerfilCompletoStream(alunoId);
      
      Completer<void> updateCompleter = Completer<void>();
      int emissionCount = 0;
      String? currentRotinaNome;

      final subscription = profileStream.listen((data) {
        emissionCount++;
        currentRotinaNome = data.rotinaAtiva?['nome'];
        print('[STREAM] Emissão #$emissionCount | Rotina Ativa: $currentRotinaNome');
        
        if (currentRotinaNome == 'Rotina Editada via Stress Test') {
          if (!updateCompleter.isCompleted) updateCompleter.complete();
        }
      });

      // 4. Fluxo de Escrita Pesada (Criar Rotina Completa)
      print('[STEP 4] Criando Rotina Complexa...');
      await rotinaService.criarRotina(
        alunoId: alunoId,
        nome: 'Rotina Stress Inicial',
        objetivo: 'Testar gRPC',
        tipoVencimento: 'data',
        sessoes: [
          {
            'nome': 'Sessão A',
            'exercicios': List.generate(5, (i) => {
              'nome': 'Exercicio Stress $i',
              'series': [{'tipo': 'trabalho', 'alvo': '10', 'carga': '50kg', 'descanso': '60s'}]
            })
          }
        ],
      );
      print('[STEP 4] Rotina criada em ${stopwatch.elapsedMilliseconds}ms');

      // 5. Atualização Rápida (Simular edição e salvamento que causava o shimmer)
      print('[STEP 5] Disparando atualização imediata (Simulando save de Sessão + Rotina)...');
      
      // Busca ID da rotina criada
      final rotinaQuery = await FirebaseFirestore.instance
          .collection('rotinas')
          .where('alunoId', isEqualTo: alunoId)
          .where('ativa', isEqualTo: true)
          .get();
      
      final String rotinaId = rotinaQuery.docs.first.id;

      // UPDATE PESADO
      await rotinaService.atualizarRotina(
        rotinaId: rotinaId,
        nome: 'Rotina Editada via Stress Test',
        objetivo: 'Sucesso Total',
        sessoes: [
          {
            'nome': 'Sessão A Modificada',
            'exercicios': List.generate(8, (i) => { // Aumentando volume de dados
              'nome': 'Exercicio Novo $i',
              'series': List.generate(4, (j) => {'tipo': 'trabalho', 'alvo': '12', 'carga': '60kg'})
            })
          }
        ]
      );

      print('[STEP 5] Atualização enviada em ${stopwatch.elapsedMilliseconds}ms. Aguardando reatividade do stream...');

      // 6. Verificar se o Stream capturou a mudança sem travar
      try {
        await updateCompleter.future.timeout(Duration(seconds: 15));
        print('[SUCCESS] Reatividade validada! O Stream capturou a mudança de nome da rotina.');
      } on TimeoutException {
        print('[FAILURE] O Stream travou ou demorou mais de 15s para reagir.');
        fail('Deadlock de Stream detectado!');
      }

      // Limpeza
      await subscription.cancel();
      print('[CLEANUP] Teste finalizado. Tempo total: ${stopwatch.elapsed.inSeconds}s');
      stopwatch.stop();
    });
  });
}