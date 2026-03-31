import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:appfit/features/treinos/treinos_page.dart';
import 'package:appfit/features/treinos/rotina_detalhe_page.dart';
import 'package:appfit/core/services/aluno_service.dart';
import 'package:appfit/core/services/rotina_service.dart';

class MockRotinaService extends Mock implements RotinaService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late AlunoService alunoService;
  late MockRotinaService mockRotinaService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true);
    alunoService = AlunoService(firestore: fakeFirestore, auth: mockAuth);
    mockRotinaService = MockRotinaService();

    when(() => mockRotinaService.excluirRotina(any()))
        .thenAnswer((_) async {});
    when(() => mockRotinaService.renomearRotina(any(), any()))
        .thenAnswer((_) async {});
  });

  /// Insere uma rotina no Firestore fake e retorna seu id.
  Future<String> seedRotina(String nome) async {
    final ref = await fakeFirestore.collection('rotinas').add({
      'nome': nome,
      'objetivo': 'Ganho de massa',
      'sessoes': [],
      'ativa': true,
      'personalId': 'uid1',
      'alunoId': null,
      'tipoVencimento': 'sessoes',
      'vencimentoSessoes': 20,
    });
    return ref.id;
  }

  Widget buildPage({String? alunoId}) {
    return MaterialApp(
      home: TreinosPage(
        alunoId: alunoId,
        alunoService: alunoService,
        rotinaService: mockRotinaService,
      ),
    );
  }

  // Helper: abre o PopupMenu do card de uma rotina pelo nome
  Future<void> abrirMenu(WidgetTester tester, String nomeRotina) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpAndSettle();

    // O ícone more_vert fica dentro de um PopupMenuButton
    final menuBtn = find.byType(PopupMenuButton<String>);
    expect(menuBtn, findsOneWidget);
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();
  }

  group('PopupMenu do card de treino', () {
    testWidgets('exibe as opções Editar, Renomear e Excluir', (tester) async {
      await seedRotina('Treino A');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino A');

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Renomear'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
    });

    testWidgets('Editar navega para RotinaDetalhePage', (tester) async {
      await seedRotina('Treino Editar');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Editar');

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.byType(RotinaDetalhePage), findsOneWidget);
    });

    testWidgets('Renomear abre dialog e salva novo nome', (tester) async {
      final id = await seedRotina('Treino Original');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Original');

      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      // Dialog de renomear deve estar visível
      expect(find.text('Renomear treino'), findsOneWidget);

      // Limpa o campo e digita novo nome
      final field = find.byType(CupertinoTextField);
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, 'Treino Renomeado');
      await tester.pump();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      verify(() => mockRotinaService.renomearRotina(id, 'Treino Renomeado'))
          .called(1);
    });

    testWidgets('Renomear: cancelar não chama o serviço', (tester) async {
      await seedRotina('Treino Cancel');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Cancel');

      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRotinaService.renomearRotina(any(), any()));
    });

    testWidgets('Excluir abre dialog de confirmação', (tester) async {
      await seedRotina('Treino Excluir');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Excluir');

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir template?'), findsOneWidget);
      expect(
        find.text('Isso removerá a ficha da sua biblioteca permanentemente.'),
        findsOneWidget,
      );
    });

    testWidgets('Excluir: confirmar chama excluirRotina', (tester) async {
      final id = await seedRotina('Treino Delete');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Delete');

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      // Confirma no dialog — há dois textos 'Excluir', o do menu já sumiu,
      // agora só aparece o do dialog de confirmação
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      verify(() => mockRotinaService.excluirRotina(id)).called(1);
    });

    testWidgets('Excluir: cancelar não chama excluirRotina', (tester) async {
      await seedRotina('Treino NaoDelete');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino NaoDelete');

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRotinaService.excluirRotina(any()));
    });
  });

  group('TreinosPage geral', () {
    testWidgets('exibe estado vazio quando não há rotinas', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Biblioteca vazia'), findsOneWidget);
    });

    testWidgets('navega para RotinaDetalhePage ao clicar no botão adicionar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();

      expect(find.byType(RotinaDetalhePage), findsOneWidget);
    });
  });

  group('RotinaDetalhePage Logic', () {
    testWidgets('permite criar rotina com sessões', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      final svc = MockRotinaService();

      when(() => svc.criarRotina(
            alunoId: any(named: 'alunoId'),
            nome: any(named: 'nome'),
            objetivo: any(named: 'objetivo'),
            sessoes: any(named: 'sessoes'),
            tipoVencimento: any(named: 'tipoVencimento'),
            sessoesAlvo: any(named: 'sessoesAlvo'),
            dataVencimento: any(named: 'dataVencimento'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(home: RotinaDetalhePage(rotinaService: svc)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Treino de Força');
      await tester.enterText(fields.at(1), 'Ganho de massa');
      await tester.enterText(fields.at(2), '20');
      await tester.pump();

      await tester.tap(find.text('Salvar').first);
      await tester.pumpAndSettle();

      expect(find.text('Gerenciar Planilha'), findsOneWidget);

      await tester.tap(find.text('Nova sessão'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Treino A');
      await tester.pump();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Treino A'), findsOneWidget);

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      verify(() => svc.criarRotina(
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
