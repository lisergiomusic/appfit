import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:appfit/features/treinos/treinos_page.dart';
import 'package:appfit/features/treinos/rotina_detalhe_page.dart';
import 'package:appfit/core/services/aluno_service.dart';
import 'package:appfit/core/services/rotina_service.dart';

class MockRotinaServiceReal extends Mock implements RotinaService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late AlunoService alunoService;
  late RotinaService rotinaService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true);
    alunoService = AlunoService(firestore: fakeFirestore, auth: mockAuth);
    rotinaService = RotinaService(firestore: fakeFirestore, auth: mockAuth);
  });

  Widget createWidgetUnderTest({RotinaService? customRotinaService, String? alunoId}) {
    return MaterialApp(
      home: TreinosPage(
        alunoId: alunoId,
        alunoService: alunoService,
        rotinaService: customRotinaService ?? rotinaService,
      ),
    );
  }

  group('TreinosPage', () {
    testWidgets('Deve exibir estado vazio quando não há rotinas', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Biblioteca vazia'), findsOneWidget);
    });

    testWidgets('Deve navegar para RotinaDetalhePage ao clicar no botão adicionar', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      await tester.pumpWidget(createWidgetUnderTest(alunoId: null));
      await tester.pumpAndSettle();

      final addButton = find.byIcon(CupertinoIcons.add);
      await tester.tap(addButton);
      
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
    });
  });

  group('RotinaDetalhePage Logic', () {
    testWidgets('Deve permitir criar rotina com sessões', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      final mockRotinaService = MockRotinaServiceReal();
      
      // Mock da criação de rotina.
      // Assinatura: criarRotina({String? alunoId, required String nome, required String objetivo, required List<Map<String, dynamic>> sessoes, ...})
      // NOTA: No código atual, nome, objetivo e sessoes são posicionais se não forem 'named'. 
      // Vamos checar a assinatura real no serviço.
      
      when(() => mockRotinaService.criarRotina(
        alunoId: any(named: 'alunoId'),
        nome: any(named: 'nome'),
        objetivo: any(named: 'objetivo'),
        sessoes: any(named: 'sessoes'),
        tipoVencimento: any(named: 'tipoVencimento'),
        sessoesAlvo: any(named: 'sessoesAlvo'),
        dataVencimento: any(named: 'dataVencimento'),
      )).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: RotinaDetalhePage(
            rotinaService: mockRotinaService,
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Treino de Força');
      await tester.enterText(fields.at(1), 'Ganho de massa');
      await tester.enterText(fields.at(2), '20');
      await tester.pump();
      
      final salvarBtn = find.text('Salvar');
      await tester.tap(salvarBtn.first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Gerenciar Planilha'), findsOneWidget);

      await tester.tap(find.text('Nova sessão'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField).at(0), 'Treino A');
      await tester.pump();
      
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Treino A'), findsOneWidget);

      // Salva voltando (PopScope)
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      verify(() => mockRotinaService.criarRotina(
        alunoId: any(named: 'alunoId'),
        nome: 'Treino de Força',
        objetivo: 'Ganho de massa',
        sessoes: any(named: 'sessoes'),
        tipoVencimento: any(named: 'tipoVencimento'),
        sessoesAlvo: any(named: 'sessoesAlvo'),
        dataVencimento: any(named: 'dataVencimento'),
      )).called(1);
    });
  });
}
