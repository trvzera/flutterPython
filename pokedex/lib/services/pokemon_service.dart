import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PokemonService {
  // Informe o IP do computador ao executar em um aparelho físico.
  static const String _base = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://127.0.0.1:5001',
  );

  static Future<dynamic> _get(String path) async {
    try {
      final uri = Uri.parse('${_base.replaceAll(RegExp(r'/+$'), '')}$path');
      final resposta = await http.get(uri).timeout(const Duration(seconds: 60));
      if (resposta.statusCode == 404) {
        throw Exception('Pokémon não encontrado. Confira o nome ou ID.');
      }
      if (resposta.statusCode != 200) {
        throw Exception('Erro ${resposta.statusCode} ao consultar o servidor.');
      }
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on TimeoutException {
      throw Exception('O servidor demorou para responder.');
    } on http.ClientException {
      throw Exception('Não foi possível conectar ao Flask em $_base.');
    } on FormatException {
      throw Exception('Resposta inválida do Flask.');
    }
  }

  static Future<List<dynamic>> buscarPokemons() async {
    final dados = await _get('/pokemons');
    return dados as List<dynamic>;
  }

  static Future<Map<String, dynamic>> buscarDetalhes(int id) async {
    return (await _get('/pokemons/$id')) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> buscarPorNome(String nome) async {
    return (await _get('/pokemons/nome/${Uri.encodeComponent(nome.trim().toLowerCase())}'))
        as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> buscarAleatorio() async {
    return (await _get('/pokemons/aleatorio')) as Map<String, dynamic>;
  }
}
