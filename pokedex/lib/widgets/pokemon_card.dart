import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonImage extends StatelessWidget {
  final Pokemon pokemon;
  final double size;
  const PokemonImage({super.key, required this.pokemon, this.size = 96});
  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.catching_pokemon, size: size * .6, color: Colors.grey);
    if (pokemon.imagem == null) return SizedBox(width: size, height: size, child: fallback);
    return Image.network(
      pokemon.imagem!, width: size, height: size, fit: BoxFit.contain,
      errorBuilder: (_, error, stackTrace) => SizedBox(width: size, height: size, child: fallback),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : SizedBox(width: size, height: size,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;
  const PokemonCard({super.key, required this.pokemon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            PokemonImage(pokemon: pokemon),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${pokemon.id.toString().padLeft(3, '0')}',
                  style: const TextStyle(color: Colors.grey)),
              Text(pokemon.nomeFormatado,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: pokemon.tipos
                  .map((tipo) => Chip(label: Text(tipo), visualDensity: VisualDensity.compact)).toList()),
            ])),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}
