import 'package:flutter/material.dart';
import '../services/pokemon_service.dart';

class PokemonProvider extends ChangeNotifier {
  List<dynamic> pokemons = [];
  Map<String, dynamic>? pokemonSelecionado;
  Map<String, dynamic>? resultadoBusca;
  bool carregandoLista = false;
  bool carregandoBusca = false;
  bool carregando = false; // Estado da tela de detalhes existente.
  bool pesquisou = false;
  String? erroLista;
  String? erroBusca;
  String? erroDetalhes;
  int _buscaAtual = 0;
  int _detalheAtual = 0;
  bool _disposed = false;

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  String _mensagem(Object erro) => erro.toString().replaceFirst('Exception: ', '');

  Future<void> carregarPokemons() async {
    if (carregandoLista) return;
    carregandoLista = true;
    erroLista = null;
    _avisar();
    try {
      pokemons = await PokemonService.buscarPokemons();
    } catch (erro) {
      erroLista = _mensagem(erro);
    } finally {
      carregandoLista = false;
      _avisar();
    }
  }

  Future<void> pesquisar(String nome) async {
    final termo = nome.trim();
    if (termo.isEmpty) {
      limparPesquisa();
      return;
    }
    await _buscar(() async {
      final id = int.tryParse(termo);
      if (id != null) return PokemonService.buscarDetalhes(id);
      return PokemonService.buscarPorNome(termo);
    });
  }

  Future<void> buscarAleatorio() => _buscar(PokemonService.buscarAleatorio);

  Future<void> _buscar(Future<Map<String, dynamic>> Function() consulta) async {
    final atual = ++_buscaAtual;
    pesquisou = true;
    resultadoBusca = null;
    erroBusca = null;
    carregandoBusca = true;
    _avisar();
    try {
      final resultado = await consulta();
      if (atual == _buscaAtual) resultadoBusca = resultado;
    } catch (erro) {
      if (atual == _buscaAtual) erroBusca = _mensagem(erro);
    } finally {
      if (atual == _buscaAtual) {
        carregandoBusca = false;
        _avisar();
      }
    }
  }

  void limparPesquisa() {
    _buscaAtual++;
    pesquisou = false;
    resultadoBusca = null;
    carregandoBusca = false;
    erroBusca = null;
    _avisar();
  }

  Future<void> carregarDetalhes(int id) async {
    final atual = ++_detalheAtual;
    carregando = true;
    erroDetalhes = null;
    pokemonSelecionado = null;
    _avisar();
    try {
      final detalhes = await PokemonService.buscarDetalhes(id);
      if (atual == _detalheAtual) pokemonSelecionado = detalhes;
    } catch (erro) {
      if (atual == _detalheAtual) erroDetalhes = _mensagem(erro);
    } finally {
      if (atual == _detalheAtual) {
        carregando = false;
        _avisar();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
