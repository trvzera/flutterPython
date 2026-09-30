import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../providers/pokemon_provider.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pesquisa = TextEditingController();
  @override
  void dispose() {
    _pesquisa.dispose();
    super.dispose();
  }

  void _pesquisar() {
    FocusScope.of(context).unfocus();
    context.read<PokemonProvider>().pesquisar(_pesquisa.text);
  }

  void _abrir(Pokemon pokemon) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PokemonDetailScreen(id: pokemon.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PokemonProvider>();
    final visiveis = state.pesquisou
        ? (state.resultado == null ? <Pokemon>[] : [state.resultado!])
        : state.pokemons;
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex'), centerTitle: true),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            TextField(
              controller: _pesquisa,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _pesquisar(),
              decoration: InputDecoration(
                labelText: 'Nome ou ID do Pokémon',
                hintText: 'pikachu ou 25',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Limpar pesquisa', icon: const Icon(Icons.close),
                  onPressed: () {
                    _pesquisa.clear();
                    state.limparPesquisa();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: state.carregandoBusca ? null : _pesquisar,
                icon: const Icon(Icons.search), label: const Text('Pesquisar'),
              ),
              OutlinedButton.icon(
                onPressed: state.carregandoBusca ? null : () {
                  FocusScope.of(context).unfocus();
                  _pesquisa.clear();
                  state.sortear();
                },
                icon: const Icon(Icons.shuffle), label: const Text('Pokémon aleatório'),
              ),
            ]),
          ])),
          if (state.pesquisou)
            TextButton(onPressed: () {
              _pesquisa.clear();
              state.limparPesquisa();
            }, child: const Text('Voltar para a lista')),
          Expanded(child: state.carregandoBusca
              ? const Center(child: CircularProgressIndicator())
              : state.pesquisou && state.erroBusca != null
                  ? _Erro(mensagem: state.erroBusca!, repetir: _pesquisar)
                  : !state.pesquisou && state.carregandoLista && visiveis.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : !state.pesquisou && state.erroLista != null && visiveis.isEmpty
                          ? _Erro(mensagem: state.erroLista!, repetir: () => state.carregarLista())
                          : RefreshIndicator(
                              onRefresh: () async {
                                _pesquisa.clear();
                                state.limparPesquisa();
                                await state.carregarLista(reiniciar: true);
                              },
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                                itemCount: visiveis.length + (state.pesquisou ? 0 : 1),
                                itemBuilder: (_, index) {
                                  if (index < visiveis.length) {
                                    final pokemon = visiveis[index];
                                    return PokemonCard(pokemon: pokemon, onTap: () => _abrir(pokemon));
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(children: [
                                      if (state.erroLista != null) Text(state.erroLista!, textAlign: TextAlign.center),
                                      if (state.carregandoLista) const CircularProgressIndicator()
                                      else if (state.temMais) OutlinedButton(
                                        onPressed: () => state.carregarLista(),
                                        child: const Text('Carregar mais'),
                                      ) else const Text('Todos os Pokémon foram carregados.'),
                                    ]),
                                  );
                                },
                              ),
                            )),
        ]),
      ))),
    );
  }
}

class _Erro extends StatelessWidget {
  final String mensagem;
  final VoidCallback repetir;
  const _Erro({required this.mensagem, required this.repetir});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.info_outline, size: 40),
      const SizedBox(height: 12),
      Text(mensagem, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton(onPressed: repetir, child: const Text('Tentar novamente')),
    ]),
  ));
}
