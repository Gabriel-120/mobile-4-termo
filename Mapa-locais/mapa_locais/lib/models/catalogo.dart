import 'package:latlong2/latlong.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'local.dart';

const cidades = ['São Paulo', 'Campinas', 'Jundiaí'];
const categorias = ['Academia', 'Restaurante', 'Parque', 'Cultura', 'Hospital'];
const centros = {
  'São Paulo': LatLng(-23.5505, -46.6333),
  'Campinas': LatLng(-22.9056, -47.0608),
  'Jundiaí': LatLng(-23.1857, -46.8978),
};
String normalizar(String text) => unorm
    .nfd(text.trim().toLowerCase())
    .replaceAll(RegExp(r'[\u0300-\u036f]'), '');
List<Local> filtrarLocais(
  List<Local> locais, {
  String texto = '',
  String cidade = 'Todas',
  String categoria = 'Todas',
  bool favoritos = false,
}) {
  final termo = normalizar(texto);
  final resultado = locais
      .where(
        (local) =>
            (cidade == 'Todas' || local.cidade == cidade) &&
            (categoria == 'Todas' || local.categoria == categoria) &&
            (!favoritos || local.favorito) &&
            (normalizar(local.nome).contains(termo) ||
                normalizar(local.categoria).contains(termo)),
      )
      .toList();
  resultado.sort((a, b) => a.nome.compareTo(b.nome));
  return resultado;
}
