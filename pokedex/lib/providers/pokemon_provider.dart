import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

class PokemonProvider extends ChangeNotifier {
  final PokemonService _service;
  PokemonProvider(this._service);

  final List<Pokemon> _pokemons = [];
  List<Pokemon> get pokemons => List.unmodifiable(_pokemons);
  Pokemon? resultado;
  Pokemon? detalhe;
  String? erroLista;
  String? erroBusca;
  String? erroDetalhe;
  bool carregandoLista = false;
  bool carregandoBusca = false;
  bool carregandoDetalhe = false;
  bool temMais = true;
  bool get pesquisou => _pesquisou;
  bool _pesquisou = false;
  int _buscaVersao = 0;
  int _detalheVersao = 0;

  String _mensagem(Object erro) => erro is ApiException
      ? erro.mensagem
      : 'Não foi possível ler os dados. Confira o contrato JSON do Flask.';

  Future<void> carregarLista({bool reiniciar = false}) async {
    if (carregandoLista || (!temMais && !reiniciar)) return;
    carregandoLista = true;
    erroLista = null;
    if (reiniciar) {
      _pokemons.clear();
      temMais = true;
    }
    notifyListeners();
    try {
      final novos = await _service.listar(offset: _pokemons.length);
      _pokemons.addAll(novos);
      temMais = novos.length == 20;
    } catch (erro) {
      erroLista = _mensagem(erro);
    } finally {
      carregandoLista = false;
      notifyListeners();
    }
  }

  Future<void> pesquisar(String texto) async {
    final termo = texto.trim().toLowerCase();
    if (termo.isEmpty) {
      limparPesquisa();
      return;
    }
    await _buscar(() {
      final id = int.tryParse(termo);
      return id != null ? _service.buscarPorId(id) : _service.buscarPorNome(termo);
    });
  }

  Future<void> sortear() => _buscar(_service.aleatorio);

  Future<void> _buscar(Future<Pokemon> Function() consulta) async {
    final versao = ++_buscaVersao;
    _pesquisou = true;
    carregandoBusca = true;
    resultado = null;
    erroBusca = null;
    notifyListeners();
    try {
      final pokemon = await consulta();
      if (versao == _buscaVersao) resultado = pokemon;
    } catch (erro) {
      if (versao == _buscaVersao) erroBusca = _mensagem(erro);
    } finally {
      if (versao == _buscaVersao) {
        carregandoBusca = false;
        notifyListeners();
      }
    }
  }

  void limparPesquisa() {
    _buscaVersao++;
    _pesquisou = false;
    carregandoBusca = false;
    resultado = null;
    erroBusca = null;
    notifyListeners();
  }

  Future<void> carregarDetalhe(int id) async {
    final versao = ++_detalheVersao;
    carregandoDetalhe = true;
    detalhe = null;
    erroDetalhe = null;
    notifyListeners();
    try {
      final pokemon = await _service.buscarPorId(id);
      if (versao == _detalheVersao) detalhe = pokemon;
    } catch (erro) {
      if (versao == _detalheVersao) erroDetalhe = _mensagem(erro);
    } finally {
      if (versao == _detalheVersao) {
        carregandoDetalhe = false;
        notifyListeners();
      }
    }
  }
}
