import 'package:flutter/material.dart';

import '../models/local.dart';
import '../models/catalogo.dart';
import '../services/local_service.dart';
import '../widgets/common.dart';
import '../widgets/local_form.dart';
import '../dialogs/confirm_delete.dart';
import 'detalhes_screen.dart';

class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({
    super.key,
    required this.repository,
    required this.admin,
    required this.cidade,
    this.pesquisa = '',
    this.favoritos = false,
  });
  final LocalRepository repository;
  final bool admin, favoritos;
  final String cidade, pesquisa;
  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  late String city;
  String category = 'Todas';
  late bool favorites;
  late TextEditingController search;
  late Stream<List<Local>> stream;
  bool deleting = false;
  @override
  void initState() {
    super.initState();
    city = widget.cidade;
    favorites = widget.favoritos;
    search = TextEditingController(text: widget.pesquisa);
    stream = widget.repository.listarLocais();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> open(Local local) async {
    final target = await Navigator.push<Local>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetalhesScreen(id: local.id, repository: widget.repository),
      ),
    );
    if (target != null && mounted) Navigator.pop(context, target);
  }

  Future<void> edit([Local? local]) async {
    final saved = await showLocalForm(
      context,
      widget.repository,
      local: local,
      cidade: city == 'Todas' ? 'São Paulo' : city,
    );
    if (saved == true && mounted) {
      feedback(
        context,
        local == null
            ? 'Local cadastrado no Firestore.'
            : 'Local atualizado no Firestore.',
      );
    }
  }

  Future<void> remove(Local local) async {
    if (deleting || !await confirmDelete(context, local.nome)) return;
    setState(() => deleting = true);
    try {
      await widget.repository.excluir(local.id);
      if (mounted) feedback(context, 'Local excluído do Firestore.');
    } catch (e) {
      if (mounted) feedback(context, mensagemErro(e));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Resultados'),
      actions: [
        IconButton(
          key: const Key('filter-favorite'),
          tooltip: favorites ? 'Mostrar todos' : 'Somente favoritos',
          onPressed: () => setState(() => favorites = !favorites),
          icon: Icon(favorites ? Icons.favorite : Icons.favorite_border),
        ),
      ],
    ),
    floatingActionButton: widget.admin
        ? FloatingActionButton.extended(
            key: const Key('create-local'),
            onPressed: edit,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar'),
          )
        : null,
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              TextField(
                key: const Key('results-search'),
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Pesquisar nome ou categoria',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('results-city'),
                      initialValue: city,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      items: ['Todas', ...cidades]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => city = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('results-category'),
                      initialValue: category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: ['Todas', ...categorias]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                texto: search.text,
                cidade: city,
                categoria: category,
                favoritos: favorites,
              );
              if (list.isEmpty) return const LoadState(empty: true);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${list.length} locais${favorites ? ' favoritos' : ''}',
                      key: const Key('result-count'),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  ...list.map(
                    (l) => LocalCard(
                      key: Key('card-${l.id}'),
                      local: l,
                      open: () => open(l),
                      edit: widget.admin ? () => edit(l) : null,
                      delete: widget.admin && !deleting
                          ? () => remove(l)
                          : null,
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
