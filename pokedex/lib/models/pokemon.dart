// Contrato do Flask: altura em decímetros e peso em hectogramas.
class Pokemon {
  final int id;
  final String nome;
  final String? imagem;
  final List<String> tipos;
  final double altura;
  final double peso;
  final int experiencia;
  final List<String> habilidades;
  final Map<String, int> atributos;

  const Pokemon({
    required this.id,
    required this.nome,
    this.imagem,
    required this.tipos,
    required this.altura,
    required this.peso,
    required this.experiencia,
    required this.habilidades,
    required this.atributos,
  });

  String get nomeFormatado => nome.isEmpty
      ? 'Pokémon'
      : nome[0].toUpperCase() + nome.substring(1).replaceAll('-', ' ');
  double get alturaMetros => altura / 10;
  double get pesoQuilos => peso / 10;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final tiposJson = json['tipos'] ?? json['tipo'];
    final imagemJson = json['imagem'];
    return Pokemon(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      imagem: imagemJson is String && imagemJson.isNotEmpty ? imagemJson : null,
      tipos: tiposJson is List
          ? tiposJson.map((e) => e.toString()).toList()
          : tiposJson is String ? [tiposJson] : [],
      altura: (json['altura'] as num? ?? 0).toDouble(),
      peso: (json['peso'] as num? ?? 0).toDouble(),
      experiencia: (json['experiencia'] as num? ?? 0).toInt(),
      habilidades: (json['habilidades'] as List? ?? [])
          .map((e) => e.toString()).toList(),
      atributos: (json['atributos'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toInt())),
    );
  }
}
