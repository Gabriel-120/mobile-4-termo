import 'package:flutter/material.dart';

import '../models/local.dart';
import '../services/local_service.dart';

const ink = Color(0xFF183D3A);
const paper = Color(0xFFF7F8F4);
IconData categoryIcon(String category) => switch (category) {
  'Academia' => Icons.fitness_center,
  'Restaurante' => Icons.restaurant,
  'Parque' => Icons.park,
  'Hospital' => Icons.local_hospital,
  _ => Icons.museum,
};

class LocalImage extends StatelessWidget {
  const LocalImage({super.key, required this.local, this.height = 180});
  final Local local;
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ilustração de ${local.categoria}',
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCECE2), Color(0xFFACCBC1)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            top: -35,
            child: Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                color: Color(0x55FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Icon(categoryIcon(local.categoria), size: height * .45, color: ink),
          if (height >= 120)
            Positioned(
              bottom: 10,
              right: 12,
              child: Text(
                'ILUSTRAÇÃO',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: ink.withValues(alpha: .7),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class LoadState extends StatelessWidget {
  const LoadState({super.key, this.error, this.empty = false, this.retry});
  final Object? error;
  final bool empty;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error == null && !empty)
            const CircularProgressIndicator()
          else
            Icon(
              error != null ? Icons.cloud_off : Icons.search_off,
              size: 44,
              color: ink,
            ),
          const SizedBox(height: 16),
          Text(
            error != null
                ? mensagemErro(error!)
                : empty
                ? 'Nenhum local encontrado.'
                : 'Carregando locais do Firestore…',
            textAlign: TextAlign.center,
            key: const Key('load-message'),
          ),
          if (error != null && retry != null)
            TextButton(onPressed: retry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}

void feedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class LocalCard extends StatelessWidget {
  const LocalCard({
    super.key,
    required this.local,
    required this.open,
    this.edit,
    this.delete,
  });
  final Local local;
  final VoidCallback open;
  final VoidCallback? edit, delete;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(width: 64, child: LocalImage(local: local, height: 76)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    local.nome,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    local.categoria,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '★ ${local.avaliacao.toStringAsFixed(1)}   •   ${local.distancia.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    local.cidade,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (local.favorito)
              const Icon(Icons.favorite, size: 16, color: Color(0xFFB64F5B)),
            if (edit != null)
              PopupMenuButton<String>(
                tooltip: 'Ações de ${local.nome}',
                onSelected: (v) => v == 'edit' ? edit!() : delete!(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              )
            else
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
