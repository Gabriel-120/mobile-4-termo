import 'package:flutter/material.dart';

import '../models/local.dart';
import '../services/local_service.dart';
import '../widgets/common.dart';

class DetalhesScreen extends StatefulWidget {
  const DetalhesScreen({super.key, required this.id, required this.repository});
  final String id;
  final LocalRepository repository;
  @override
  State<DetalhesScreen> createState() => _DetalhesScreenState();
}

class _DetalhesScreenState extends State<DetalhesScreen> {
  late Stream<Local?> stream;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    stream = widget.repository.observar(widget.id);
  }

  Future<void> favorite(Local local) async {
    setState(() => busy = true);
    try {
      await widget.repository.alterarFavorito(local.id, !local.favorito);
      if (mounted) {
        feedback(
          context,
          local.favorito
              ? 'Removido dos favoritos.'
              : 'Adicionado aos favoritos.',
        );
      }
    } catch (e) {
      if (mounted) feedback(context, mensagemErro(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Local?>(
    stream: stream,
    builder: (context, s) {
      final local = s.data;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes'),
          actions: [
            if (local != null)
              IconButton(
                key: const Key('favorite'),
                tooltip: local.favorito
                    ? 'Desmarcar favorito'
                    : 'Marcar favorito',
                onPressed: busy ? null : () => favorite(local),
                icon: Icon(
                  local.favorito ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFB64F5B),
                ),
              ),
          ],
        ),
        body: s.hasError
            ? LoadState(
                error: s.error,
                retry: () => setState(
                  () => stream = widget.repository.observar(widget.id),
                ),
              )
            : s.connectionState == ConnectionState.waiting
            ? const LoadState()
            : local == null
            ? const LoadState(empty: true)
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  LocalImage(local: local, height: 210),
                  const SizedBox(height: 22),
                  Text(
                    local.nome,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${local.categoria} • ${local.cidade}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      Chip(
                        avatar: const Icon(
                          Icons.star,
                          size: 18,
                          color: Color(0xFFC58D30),
                        ),
                        label: Text(
                          '${local.avaliacao.toStringAsFixed(1)} / 5',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.near_me, size: 18),
                        label: Text(
                          '${local.distancia.toStringAsFixed(1)} km • referência',
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Horário'),
                    subtitle: Text(local.horario),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined),
                    title: const Text('Endereço'),
                    subtitle: Text(local.endereco),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Sobre o local',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(local.descricao, style: const TextStyle(height: 1.6)),
                  const SizedBox(height: 20),
                  Text(
                    'Coordenadas: ${local.latitude.toStringAsFixed(5)}, ${local.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Dados de demonstração: horários, avaliações e distâncias são didáticos.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('see-map'),
                    onPressed: () => Navigator.pop(context, local),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver no mapa'),
                  ),
                ],
              ),
      );
    },
  );
}
