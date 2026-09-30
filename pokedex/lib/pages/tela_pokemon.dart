import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pokemon_provider.dart';
import 'tela_detalhes_pokemon.dart';

class TelaPokemon extends StatefulWidget {
  const TelaPokemon({super.key});

  @override
  State<TelaPokemon> createState() => _TelaPokemonState();
}

class _TelaPokemonState extends State<TelaPokemon> {
  final _nome = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PokemonProvider>().carregarPokemons();
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _abrir(dynamic pokemon) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TelaDetalhesPokemon(idPokemon: pokemon['id'] as int),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PokemonProvider>();
    final lista = provider.pesquisou
        ? (provider.resultadoBusca == null ? <dynamic>[] : [provider.resultadoBusca!])
        : provider.pokemons;
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                controller: _nome,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => context.read<PokemonProvider>().pesquisar(_nome.text),
                decoration: InputDecoration(
                  labelText: 'Nome ou ID do Pokémon',
                  hintText: 'pikachu ou 25',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Limpar',
                    onPressed: () {
                      _nome.clear();
                      provider.limparPesquisa();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ElevatedButton.icon(
                  onPressed: provider.carregandoBusca ? null : () {
                    FocusScope.of(context).unfocus();
                    provider.pesquisar(_nome.text);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Pesquisar'),
                ),
                OutlinedButton.icon(
                  onPressed: provider.carregandoBusca ? null : () {
                    _nome.clear();
                    FocusScope.of(context).unfocus();
                    provider.buscarAleatorio();
                  },
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Pokémon Aleatório'),
                ),
              ]),
              if (provider.pesquisou)
                TextButton(
                  onPressed: () {
                    _nome.clear();
                    provider.limparPesquisa();
                  },
                  child: const Text('Voltar para a lista'),
                ),
            ]),
          ),
          if (provider.carregandoBusca || provider.carregandoLista)
            const LinearProgressIndicator(),
          if (provider.erroBusca != null || provider.erroLista != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(provider.pesquisou
                  ? provider.erroBusca ?? ''
                  : provider.erroLista ?? '', textAlign: TextAlign.center),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (_, index) {
                final pokemon = lista[index];
                final imagem = pokemon['imagem'] as String?;
                return Card(child: ListTile(
                  leading: imagem == null
                      ? const Icon(Icons.catching_pokemon, size: 42)
                      : Image.network(imagem, width: 60,
                          errorBuilder: (_, error, trace) =>
                              const Icon(Icons.catching_pokemon, size: 42)),
                  title: Text(pokemon['nome'].toString().toUpperCase()),
                  subtitle: Text('Tipo: ${pokemon['tipo']}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _abrir(pokemon),
                ));
              },
            ),
          ),
          if (!provider.pesquisou && provider.erroLista != null)
            TextButton(onPressed: provider.carregarPokemons,
                child: const Text('Tentar carregar novamente')),
        ]),
      ))),
    );
  }
}
