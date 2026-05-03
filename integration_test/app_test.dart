import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appfit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo de Prescrição de Treino', () {
    testWidgets('Criar nova planilha básica para o aluno Manoel', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verificar se estamos na tela de seleção de perfil
      final btnPersonal = find.text('Sou personal trainer');
      if (btnPersonal.evaluate().isNotEmpty) {
        await tester.tap(btnPersonal);
        await tester.pumpAndSettle();
      }

      // 2. Se estivermos na tela de login, precisamos estar logados.
      // Como não temos as credenciais, assumimos que o app já pode estar logado
      // ou que o testador fará o login manual se necessário antes de rodar o teste real,
      // ou que o ambiente de teste já tem uma sessão ativa.
      // Para fins deste script, vamos esperar o Dashboard aparecer.

      // Tentamos encontrar a aba 'Alunos' que indica que estamos no Dashboard
      final tabAlunos = find.byIcon(Icons.group);

      // Se não encontrar de primeira, pode ser que precise de login.
      // Aqui o teste pararia ou falharia se não houver login automático.
      expect(tabAlunos, findsOneWidget, reason: 'O app deve estar logado no perfil Personal para prosseguir.');

      // 3. Clicar na aba 'Alunos'
      await tester.tap(tabAlunos);
      await tester.pumpAndSettle();

      // 4. Selecionar o aluno 'Manoel'
      // Assumimos que ele está na lista.
      final cardManoel = find.textContaining('Manoel');
      expect(cardManoel, findsOneWidget, reason: 'Aluno Manoel não encontrado na lista.');
      await tester.tap(cardManoel);
      await tester.pumpAndSettle();

      // 5. Clicar em 'Prescrever novo treino'
      final btnPrescrever = find.text('Prescrever novo treino');
      expect(btnPrescrever, findsOneWidget);
      await tester.tap(btnPrescrever);
      await tester.pumpAndSettle();

      // 6. Clicar em 'Criar do zero'
      final btnCriarZero = find.text('Criar do zero');
      expect(btnCriarZero, findsOneWidget);
      await tester.tap(btnCriarZero);
      await tester.pumpAndSettle();

      // 7. Configurações da Planilha (PlanilhaSettingsModal abre automaticamente)
      expect(find.text('Configurações'), findsOneWidget);

      // Encontrar o campo de texto pelo seu tipo (é o primeiro da tela)
      final fieldNome = find.byType(TextFormField).first;
      await tester.enterText(fieldNome, 'Treino de Força');
      await tester.pumpAndSettle();

      // Selecionar Objetivo (Dropdown)
      // O DropdownButtonFormField contém o texto 'Selecione o objetivo' quando vazio
      await tester.tap(find.text('Selecione o objetivo'));
      await tester.pumpAndSettle();

      // No menu do Dropdown, selecionar 'Ganho de Força'
      final itemObjetivo = find.text('Ganho de Força').last;
      await tester.tap(itemObjetivo);
      await tester.pumpAndSettle();

      // Clicar em Salvar (no Modal)
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // 8. Adicionar uma Sessão básica para permitir salvar a planilha
      // A página PersonalRotinaDetalhePage deve estar visível
      final btnNovaSessao = find.text('Nova sessão');
      expect(btnNovaSessao, findsOneWidget);
      await tester.tap(btnNovaSessao);
      await tester.pumpAndSettle();

      // No SessaoTreinoModal
      await tester.enterText(find.widgetWithText(TextFormField, 'Nome da sessão'), 'Sessão A');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      // Agora deve ter aberto a PersonalSessaoDetalhePage. Vamos apenas voltar para salvar a rotina.
      final btnVoltarSessao = find.byType(BackButton);
      if (btnVoltarSessao.evaluate().isNotEmpty) {
        await tester.tap(btnVoltarSessao);
        await tester.pumpAndSettle();
      }

      // 9. Clicar em Salvar a Planilha final
      final btnSalvarFinal = find.text('Salvar');
      await tester.tap(btnSalvarFinal);
      await tester.pumpAndSettle();

      // Verificar se voltou para o perfil do aluno
      expect(find.text('Perfil do Aluno'), findsOneWidget);
      expect(find.text('Treino de Força'), findsOneWidget);
    });
  });
}