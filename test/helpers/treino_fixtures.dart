import 'package:appfit/features/treinos/shared/models/rotina_model.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';

/// Cria uma sessão de treino fake para testes
SessaoTreinoModel fakeSessao({
  String nome = 'Peito e Costas',
  String? diaSemana = 'Segunda',
  String? orientacoes = 'Foco na contração',
  List<ExercicioItem>? exercicios,
}) {
  return SessaoTreinoModel(
    nome: nome,
    diaSemana: diaSemana,
    orientacoes: orientacoes,
    exercicios: exercicios ?? _defaultExercicios(),
  );
}

/// Retorna exercícios padrão para testes
List<ExercicioItem> _defaultExercicios() => [
  ExercicioItem(
    nome: 'Supino Reto',
    grupoMuscular: const ['Peito'],
    tipoAlvo: 'Reps',
    series: [
      SerieItem(
        tipo: TipoSerie.aquecimento,
        alvo: '15',
        carga: '40',
        descanso: '60s',
      ),
      SerieItem(
        tipo: TipoSerie.trabalho,
        alvo: '10',
        carga: '60',
        descanso: '90s',
      ),
      SerieItem(
        tipo: TipoSerie.trabalho,
        alvo: '10',
        carga: '60',
        descanso: '90s',
      ),
    ],
  ),
  ExercicioItem(
    nome: 'Remada',
    grupoMuscular: const ['Costas'],
    tipoAlvo: 'Reps',
    instrucoes: 'Manter postura reta',
    series: [
      SerieItem(
        tipo: TipoSerie.trabalho,
        alvo: '12',
        carga: '50',
        descanso: '120s',
      ),
    ],
  ),
];

/// Cria uma rotina completa fake para testes
RotinaModel fakeRotina({
  String id = 'rotina_test_123',
  String nome = 'Hipertrofia A',
  String objetivo = 'Ganho de massa muscular',
  String tipoVencimento = 'sessoes',
  int? vencimentoSessoes = 20,
  DateTime? dataVencimento,
  List<SessaoTreinoModel>? sessoes,
}) {
  return RotinaModel(
    id: id,
    nome: nome,
    objetivo: objetivo,
    tipoVencimento: tipoVencimento,
    vencimentoSessoes: vencimentoSessoes,
    dataVencimento: dataVencimento,
    sessoes: sessoes ?? [fakeSessao()],
  );
}

/// Cria dados Firestore fake de uma rotina com contadores
Map<String, dynamic> fakeRotinaData({
  String nome = 'Hipertrofia A',
  String objetivo = 'Ganho de massa',
  String tipoVencimento = 'sessoes',
  int vencimentoSessoes = 20,
  int sessoesConcluidas = 5,
  bool ativa = true,
  DateTime? dataCriacao,
  DateTime? dataVencimento,
  List<Map<String, dynamic>>? sessoes,
}) {
  final now = DateTime.now();
  return {
    'nome': nome,
    'objetivo': objetivo,
    'tipoVencimento': tipoVencimento,
    'vencimentoSessoes': vencimentoSessoes,
    'sessoesConcluidas': sessoesConcluidas,
    'ativa': ativa,
    'dataCriacao': dataCriacao ?? now,
    'dataVencimento': dataVencimento ?? now.add(const Duration(days: 90)),
    'personalId': 'personal_test_123',
    'alunoId': 'aluno_test_123',
    'sessoes': sessoes ?? _defaultSessoesData(),
  };
}

/// Retorna sessões padrão em formato Firestore
List<Map<String, dynamic>> _defaultSessoesData() => [
  {
    'nome': 'Peito e Costas',
    'diaSemana': 'Segunda',
    'orientacoes': 'Foco na contração',
    'exercicios': [
      {
        'nome': 'Supino Reto',
        'grupoMuscular': ['Peito'],
        'tipoAlvo': 'Reps',
        'series': [
          {
            'tipo': 'aquecimento',
            'alvo': '15',
            'carga': '40',
            'descanso': '60s',
          },
          {'tipo': 'trabalho', 'alvo': '10', 'carga': '60', 'descanso': '90s'},
        ],
      },
    ],
  },
];

/// Cria um documento de log de treino fake
Map<String, dynamic> fakeTreinoLog({
  String alunoId = 'aluno_test_123',
  String rotinaId = 'rotina_test_123',
  String sessaoNome = 'Peito e Costas',
  List<Map<String, dynamic>>? exercicios,
}) {
  return {
    'alunoId': alunoId,
    'rotinaId': rotinaId,
    'sessaoNome': sessaoNome,
    'dataHora': DateTime.now(),
    'duracaoMinutos': 45,
    'exercicios': exercicios ?? _defaultLogExercicios(),
  };
}

/// Retorna exercícios com performance registrada (para logs)
List<Map<String, dynamic>> _defaultLogExercicios() => [
  {
    'nome': 'Supino Reto',
    'grupoMuscular': ['Peito'],
    'series': [
      {
        'alvo': '15',
        'cargaAlvo': '40',
        'repsRealizadas': '15',
        'pesoRealizado': '40',
        'concluida': true,
      },
      {
        'alvo': '10',
        'cargaAlvo': '60',
        'repsRealizadas': '10',
        'pesoRealizado': '60',
        'concluida': true,
      },
    ],
  },
];
