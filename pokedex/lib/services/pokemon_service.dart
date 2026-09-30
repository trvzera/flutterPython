import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class ApiException implements Exception {
  final String mensagem;
  const ApiException(this.mensagem);
  @override
  String toString() => mensagem;
}

// Todas as requisições de dados ficam aqui e usam somente o Flask.
class PokemonService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );

  Future<dynamic> _get(String caminho, [Map<String, String>? parametros]) async {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base$caminho').replace(queryParameters: parametros);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      if (response.statusCode == 404) {
        throw const ApiException('Pokémon não encontrado. Confira o nome ou ID.');
      }
      if (response.statusCode != 200) {
        throw ApiException('O servidor retornou o erro ${response.statusCode}. Tente novamente.');
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar ao Flask. Confira o endereço e se o servidor está ligado.');
    } on FormatException {
      throw const ApiException('O servidor retornou uma resposta inválida.');
    }
  }

  Future<List<Pokemon>> listar({int limit = 20, int offset = 0}) async {
    final json = await _get('/pokemons', {'limit': '$limit', 'offset': '$offset'});
    // A API fornecida retorna {pokemons: [...], total: ...}.
    final List<dynamic> lista = json is List
        ? json
        : (json as Map<String, dynamic>)['pokemons'] as List<dynamic>;
    return lista.map((item) => Pokemon.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Pokemon> buscarPorNome(String nome) async {
    final json = await _get('/pokemons/nome/${Uri.encodeComponent(nome.trim().toLowerCase())}');
    return Pokemon.fromJson(json as Map<String, dynamic>);
  }

  Future<Pokemon> buscarPorId(int id) async {
    final json = await _get('/pokemons/$id');
    return Pokemon.fromJson(json as Map<String, dynamic>);
  }

  Future<Pokemon> aleatorio() async {
    final json = await _get('/pokemons/aleatorio');
    return Pokemon.fromJson(json as Map<String, dynamic>);
  }
}
