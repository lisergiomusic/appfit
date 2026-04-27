# Checkpoint de Migração: Firebase -> Supabase (AppFit Pro)

## 1. Objetivo
Finalizar a limpeza da "Floresta Vermelha" (erros de compilação) após a troca da infraestrutura de Firebase (NoSQL) para Supabase (SQL/PostgreSQL).

## 2. Estado Atual da Infraestrutura
- **Auth**: `SupabaseAuthService` criado e funcional. `main.dart` vigiando o estado do Supabase.
- **Database**: Tabelas `profiles`, `exercicios_base`, `rotinas`, `logs_treino` e `faturas` criadas no Supabase.
- **Services**: Todos os services (`AlunoService`, `ExerciseService`, `TreinoService`, etc.) foram migrados para o `SupabaseClient`.

## 3. A Causa Raiz dos Erros (Coupling)
O app sofre de **Acoplamento Rígido**. As páginas de UI (`features/`) ainda importam `cloud_firestore` e esperam tipos específicos do Firebase que não existem mais nos novos Services:
1. **`Timestamp`**: Deve ser substituído por `DateTime.tryParse(data.toString())`.
2. **`QuerySnapshot / DocumentSnapshot`**: Devem ser substituídos por `List<Map<String, dynamic>>` ou `Map<String, dynamic>`.
3. **`doc.id` e `doc.data()`**: No Supabase, o ID já vem dentro do Map. O acesso deve ser direto: `map['id']`.
4. **Nomes de Colunas**: O banco Supabase usa `snake_case` (`personal_id`), mas o código legado busca `camelCase` (`personalId`).

## 4. Arquivos que Precisam de "Limpeza Pesada" (Prioridade)
- `lib/features/alunos/personal/pages/personal_alunos_page.dart`
- `lib/features/treinos/personal/pages/personal_treinos_page.dart`
- `lib/features/treinos/aluno/pages/aluno_historico_page.dart`
- `lib/features/treinos/personal/controllers/rotina_detalhe_controller.dart`
- `lib/features/alunos/shared/widgets/ficha_ativa_hero_card.dart`

## 5. Instruções de Correção (Para o Claude/Dev)
1. **Remover Imports**: Deletar `import 'package:cloud_firestore/cloud_firestore.dart';` de todos os arquivos na pasta `lib/features/`.
2. **Normalizar Modelos**: Garantir que as factories `fromFirestore` sejam renomeadas ou adaptadas para aceitar `Map<String, dynamic>` puro (JSON).
3. **Ajustar Streams**: Mudar `StreamBuilder<QuerySnapshot>` para `StreamBuilder<List<Map<String, dynamic>>>` e remover acessos a `.docs`.
4. **Tratar Datas**: Substituir qualquer chamada de `.toDate()` (do Firebase) por conversões `DateTime`.

---
**Assinado:** IA Mentor Staff (Modo War Room)