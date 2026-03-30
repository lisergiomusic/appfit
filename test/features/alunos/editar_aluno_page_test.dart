import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appfit/features/alunos/editar_aluno_page.dart';

void main() {
  group('EditarAlunoPage - Testes de Interface', () {
    testWidgets('Deve encontrar os placeholders e o botão de voltar', (WidgetTester tester) async {
      // Carrega o widget
      await tester.pumpWidget(
        const MaterialApp(
          home: EditarAlunoPage(alunoId: 'id_fake_para_teste'),
        ),
      );

      // Como a página começa em estado de "loading", damos um pump()
      // No seu código real, ela tentará carregar do Firebase. 
      // Por enquanto, vamos verificar se ela renderiza a estrutura.
      await tester.pump();

      // Verifica se o título da AppBar está lá
      expect(find.text('Editar Aluno'), findsOneWidget);

      // Verifica se o botão "Voltar" que configuramos aparece
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_back), findsOneWidget);

      // Note: Como o initState chama o Firebase real, este teste pode mostrar 
      // um erro de "MissingPluginException" se rodar sem Mock.
      // Mas a estrutura do arquivo agora existe para você estudar!
    });
  });

  group('EditarAlunoPage - Funcionalidade', () {
    testWidgets('Exibe loading indicator ao carregar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditarAlunoPage(alunoId: 'id_fake_para_teste'),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Campos obrigatórios validam corretamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditarAlunoPage(alunoId: 'id_fake_para_teste'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(find.text('O nome é obrigatório'), findsOneWidget);
      expect(find.text('O sobrenome é obrigatório'), findsOneWidget);
      expect(find.text('O e-mail é obrigatório'), findsOneWidget);
    });

    testWidgets('Permite selecionar gênero e data de nascimento', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditarAlunoPage(alunoId: 'id_fake_para_teste'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gênero'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outro').last);
      await tester.pump();
      expect(find.text('Outro'), findsWidgets);
      await tester.tap(find.byIcon(Icons.calendar_today_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('Botão Salvar mostra loading ao salvar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditarAlunoPage(alunoId: 'id_fake_para_teste'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'João');
      await tester.enterText(find.byType(TextFormField).at(1), 'Silva');
      await tester.enterText(find.byType(TextFormField).at(2), 'joao@email.com');
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}