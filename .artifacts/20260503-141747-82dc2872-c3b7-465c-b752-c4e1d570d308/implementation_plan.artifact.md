# Implementação de Exercícios Alternativos (Slot Flex)

O objetivo é permitir que o Personal Trainer defina dois exercícios equivalentes para um único slot de treino. O aluno terá o poder de escolha, podendo realizar qualquer um dos dois (ou alternar entre as séries) sem fugir do planejamento de volume (séries/reps) definido pelo treinador.

## User Review Required

> [!IMPORTANT]
> - **Compartilhamento de Séries**: O planejamento de séries (objetivo de reps, tempo de descanso) será **idêntico** para os dois exercícios do slot.
> - **Histórico Individual**: Embora o slot seja compartilhado, a carga registrada será salva especificamente para o exercício executado, garantindo que o progresso de cada um seja rastreado separadamente no Supabase.

## Mudanças Propostas

### 1. Modelo de Dados

#### [exercicio_model.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/shared/models/exercicio_model.dart)
- Modificar `ExercicioItem` para incluir `String? exercicioAlternativoId` e `String? exercicioAlternativoNome`.
- Alternativa: Criar um wrapper ou manter na tabela de junção da sessão. Dado o fluxo atual, adicionar um campo `exercicioAlternativo` (objeto parcial) ao `ExercicioItem` parece mais simples para a UI.

### 2. Controle de Sessão

#### [configurar_treino_controller.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/controllers/configurar_treino_controller.dart)
- Adicionar métodos para gerenciar o exercício alternativo:
  - `addAlternativa(int index, ExercicioItem alternativa)`
  - `removeAlternativa(int index)`

### 3. Interface do Personal (Configuração de Treino)

#### [personal_sessao_detalhe_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_sessao_detalhe_page.dart)
- **Novo Botão**: Adicionar um botão discreto (ícone de `swap` ou `plus`) no card de cada exercício para "Adicionar Alternativa".
- **Visual "Slot Flex"**: Se houver alternativa, o card exibirá os dois nomes com um divisor "OU" estilizado.
- **Fluxo**: Abrir a biblioteca em modo de seleção para escolher a alternativa.

### 4. Interface de Detalhe do Exercício

#### [personal_exercicio_detalhe_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_exercicio_detalhe_page.dart)
- Exibir o nome de ambos os exercícios no cabeçalho se for um slot flex.
- Reforçar que as séries configuradas valem para ambos.

---

## Plano de Verificação

### Testes Manuais
1. **Adição de Alternativa**: No modo de edição de sessão, adicionar um exercício principal e depois vincular uma alternativa.
2. **Visualização**: Confirmar que o card da sessão agora mostra `Exercício A OU Exercício B`.
3. **Persistência**: Salvar a rotina no Supabase e verificar se a relação alternativa foi mantida no banco.
4. **Remoção**: Remover a alternativa e garantir que o slot volte a ser um exercício único sem perder as séries planejadas.