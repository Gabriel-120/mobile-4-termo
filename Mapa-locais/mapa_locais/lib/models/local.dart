class Local {
  const Local({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.cidade,
    required this.avaliacao,
    required this.distancia,
    required this.horario,
    required this.descricao,
    required this.favorito,
    required this.latitude,
    required this.longitude,
    required this.endereco,
  });
  final String id, nome, categoria, cidade, horario, descricao, endereco;
  final double avaliacao, distancia, latitude, longitude;
  final bool favorito;
  factory Local.fromMap(String id, Map<String, dynamic> data) => Local(
    id: id,
    nome: data['nome'] as String,
    categoria: data['categoria'] as String,
    cidade: data['cidade'] as String,
    avaliacao: (data['avaliacao'] as num).toDouble(),
    distancia: (data['distancia'] as num).toDouble(),
    horario: data['horario'] as String,
    descricao: data['descricao'] as String,
    favorito: data['favorito'] as bool,
    latitude: (data['latitude'] as num).toDouble(),
    longitude: (data['longitude'] as num).toDouble(),
    endereco: data['endereco'] as String,
  );
  Map<String, dynamic> toMap() => {
    'nome': nome,
    'categoria': categoria,
    'cidade': cidade,
    'avaliacao': avaliacao,
    'distancia': distancia,
    'horario': horario,
    'descricao': descricao,
    'favorito': favorito,
    'latitude': latitude,
    'longitude': longitude,
    'endereco': endereco,
  };
}
