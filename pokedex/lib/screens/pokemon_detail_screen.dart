import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pokemon_provider.dart';
import '../widgets/pokemon_card.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int id;
  const PokemonDetailScreen({super.key, required this.id});
  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PokemonProvider>().carregarDetalhe(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PokemonProvider>();
    final pokemon = state.detalhe;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Pokémon')),
      body: state.carregandoDetalhe
          ? const Center(child: CircularProgressIndicator())
          : state.erroDetalhe != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(state.erroDetalhe!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => state.carregarDetalhe(widget.id),
                      child: const Text('Tentar novamente'),
                    ),
                  ])))
              : pokemon == null || pokemon.id != widget.id
                  ? const Center(child: CircularProgressIndicator())
                  : Center(child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView(padding: const EdgeInsets.all(24), children: [
                        Center(child: PokemonImage(pokemon: pokemon, size: 220)),
                        Text(pokemon.nomeFormatado, textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        Text('#${pokemon.id.toString().padLeft(3, '0')}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Wrap(alignment: WrapAlignment.center, spacing: 8,
                            children: pokemon.tipos.map((t) => Chip(label: Text(t))).toList()),
                        const SizedBox(height: 20),
                        Card(child: Column(children: [
                          ListTile(leading: const Icon(Icons.height), title: const Text('Altura'),
                              trailing: Text('${pokemon.alturaMetros.toStringAsFixed(1)} m')),
                          ListTile(leading: const Icon(Icons.monitor_weight_outlined), title: const Text('Peso'),
                              trailing: Text('${pokemon.pesoQuilos.toStringAsFixed(1)} kg')),
                          ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Experiência base'),
                              trailing: Text('${pokemon.experiencia} XP')),
                        ])),
                        const SizedBox(height: 20),
                        const Text('Habilidades', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (pokemon.habilidades.isEmpty) const Text('Nenhuma habilidade informada.')
                        else Wrap(spacing: 8, runSpacing: 8, children: pokemon.habilidades
                            .map((h) => Chip(label: Text(h.replaceAll('-', ' ')))).toList()),
                        const SizedBox(height: 24),
                        const Text('Atributos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...pokemon.atributos.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [Expanded(child: Text(_rotulo(entry.key))), Text('${entry.value}')]),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: (entry.value / 255).clamp(0.0, 1.0), minHeight: 8),
                          ]),
                        )),
                      ]),
                    )),
    );
  }

  String _rotulo(String chave) => const {
    'hp': 'HP', 'attack': 'Ataque', 'defense': 'Defesa',
    'special-attack': 'Ataque especial', 'special-defense': 'Defesa especial', 'speed': 'Velocidade',
  }[chave] ?? chave;
}
