# Refatoração da AlunoHistoricoPage

A página `AlunoHistoricoPage` foi refatorada para separar a lógica de negócio da interface do usuário, seguindo os princípios de arquitetura do projeto.

## O que foi feito

### 1. Criação do `HistoricoController`
Foi criado um novo controller em [historico_controller.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/aluno/controllers/historico_controller.dart) que agora gerencia:
- O estado do mês atual selecionado no calendário.
- O cache de streams de logs para evitar flickering e reconexões desnecessárias.
- A lógica de navegação entre meses.
- O processamento de logs brutos para agrupamento por dia.
- A lógica de registro de peso chamando o `AlunoService`.

### 2. Simplificação da `AlunoHistoricoPage`
O arquivo [aluno_historico_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/aluno/pages/aluno_historico_page.dart) foi simplificado:
- A lógica de `StatefulWidget` que geria o mês e os streams foi removida.
- A página agora utiliza `ChangeNotifierProvider` para injetar o controller.
- Os widgets internos utilizam `context.watch<HistoricoController>()` para reagir às mudanças de estado e `context.read<HistoricoController>()` para disparar ações.
- **Conforme solicitado, todos os widgets de UI (calendário, cards, sheets) foram mantidos no mesmo arquivo.**

## Verificação
- Os analisadores estáticos não reportaram erros nos novos arquivos.
- A estrutura de dados e as chamadas de serviço foram mantidas idênticas à lógica original, garantindo que o comportamento da UI permaneça o mesmo.
- A navegação mensal agora é gerenciada centralizadamente, o que facilita testes futuros e manutenção.

## Sugestão de Commit
`refactor(aluno): extract business logic from AlunoHistoricoPage to HistoricoController`