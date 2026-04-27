# Checkpoint de Contexto - AppFit Pro

## 1. Identidade do Projeto (Atualizado 2026)
- **ApplicationId**: `com.appfit.pro`
- **Namespace**: `com.appfit.pro`
- **Firebase BOM**: `33.9.0` (Estabilizado para Android 14)
- **SHA-1 (Debug)**: `B9:9F:60:8B:DD:9C:E0:A2:60:FA:66:A7:4F:BD:F8:41:D3:FD:8B:E1`

## 2. Histórico do Problema (gRPC vs Android)
- **Sintoma**: Shimmer infinito ao navegar entre alunos e erro de `Broken pipe`.
- **Causa**: O gRPC do Firestore no Android (especialmente Xiaomi) é sensível à latência e à falta de índices. Consultas sem índices disparavam "Full Collection Scans" que o sistema operacional matava por timeout.
- **Estado Atual**: A identidade foi corrigida, os índices compostos foram criados no console, e o `AlunoService` foi blindado com `startWith` e `onErrorReturn` para não travar a UI.

## 3. Estrutura de Dados (Mapeamento para Migração)
- **Usuários/Alunos**: Campos básicos + `personalId` + `tipoUsuario`.
- **Rotinas**: 1 Aluno -> 1 Rotina Ativa. Contém uma `List<Sessoes>`.
- **Sessões**: Contém uma `List<Exercicios>`.
- **Exercícios**: Contém uma `List<Series>`.
- **Logs de Treino**: Histórico de execuções ligadas ao `alunoId`.

## 4. Próximo Grande Objetivo: Migração para Supabase
- **Motivação**: Estabilidade de rede (HTTPS/WebSockets) e aprendizado de mercado (SQL/PostgreSQL) para o desenvolvedor (foco em vagas Junior).
- **Dados de Infraestrutura**:
  - **DB Password**: `_E4Xm/ZC4f%+HCG`
  - **URL**: *Aguardando preenchimento*
  - **Anon Key**: *Aguardando preenchimento*
- **Plano**: 
  1. Criar projeto no Supabase. (CONCLUÍDO)
  2. Modelar tabelas SQL equivalentes aos documentos NoSQL. (SCRIPT GERADO)
  3. Migrar Auth e Services um por um.

## 5. Instruções para a IA
Ao ler este arquivo, assuma que a infraestrutura Firebase está funcional mas instável, e que o foco agora é a transição para uma arquitetura baseada em HTTPS e SQL para fins educacionais e de performance.