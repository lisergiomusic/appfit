# Exibir tempo de descanso na execução do treino

Adicionar o tempo de descanso definido pelo personal trainer logo abaixo do alvo de repetições nas linhas de séries da tela de execução de treino.

## Proposed Changes

### Treinos Shared Widgets

#### [workout_set_row.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/shared/widgets/executar_treino/workout_set_row.dart)

- Atualizar o widget da coluna "ALVO" para incluir o tempo de descanso com um ícone de timer.
- Implementar a lógica para adicionar "s" (segundos) caso o valor de descanso seja puramente numérico.

```diff
           SizedBox(
             width: 52,
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(
                   serie.alvo,
                   style: const TextStyle(
                     fontSize: 13,
                     fontWeight: FontWeight.w500,
                     color: AppColors.labelSecondary,
                     letterSpacing: -0.1,
+                    height: 1.1,
                   ),
                   textAlign: TextAlign.center,
                 ),
+                const SizedBox(height: 2),
+                Row(
+                  mainAxisAlignment: MainAxisAlignment.center,
+                  children: [
+                    const Icon(
+                      Icons.timer_outlined,
+                      size: 10,
+                      color: AppColors.labelTertiary,
+                    ),
+                    const SizedBox(width: 2),
+                    Text(
+                      RegExp(r'^\d+$').hasMatch(serie.descanso.trim())
+                          ? '${serie.descanso}s'
+                          : serie.descanso,
+                      style: const TextStyle(
+                        fontSize: 10,
+                        fontWeight: FontWeight.w400,
+                        color: AppColors.labelTertiary,
+                        letterSpacing: -0.1,
+                      ),
+                    ),
+                  ],
+                ),
               ],
             ),
           ),
```

## Verification Plan

### Automated Tests
- Não há testes automatizados específicos para este widget visual no momento.

### Manual Verification
1. Abrir a tela de execução de treino como aluno.
2. Verificar se em cada série, abaixo do número de repetições alvo, aparece o ícone de timer e o tempo de descanso (ex: "60s").
3. Validar se o layout permanece alinhado e legível em dispositivos com telas menores.