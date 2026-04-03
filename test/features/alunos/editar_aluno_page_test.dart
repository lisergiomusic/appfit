import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:appfit/core/services/aluno_service.dart';
import 'package:appfit/features/alunos/editar_aluno_page.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  Future<AlunoService> buildAlunoServiceWithAluno() async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'personal_test_123'),
    );

    await firestore.collection('usuarios').doc('aluno_teste').set({
      'nome': 'Joao',
      'sobrenome': 'Silva',
      'email': 'joao@email.com',
      'telefone': '(11) 99999-9999',
      'pesoAtual': 80,
      'tipoUsuario': 'aluno',
      'personalId': 'personal_test_123',
    });

    return AlunoService(firestore: firestore, auth: auth);
  }

  Future<void> pumpEditarAlunoPage(
    WidgetTester tester,
    AlunoService service,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditarAlunoPage(alunoId: 'aluno_teste', alunoService: service),
      ),
    );
  }

  group('EditarAlunoPage - Testes de Interface', () {
    testWidgets('Deve encontrar os placeholders e o botão de voltar', (
      WidgetTester tester,
    ) async {
      final service = await buildAlunoServiceWithAluno();
      await pumpEditarAlunoPage(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('Editar Aluno'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_back), findsOneWidget);
    });
  });

  group('EditarAlunoPage - Funcionalidade', () {
    testWidgets('Exibe loading indicator ao carregar', (tester) async {
      final service = await buildAlunoServiceWithAluno();
      await pumpEditarAlunoPage(tester, service);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Campos obrigatórios validam corretamente', (tester) async {
      final service = await buildAlunoServiceWithAluno();
      await pumpEditarAlunoPage(tester, service);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.enterText(find.byType(TextFormField).at(1), '');

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('O nome é obrigatório'), findsOneWidget);
      expect(find.text('O sobrenome é obrigatório'), findsOneWidget);
    });

    testWidgets('Permite selecionar gênero e data de nascimento', (
      tester,
    ) async {
      final service = await buildAlunoServiceWithAluno();
      await pumpEditarAlunoPage(tester, service);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outro').last);
      await tester.pump();

      expect(find.text('Outro'), findsWidgets);

      await tester.tap(find.byIcon(Icons.calendar_today_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('Botão Salvar mostra loading ao salvar', (tester) async {
      final service = await buildAlunoServiceWithAluno();
      await pumpEditarAlunoPage(tester, service);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'João');
      await tester.enterText(find.byType(TextFormField).at(1), 'Silva');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'joao@email.com',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
