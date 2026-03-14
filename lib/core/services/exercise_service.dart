import 'dart:convert';
import 'dart:io'; // <-- Importante para capturar o erro de Socket
import 'package:http/http.dart' as http;
import '../../features/treinos/models/exercicio_model.dart';

class ExerciseService {
  final String _baseUrl = 'https://www.exercisedb.dev/api/v1/exercises';

  Future<List<ExercicioItem>> buscarTodos() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> listaRaw = data['data'];
        return listaRaw.map((item) => ExercicioItem.fromApi(item)).toList();
      } else {
        throw Exception('A API respondeu com erro: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet. Verifique o seu Wi-Fi.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado: $e');
    }
  }
}
