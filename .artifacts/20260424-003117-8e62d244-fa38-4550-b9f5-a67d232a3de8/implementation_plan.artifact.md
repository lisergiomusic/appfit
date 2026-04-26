# Fix Infinite Loading in Student Profile

The user reported an infinite loading state (shimmer) when re-entering any student's profile page after editing a routine. This typically indicates that a `StreamBuilder` is stuck in `ConnectionState.waiting`, meaning the underlying stream is not emitting any events (data or error).

The investigation points to `AlunoService.getAlunoPerfilCompletoStream`. This method uses `switchMap` combined with `Rx.combineLatest2`. A potential race condition or re-subscription issue exists because one of the combined streams (`rotinaStream`) is defined outside the `switchMap`, while the other (`personalStream`) is defined inside.

## Proposed Changes

### Aluno Service

#### [aluno_service.dart](file:///C:/Dev/Projetos/appfit/lib/core/services/aluno_service.dart)

- Refactor `getAlunoPerfilCompletoStream` to move all stream definitions inside the `switchMap`.
- Ensure that `combineLatest` receives fresh streams for each emission of the student document.
- Add error handling and logging to the stream to help diagnose if a specific part fails.
- Use `distinct()` on the student stream to avoid redundant re-subscriptions if the student document is updated without changing relevant fields.

```dart
  Stream<AlunoPerfilData> getAlunoPerfilCompletoStream(String alunoId) {
    return getAlunoStream(alunoId)
        .distinct((prev, curr) {
          // Só re-dispara o switchMap se dados fundamentais mudarem
          final pData = prev.data() as Map<String, dynamic>?;
          final cData = curr.data() as Map<String, dynamic>?;
          return pData?['personalId'] == cData?['personalId'] &&
                 pData?['nome'] == cData?['nome'] &&
                 pData?['sobrenome'] == cData?['sobrenome'];
        })
        .switchMap((alunoSnap) {
          final alunoMap = alunoSnap.data() as Map<String, dynamic>? ?? {};
          final personalId = alunoMap['personalId'] as String?;

          // Movido para dentro do switchMap para garantir que é recriado
          // corretamente a cada mudança do aluno.
          final rotinaStream = _firestore
              .collection('rotinas')
              .where('alunoId', isEqualTo: alunoId)
              .where('ativa', isEqualTo: true)
              .limit(1)
              .snapshots();

          final personalStream = personalId != null
              ? _firestore.collection('usuarios').doc(personalId).snapshots()
              : Stream<DocumentSnapshot?>.value(null);

          return Rx.combineLatest2<QuerySnapshot, DocumentSnapshot?, AlunoPerfilData>(
            rotinaStream,
            personalStream,
            (rotinaSnap, personalSnap) {
              final rotinaDoc = rotinaSnap.docs.isNotEmpty ? rotinaSnap.docs.first : null;
              final rotinaMap = rotinaDoc?.data() as Map<String, dynamic>?;
              final rotinaId = rotinaDoc?.id;

              final personalMap = personalSnap?.data() as Map<String, dynamic>? ?? {};
              final pNome = personalMap['nome']?.toString() ?? '';
              final pSobrenome = personalMap['sobrenome']?.toString() ?? '';
              final pNomeCompleto = '$pNome $pSobrenome'.trim();

              return AlunoPerfilData(
                aluno: alunoMap,
                rotinaAtiva: rotinaMap,
                rotinaId: rotinaId,
                nomePersonal: pNomeCompleto.isNotEmpty ? pNomeCompleto : null,
                especialidadePersonal: personalMap['especialidade']?.toString(),
                photoUrlPersonal: personalMap['photoUrl']?.toString(),
                telefonePersonal: personalMap['telefone']?.toString(),
              );
            },
          ).onErrorReturnWith((error, stackTrace) {
            debugPrint('Erro no combineLatest de perfil: $error');
            // Retorna dados parciais apenas com o aluno se o resto falhar
            return AlunoPerfilData(aluno: alunoMap);
          });
        });
  }
```

### UI Components

#### [personal_aluno_perfil_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/alunos/personal/pages/personal_aluno_perfil_page.dart)

- Improve the `StreamBuilder` logic to handle potential error states explicitly, providing feedback to the user instead of just showing a generic error or shimmer if something goes wrong.

## Verification Plan

### Automated Tests
- No new automated tests are planned as this is a fix for a reactive stream hang which is hard to unit test without complex mock setups for Firestore/RxDart interactions.

### Manual Verification
- **Reproduce the flow**:
    1. Login as 'personal'.
    2. Go to a student profile.
    3. Edit active routine and save (Sessao page then Routine page).
    4. Back to Home.
    5. Re-enter any student profile.
    6. Verify that the shimmer disappears and data is loaded correctly.
- **Check various student states**:
    1. Student with no active routine.
    2. Student with no personal assigned (if possible).
    3. Student with non-existent personal ID.
- **Inspect Logs**:
    1. Monitor `debugPrint` output for any "Erro no combineLatest de perfil" or Firestore index errors.