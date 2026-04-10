
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:appfit/features/treinos/shared/models/rotina_model.dart';
import 'package:appfit/features/treinos/personal/controllers/rotina_detalhe_controller.dart';
import 'package:appfit/core/services/rotina_service.dart';


Map<String, dynamic> _serie({
  String tipo = 'trabalho',
  String alvo = '10',
  String carga = '80kg',
  String descanso = '60s',
}) => {'tipo': tipo, 'alvo': alvo, 'carga': carga, 'descanso': descanso};

Map<String, dynamic> _exercicio({
  String nome = 'Supino Reto',
  List<Map<String, dynamic>>? series,
}) => {
  'nome': nome,
  'grupoMuscular': ['Peito'],
  'tipoAlvo': 'Reps',
  'series': series ?? [_serie()],
};

Map<String, dynamic> _sessao({
  String nome = 'Treino A',
  List<Map<String, dynamic>>? exercicios,
}) => {
  'nome': nome,
  'diaSemana': '',
  'orientacoes': '',
  'exercicios': exercicios ?? [_exercicio()],
};

Map<String, dynamic> _rotinaData({List<Map<String, dynamic>>? sessoes}) => {
  'nome': 'Rotina Teste',
  'objetivo': 'Ganho de massa',
  'tipoVencimento': 'sessoes',
  'vencimentoSessoes': 20,
  'sessoes': sessoes ?? [_sessao()],
};


void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('SessaoTreinoModel — serialização', () {
    test(
      'toFirestore inclui campo "series" com tipo, alvo, carga e descanso',
      () {
        final sessao = SessaoTreinoModel(
          nome: 'Treino A',
          exercicios: [
            ExercicioItem(
              nome: 'Supino',
              grupoMuscular: ['Peito'],
              series: [
                SerieItem(
                  tipo: TipoSerie.trabalho,
                  alvo: '10',
                  carga: '80kg',
                  descanso: '60s',
                ),
                SerieItem(
                  tipo: TipoSerie.aquecimento,
                  alvo: '15',
                  carga: '40kg',
                  descanso: '30s',
                ),
              ],
            ),
          ],
        );

        final map = sessao.toFirestore();
        final series = (map['exercicios'] as List).first['series'] as List;

        expect(series.length, 2);
        expect(series[0], containsPair('tipo', 'trabalho'));
        expect(series[0], containsPair('alvo', '10'));
        expect(series[0], containsPair('carga', '80kg'));
        expect(series[0], containsPair('descanso', '60s'));
        expect(series[1], containsPair('tipo', 'aquecimento'));
        expect(series[1], containsPair('alvo', '15'));
      },
    );

    test(
      'fromFirestore reconstrói SerieItem com tipo, alvo, carga e descanso',
      () {
        final data = {
          'nome': 'Treino A',
          'diaSemana': '',
          'orientacoes': '',
          'exercicios': [
            {
              'nome': 'Agachamento',
              'grupoMuscular': ['Pernas'],
              'tipoAlvo': 'Reps',
              'series': [
                {
                  'tipo': 'feeder',
                  'alvo': '8',
                  'carga': '100kg',
                  'descanso': '90s',
                },
                {
                  'tipo': 'trabalho',
                  'alvo': '5',
                  'carga': '120kg',
                  'descanso': '180s',
                },
              ],
            },
          ],
        };

        final sessao = SessaoTreinoModel.fromFirestore(data);
        final series = sessao.exercicios.first.series;

        expect(series.length, 2);
        expect(series[0].tipo, TipoSerie.feeder);
        expect(series[0].alvo, '8');
        expect(series[0].carga, '100kg');
        expect(series[0].descanso, '90s');
        expect(series[1].tipo, TipoSerie.trabalho);
        expect(series[1].alvo, '5');
        expect(series[1].carga, '120kg');
      },
    );

    test(
      'round-trip (toFirestore → fromFirestore) preserva todas as séries',
      () {
        final original = SessaoTreinoModel(
          nome: 'Treino B',
          exercicios: [
            ExercicioItem(
              nome: 'Rosca Direta',
              grupoMuscular: ['Bíceps'],
              series: [
                SerieItem(
                  tipo: TipoSerie.aquecimento,
                  alvo: '20',
                  carga: '15kg',
                  descanso: '30s',
                ),
                SerieItem(
                  tipo: TipoSerie.feeder,
                  alvo: '12',
                  carga: '25kg',
                  descanso: '60s',
                ),
                SerieItem(
                  tipo: TipoSerie.trabalho,
                  alvo: '10',
                  carga: '30kg',
                  descanso: '90s',
                ),
              ],
            ),
          ],
        );

        final rebuilt = SessaoTreinoModel.fromFirestore(original.toFirestore());
        final orig = original.exercicios.first.series;
        final reb = rebuilt.exercicios.first.series;

        expect(reb.length, orig.length);
        for (var i = 0; i < orig.length; i++) {
          expect(reb[i].tipo, orig[i].tipo, reason: 'série $i: tipo diverge');
          expect(reb[i].alvo, orig[i].alvo, reason: 'série $i: alvo diverge');
          expect(
            reb[i].carga,
            orig[i].carga,
            reason: 'série $i: carga diverge',
          );
          expect(
            reb[i].descanso,
            orig[i].descanso,
            reason: 'série $i: descanso diverge',
          );
        }
      },
    );

    test('exercício sem séries é preservado no round-trip', () {
      final sessao = SessaoTreinoModel(
        nome: 'Treino',
        exercicios: [
          ExercicioItem(nome: 'Pull-up', grupoMuscular: ['Costas'], series: []),
        ],
      );

      final rebuilt = SessaoTreinoModel.fromFirestore(sessao.toFirestore());
      expect(rebuilt.exercicios.first.series, isEmpty);
    });

    test('múltiplos exercícios com séries distintas são todos preservados', () {
      final sessao = SessaoTreinoModel(
        nome: 'Full Body',
        exercicios: [
          ExercicioItem(
            nome: 'Supino',
            grupoMuscular: ['Peito'],
            series: [
              SerieItem(
                tipo: TipoSerie.trabalho,
                alvo: '8',
                carga: '100kg',
                descanso: '90s',
              ),
            ],
          ),
          ExercicioItem(
            nome: 'Agachamento',
            grupoMuscular: ['Pernas'],
            series: [
              SerieItem(
                tipo: TipoSerie.aquecimento,
                alvo: '20',
                carga: '60kg',
                descanso: '30s',
              ),
              SerieItem(
                tipo: TipoSerie.trabalho,
                alvo: '5',
                carga: '140kg',
                descanso: '180s',
              ),
            ],
          ),
        ],
      );

      final rebuilt = SessaoTreinoModel.fromFirestore(sessao.toFirestore());

      expect(rebuilt.exercicios[0].series.length, 1);
      expect(rebuilt.exercicios[0].series[0].carga, '100kg');
      expect(rebuilt.exercicios[1].series.length, 2);
      expect(rebuilt.exercicios[1].series[1].carga, '140kg');
    });
  });

  group('RotinaDetalheController', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RotinaService service;
    late RotinaDetalheController Function(Map<String, dynamic>) makeCtrl;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = RotinaService(
        firestore: fakeFirestore,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'personal_123'),
        ),
      );
      makeCtrl = (data) => RotinaDetalheController(
        rotinaId: 'rotina_123',
        rotinaService: service,
        initialData: data,
      );
    });

    group('verificarAlteracoes — séries', () {
      test('retorna false quando nada foi alterado', () {
        final ctrl = makeCtrl(_rotinaData());
        expect(ctrl.verificarAlteracoes(), isFalse);
        ctrl.dispose();
      });

      test('retorna true quando alvo de uma série muda', () {
        final ctrl = makeCtrl(_rotinaData());
        ctrl.treinos[0].exercicios[0].series[0].alvo = '99';
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });

      test('retorna true quando carga de uma série muda', () {
        final ctrl = makeCtrl(_rotinaData());
        ctrl.treinos[0].exercicios[0].series[0].carga = '999kg';
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });

      test('retorna true quando descanso de uma série muda', () {
        final ctrl = makeCtrl(_rotinaData());
        ctrl.treinos[0].exercicios[0].series[0].descanso = '999s';
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });

      test('retorna true quando tipo de uma série muda', () {
        final ctrl = makeCtrl(_rotinaData());
        ctrl.treinos[0].exercicios[0].series[0].tipo = TipoSerie.aquecimento;
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });

      test('retorna true quando uma série é adicionada ao exercício', () {
        final ctrl = makeCtrl(_rotinaData());
        ctrl.treinos[0].exercicios[0].series.add(
          SerieItem(
            tipo: TipoSerie.trabalho,
            alvo: '8',
            carga: '90kg',
            descanso: '90s',
          ),
        );
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });

      test('retorna true quando uma série é removida do exercício', () {
        final data = _rotinaData(
          sessoes: [
            _sessao(
              exercicios: [
                _exercicio(
                  series: [
                    _serie(alvo: '10'),
                    _serie(alvo: '8'),
                  ],
                ),
              ],
            ),
          ],
        );
        final ctrl = makeCtrl(data);
        ctrl.treinos[0].exercicios[0].series.removeLast();
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });

      test('retorna true quando um exercício é adicionado à sessão', () {
        final ctrl = makeCtrl(_rotinaData());
        ctrl.treinos[0].exercicios.add(
          ExercicioItem(nome: 'Novo', grupoMuscular: ['Geral'], series: []),
        );
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });

      test('retorna true quando nome de um exercício muda', () {
        final ctrl = makeCtrl(_rotinaData());
        ctrl.treinos[0].exercicios[0].nome = 'Outro Exercício';
        expect(ctrl.verificarAlteracoes(), isTrue);
        ctrl.dispose();
      });
    });

    group('salvarRotina — integração com Firestore', () {
      test('nova rotina: todas as séries são persistidas', () async {
        final ctrl = RotinaDetalheController(
          alunoId: 'aluno_456',
          rotinaService: service,
          initialData: null,
        );
        ctrl.nomeCtrl.text = 'Rotina de Força';
        ctrl.objCtrl.text = 'Ganho de massa';
        ctrl.adicionarSessao('Treino A', null, '');
        ctrl.treinos[0].exercicios.addAll([
          ExercicioItem(
            nome: 'Supino',
            grupoMuscular: ['Peito'],
            series: [
              SerieItem(
                tipo: TipoSerie.trabalho,
                alvo: '8',
                carga: '100kg',
                descanso: '90s',
              ),
              SerieItem(
                tipo: TipoSerie.aquecimento,
                alvo: '15',
                carga: '50kg',
                descanso: '30s',
              ),
            ],
          ),
        ]);

        final salvo = await ctrl.salvarRotina();
        expect(salvo, isTrue);

        final docs = (await fakeFirestore.collection('rotinas').get()).docs;
        expect(docs.length, 1);

        final series = _extractSeries(
          docs.first.data(),
          sessao: 0,
          exercicio: 0,
        );

        expect(series.length, 2);
        expect(series[0], containsPair('tipo', 'trabalho'));
        expect(series[0], containsPair('alvo', '8'));
        expect(series[0], containsPair('carga', '100kg'));
        expect(series[0], containsPair('descanso', '90s'));
        expect(series[1], containsPair('tipo', 'aquecimento'));

        ctrl.dispose();
      });

      test('rotina existente: carga editada é persistida', () async {
        final docRef = await _seedRotina(fakeFirestore);
        final ctrl = await _ctrlFromDoc(docRef, service);

        ctrl.treinos[0].exercicios[0].series[0].carga = '100kg';

        final salvo = await ctrl.salvarRotina();
        expect(salvo, isTrue);

        final series = _extractSeries(
          (await docRef.get()).data()!,
          sessao: 0,
          exercicio: 0,
        );
        expect(series[0], containsPair('carga', '100kg'));

        ctrl.dispose();
      });

      test('rotina existente: série adicionada é persistida', () async {
        final docRef = await _seedRotina(fakeFirestore);
        final ctrl = await _ctrlFromDoc(docRef, service);

        ctrl.treinos[0].exercicios[0].series.add(
          SerieItem(
            tipo: TipoSerie.trabalho,
            alvo: '8',
            carga: '110kg',
            descanso: '90s',
          ),
        );

        final salvo = await ctrl.salvarRotina();
        expect(salvo, isTrue);

        final series = _extractSeries(
          (await docRef.get()).data()!,
          sessao: 0,
          exercicio: 0,
        );
        expect(series.length, 2);
        expect(series[1], containsPair('alvo', '8'));
        expect(series[1], containsPair('carga', '110kg'));

        ctrl.dispose();
      });

      test(
        'rotina existente: série removida não aparece no Firestore',
        () async {
          final docRef = await _seedRotina(fakeFirestore, numSeries: 3);
          final ctrl = await _ctrlFromDoc(docRef, service);

          ctrl.treinos[0].exercicios[0].series.removeLast();

          final salvo = await ctrl.salvarRotina();
          expect(salvo, isTrue);

          final series = _extractSeries(
            (await docRef.get()).data()!,
            sessao: 0,
            exercicio: 0,
          );
          expect(series.length, 2);

          ctrl.dispose();
        },
      );

      test(
        'verificarAlteracoes retorna true antes de salvar quando série muda',
        () async {
          final docRef = await _seedRotina(fakeFirestore);
          final ctrl = await _ctrlFromDoc(docRef, service);

          expect(
            ctrl.verificarAlteracoes(),
            isFalse,
            reason: 'sem mudança: deve ser false',
          );

          ctrl.treinos[0].exercicios[0].series[0].alvo = '20';
          expect(
            ctrl.verificarAlteracoes(),
            isTrue,
            reason: 'com mudança: deve ser true',
          );

          ctrl.dispose();
        },
      );
    });
  });
}


List<dynamic> _extractSeries(
  Map<String, dynamic> doc, {
  required int sessao,
  required int exercicio,
}) {
  final sessoes = doc['sessoes'] as List;
  final exercicios = sessoes[sessao]['exercicios'] as List;
  return exercicios[exercicio]['series'] as List;
}

Future<DocumentReference<Map<String, dynamic>>> _seedRotina(
  FakeFirebaseFirestore db, {
  int numSeries = 1,
}) async {
  return db.collection('rotinas').add({
    'nome': 'Rotina Existente',
    'objetivo': 'Força',
    'tipoVencimento': 'sessoes',
    'vencimentoSessoes': 20,
    'ativa': true,
    'personalId': 'personal_123',
    'sessoes': [
      {
        'nome': 'Treino A',
        'diaSemana': '',
        'orientacoes': '',
        'exercicios': [
          {
            'nome': 'Supino',
            'grupoMuscular': ['Peito'],
            'tipoAlvo': 'Reps',
            'series': List.generate(
              numSeries,
              (i) => {
                'tipo': 'trabalho',
                'alvo': '${10 - i}',
                'carga': '80kg',
                'descanso': '60s',
              },
            ),
          },
        ],
      },
    ],
  });
}

Future<RotinaDetalheController> _ctrlFromDoc(
  DocumentReference<Map<String, dynamic>> docRef,
  RotinaService service,
) async {
  final snapshot = await docRef.get();
  return RotinaDetalheController(
    rotinaId: docRef.id,
    rotinaService: service,
    initialData: snapshot.data()!,
  );
}
