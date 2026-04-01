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
  late String currentUserId;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    currentUserId = 'personal_123';
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: currentUserId),
    );
    alunoService = AlunoService(firestore: fakeFirestore, auth: mockAuth);
    mockRotinaService = MockRotinaService();

    when(() => mockRotinaService.excluirRotina(any())).thenAnswer((_) async {});
    when(
      () => mockRotinaService.renomearRotina(any(), any()),
    ).thenAnswer((_) async {});
  });

  /// Insere uma rotina no Firestore fake e retorna seu id.
  Future<String> seedRotina(String nome, {String? personalId}) async {
    final ref = await fakeFirestore.collection('rotinas').add({
      'nome': nome,
      'objetivo': 'Ganho de massa',
      'sessoes': [],
      'ativa': true,
      'personalId': personalId ?? currentUserId,
      'alunoId': null,
      'tipoVencimento': 'sessoes',
      'vencimentoSessoes': 20,
    });
    return ref.id;
  }

  Widget buildPage({String? alunoId, String? alunoNome}) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: TreinosPage(
        alunoId: alunoId,
        alunoNome: alunoNome,
        alunoService: alunoService,
        rotinaService: mockRotinaService,
      ),
    );
  }

  // Helper: abre o PopupMenu do card de uma rotina pelo nome
  Future<void> abrirMenu(WidgetTester tester, String nomeRotina) async {
    await tester.pumpAndSettle();

    // Encontra o card pelo texto do nome da rotina
    final cardFinder = find
        .ancestor(of: find.text(nomeRotina), matching: find.byType(Container))
        .first;

    // O ícone more_vert fica dentro de um PopupMenuButton no card
    final menuBtn = find.descendant(
      of: cardFinder,
      matching: find.byType(PopupMenuButton<String>),
    );

    expect(
      menuBtn,
      findsOneWidget,
      reason: 'Não encontrou o PopupMenuButton para a rotina $nomeRotina',
    );
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();
  }

  group('TreinosPage - UI e Listagem', () {
    testWidgets('exibe estado vazio quando não há rotinas', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Biblioteca vazia'), findsOneWidget);
    });

    testWidgets('exibe lista de rotinas cadastradas', (tester) async {
      await seedRotina('Treino A');
      await seedRotina('Treino B');

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Treino A'), findsOneWidget);
      expect(find.text('Treino B'), findsOneWidget);
      expect(find.text('Templates (2)'), findsOneWidget);
    });

    testWidgets('não exibe rotinas de outros personals', (tester) async {
      await seedRotina('Meu Treino');
      await seedRotina('Treino Alheio', personalId: 'outro_uid');

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Meu Treino'), findsOneWidget);
      expect(find.text('Treino Alheio'), findsNothing);
    });

    testWidgets('busca filtra a lista de rotinas', (tester) async {
      await seedRotina('Peito e Tríceps');
      await seedRotina('Costas e Bíceps');

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Peito e Tríceps'), findsOneWidget);
      expect(find.text('Costas e Bíceps'), findsOneWidget);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Peito');
      await tester
          .pumpAndSettle(); // Usar pumpAndSettle para garantir que a UI filtrou

      expect(find.text('Peito e Tríceps'), findsOneWidget);
      expect(find.text('Costas e Bíceps'), findsNothing);

      // Limpa busca
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Costas e Bíceps'), findsOneWidget);
    });

    testWidgets('quando busca não encontra resultados exibe estado vazio', (
      tester,
    ) async {
      await seedRotina('Treino Funcional');
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'inexistente');
      await tester.pumpAndSettle();

      expect(find.text('Biblioteca vazia'), findsOneWidget);
    });
  });

  group('TreinosPage - Ações e Navegação', () {
    testWidgets('navega para RotinaDetalhePage ao clicar no botão adicionar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();

      // Quando rotinaData é null, RotinaDetalhePage abre o modal de configurações
      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets(
      'navega para RotinaDetalhePage ao clicar em um card (modo biblioteca)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1200));
        await seedRotina('Treino Clique');
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Treino Clique'));
        await tester.pumpAndSettle();

        expect(find.byType(RotinaDetalhePage), findsOneWidget);
      },
    );

    testWidgets(
      'navega para RotinaDetalhePage ao clicar em um card (modo seleção para aluno)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1200));
        await seedRotina('Treino Seleção');
        await tester.pumpWidget(
          buildPage(alunoId: 'aluno_1', alunoNome: 'João'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Treino Seleção'));
        await tester.pumpAndSettle();

        expect(find.byType(RotinaDetalhePage), findsOneWidget);
        final page = tester.widget<RotinaDetalhePage>(
          find.byType(RotinaDetalhePage),
        );
        expect(page.alunoId, equals('aluno_1'));
      },
    );

    testWidgets('não exibe botão adicionar no modo seleção', (tester) async {
      await tester.pumpWidget(buildPage(alunoId: 'aluno_1', alunoNome: 'João'));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.add), findsNothing);
    });
  });

  group('TreinosPage - Menu de Opções', () {
    testWidgets('Editar navega para RotinaDetalhePage', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
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

      expect(find.text('Renomear treino'), findsOneWidget);

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'Treino Renomeado');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      verify(
        () => mockRotinaService.renomearRotina(id, 'Treino Renomeado'),
      ).called(1);
    });

    testWidgets('Renomear com valor vazio não chama serviço', (tester) async {
      await seedRotina('Treino Sem Rename');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Sem Rename');

      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, '   ');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRotinaService.renomearRotina(any(), any()));
    });

    testWidgets('Excluir abre confirmação e deleta', (tester) async {
      final id = await seedRotina('Treino Deletar');
      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Deletar');

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir template?'), findsOneWidget);

      final deleteBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Excluir'),
      );
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      verify(() => mockRotinaService.excluirRotina(id)).called(1);
    });
  });

  group('TreinosPage - Swipe to Delete', () {
    testWidgets('swipe para a esquerda abre dialog de exclusão', (
      tester,
    ) async {
      await seedRotina('Treino Swipe');
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final itemFinder = find.byType(Dismissible);
      expect(itemFinder, findsOneWidget);

      await tester.drag(itemFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Excluir template?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRotinaService.excluirRotina(any()));
    });

    testWidgets('swipe para a esquerda e confirma exclusão', (tester) async {
      final id = await seedRotina('Treino Swipe Delete');
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Excluir'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => mockRotinaService.excluirRotina(id)).called(1);
    });

    testWidgets('no modo seleção swipe delete fica desabilitado', (
      tester,
    ) async {
      await seedRotina('Treino Seleção Swipe');
      await tester.pumpWidget(buildPage(alunoId: 'aluno_1', alunoNome: 'João'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Excluir template?'), findsNothing);
      verifyNever(() => mockRotinaService.excluirRotina(any()));
    });
  });

  group('TreinosPage - Tratamento de erros', () {
    testWidgets('mostra SnackBar quando excluir falha pelo menu', (
      tester,
    ) async {
      final id = await seedRotina('Treino Erro Excluir');
      when(
        () => mockRotinaService.excluirRotina(any()),
      ).thenThrow(Exception('falha excluir'));

      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Erro Excluir');

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      final deleteBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Excluir'),
      );
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro ao excluir:'), findsOneWidget);
      verify(() => mockRotinaService.excluirRotina(id)).called(1);
    });

    testWidgets('mostra SnackBar quando renomear falha', (tester) async {
      final id = await seedRotina('Treino Erro Renomear');
      when(
        () => mockRotinaService.renomearRotina(any(), any()),
      ).thenThrow(Exception('falha renomear'));

      await tester.pumpWidget(buildPage());
      await abrirMenu(tester, 'Treino Erro Renomear');

      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'Treino Novo Nome');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro ao renomear:'), findsOneWidget);
      verify(
        () => mockRotinaService.renomearRotina(id, 'Treino Novo Nome'),
      ).called(1);
    });
  });
}
