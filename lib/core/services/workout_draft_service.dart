import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/treinos/shared/models/rotina_model.dart';

class WorkoutDraft {
  final String alunoId;
  final String rotinaId;
  final SessaoTreinoModel sessao;
  final DateTime startedAt;
  final Map<String, dynamic> recordedData;
  final DateTime lastUpdated;

  WorkoutDraft({
    required this.alunoId,
    required this.rotinaId,
    required this.sessao,
    required this.startedAt,
    required this.recordedData,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'alunoId': alunoId,
        'rotinaId': rotinaId,
        'sessao': sessao.toMap(),
        'startedAt': startedAt.toIso8601String(),
        'recordedData': recordedData,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory WorkoutDraft.fromJson(Map<String, dynamic> json) => WorkoutDraft(
        alunoId: json['alunoId'],
        rotinaId: json['rotinaId'],
        sessao: SessaoTreinoModel.fromMap(json['sessao']),
        startedAt: DateTime.parse(json['startedAt']),
        recordedData: json['recordedData'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

class WorkoutDraftService {
  static const String _key = 'workout_draft';

  Future<void> saveDraft(WorkoutDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  Future<WorkoutDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    try {
      final decoded = jsonDecode(data);
      return WorkoutDraft.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}