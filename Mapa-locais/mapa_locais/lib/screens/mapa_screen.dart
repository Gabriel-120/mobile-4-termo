import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/local.dart';
import '../models/catalogo.dart';
import '../services/local_service.dart';
import '../widgets/common.dart';
import 'resultados_screen.dart';
import 'detalhes_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({
    super.key,
    required this.repository,
    required this.session,
    required this.account,
    this.tiles = true,
  });
  final LocalRepository repository;
  final Session session;
  final VoidCallback account;
  final bool tiles;
  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  String city = 'São Paulo';
  final search = TextEditingController();
  final map = MapController();
  late Stream<List<Local>> stream;
  Local? focus;
  bool tileError = false;
  bool mapReady = false;
  @override
  void initState() {
    super.initState();
    stream = widget.repository.listarLocais();
  }

  @override
  void dispose() {
    search.dispose();
    map.dispose();
    super.dispose();
  }

  void target(Local local) {
    setState(() {
      city = local.cidade;
      focus = local;
      search.clear();
    });
    map.move(LatLng(local.latitude, local.longitude), 16);
  }

  Future<void> results({bool favorites = false}) async {
    final selected = await Navigator.push<Local>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadosScreen(
          repository: widget.repository,
          admin: widget.session.admin,
          cidade: city,
          pesquisa: search.text,
          favoritos: favorites,
        ),
      ),
    );
    if (selected != null && mounted) target(selected);
  }

  Future<void> details(Local local) async {
    final selected = await Navigator.push<Local>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetalhesScreen(id: local.id, repository: widget.repository),
      ),
    );
    if (selected != null && mounted) target(selected);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MAPA DE LOCAIS',
            style: TextStyle(fontSize: 10, letterSpacing: 2.3),
          ),
          Text(
            'Explore sua cidade',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Conta e permissões',
          onPressed: widget.account,
          icon: const Icon(Icons.person_outline),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        if (i == 1) results(favorites: true);
        if (i == 2) widget.account();
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          label: 'Favoritos',
        ),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Conta'),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('map-city-$city'),
                initialValue: city,
                decoration: const InputDecoration(
                  labelText: 'Cidade selecionada',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                items: cidades
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    city = v!;
                    focus = null;
                  });
                  if (mapReady) map.move(centros[city]!, 13);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('map-search'),
                controller: search,
                onSubmitted: (_) => results(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar nome ou categoria',
                  suffixIcon: IconButton(
                    tooltip: 'Abrir resultados',
                    onPressed: results,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Local>>(
            stream: stream,
            builder: (context, s) {
              if (s.hasError) {
                return LoadState(
                  error: s.error,
                  retry: () =>
                      setState(() => stream = widget.repository.listarLocais()),
                );
              }
              if (!s.hasData) return const LoadState();
              final list = filtrarLocais(
                s.data!,
                cidade: city,
                texto: search.text,
              );
              return Stack(
                children: [
                  FlutterMap(
                    mapController: map,
                    options: MapOptions(
                      onMapReady: () => mapReady = true,
                      initialCenter: centros[city]!,
                      initialZoom: 13,
                      minZoom: 5,
                      maxZoom: 18,
                      backgroundColor: const Color(0xFFE4EBE5),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      if (widget.tiles)
                        TileLayer(
                          key: ValueKey(tileError),
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'br.com.sage.mapa_locais',
                          maxNativeZoom: 19,
                          panBuffer: 0,
                          errorTileCallback: (_, _, _) {
                            if (!tileError && mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => tileError = true);
                              });
                            }
                          },
                        ),
                      MarkerLayer(
                        markers: list
                            .map(
                              (l) => Marker(
                                point: LatLng(l.latitude, l.longitude),
                                width: 46,
                                height: 46,
                                child: IconButton(
                                  key: Key('marker-${l.id}'),
                                  tooltip: l.nome,
                                  onPressed: () => details(l),
                                  icon: Icon(
                                    Icons.location_on,
                                    size: focus?.id == l.id ? 42 : 34,
                                    color: focus?.id == l.id
                                        ? const Color(0xFFB64F5B)
                                        : ink,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Text(
                              list.isEmpty
                                  ? 'Nenhum local encontrado.'
                                  : '${list.length} locais em $city',
                              key: const Key('marker-count'),
                            ),
                          ),
                        ),
                        if (tileError)
                          const Card(
                            color: Color(0xFFFFF1D9),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Mapa indisponível. Confira a internet.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 100,
                    child: FloatingActionButton.small(
                      heroTag: 'center',
                      tooltip: 'Centralizar cidade',
                      onPressed: () => map.move(centros[city]!, 13),
                      child: const Icon(Icons.center_focus_strong),
                    ),
                  ),
                  Positioned(
                    bottom: 46,
                    left: 20,
                    right: 20,
                    child: FilledButton.icon(
                      key: const Key('open-results'),
                      onPressed: results,
                      icon: const Icon(Icons.search),
                      label: const Text('Ver resultados'),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Material(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 11, color: ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
