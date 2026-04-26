# Task Management

- [x] Research bug in Student Profile loading
	- [x] Analyze `PersonalAlunoPerfilPage` stream usage
	- [x] Analyze `AlunoService.getAlunoPerfilCompletoStream` implementation
	- [x] Analyze saving logic in `PersonalRotinaDetalhePage` and `PersonalSessaoDetalhePage`
- [x] Fix infinite loading (shimmer)
	- [x] Refactor `getAlunoPerfilCompletoStream` in `aluno_service.dart`
	- [x] Improve error handling in `PersonalAlunoPerfilPage`
- [ ] Verify fix
	- [ ] Perform manual verification of the reported flow
	- [ ] Verify edge cases (student without routine, etc.)