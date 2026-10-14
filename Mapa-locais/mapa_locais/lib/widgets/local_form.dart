import 'package:flutter/material.dart';

import '../models/local.dart';
import '../models/catalogo.dart';
import '../services/local_service.dart';

Future<bool?> showLocalForm(
  BuildContext context,
  LocalRepository repository, {
  Local? local,
  String cidade = 'São Paulo',
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      LocalForm(repository: repository, local: local, cidade: cidade),
);

class LocalForm extends StatefulWidget {
  const LocalForm({
    super.key,
    required this.repository,
    this.local,
    required this.cidade,
  });
  final LocalRepository repository;
  final Local? local;
  final String cidade;
  @override
  State<LocalForm> createState() => _LocalFormState();
}

class _LocalFormState extends State<LocalForm> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> fields;
  late String city, category;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final l = widget.local;
    city = l?.cidade ?? widget.cidade;
    category = l?.categoria ?? 'Academia';
    final center = centros[city]!;
    fields = {
      'nome': TextEditingController(text: l?.nome),
      'endereco': TextEditingController(text: l?.endereco),
      'horario': TextEditingController(text: l?.horario),
      'descricao': TextEditingController(text: l?.descricao),
      'avaliacao': TextEditingController(text: (l?.avaliacao ?? 0).toString()),
      'distancia': TextEditingController(text: (l?.distancia ?? 0).toString()),
      'latitude': TextEditingController(
        text: (l?.latitude ?? center.latitude).toString(),
      ),
      'longitude': TextEditingController(
        text: (l?.longitude ?? center.longitude).toString(),
      ),
    };
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  double number(String key) =>
      double.parse(fields[key]!.text.trim().replaceAll(',', '.'));
  Widget field(
    String key,
    String label, {
    int max = 160,
    int lines = 1,
    double? min,
    double? upper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: Key('field-$key'),
      controller: fields[key],
      enabled: !busy,
      maxLength: max,
      maxLines: lines,
      keyboardType: min != null
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return 'Preencha este campo.';
        if (min != null) {
          final n = double.tryParse(text.replaceAll(',', '.'));
          if (n == null || !n.isFinite || n < min || n > upper!) {
            return 'Informe um número entre $min e $upper.';
          }
        }
        return null;
      },
    ),
  );
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final local = Local(
        id: widget.local?.id ?? '',
        nome: fields['nome']!.text.trim(),
        categoria: category,
        cidade: city,
        avaliacao: number('avaliacao'),
        distancia: number('distancia'),
        horario: fields['horario']!.text.trim(),
        descricao: fields['descricao']!.text.trim(),
        favorito: widget.local?.favorito ?? false,
        latitude: number('latitude'),
        longitude: number('longitude'),
        endereco: fields['endereco']!.text.trim(),
      );
      if (widget.local == null) {
        await widget.repository.adicionar(local);
      } else {
        await widget.repository.atualizar(local);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = mensagemErro(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(widget.local == null ? 'Cadastrar local' : 'Editar local'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field('nome', 'Nome', max: 100),
                DropdownButtonFormField<String>(
                  key: const Key('form-city'),
                  initialValue: city,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                  items: cidades
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          city = v!;
                          if (widget.local == null) {
                            fields['latitude']!.text = centros[city]!.latitude
                                .toString();
                            fields['longitude']!.text = centros[city]!.longitude
                                .toString();
                          }
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('form-category'),
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 12),
                field('endereco', 'Endereço'),
                field('horario', 'Horário', max: 80),
                field(
                  'avaliacao',
                  'Avaliação (0 a 5)',
                  min: 0,
                  upper: 5,
                  max: 8,
                ),
                field(
                  'distancia',
                  'Distância de referência (km)',
                  min: 0,
                  upper: 1000,
                  max: 10,
                ),
                field('latitude', 'Latitude', min: -90, upper: 90, max: 16),
                field('longitude', 'Longitude', min: -180, upper: 180, max: 16),
                field('descricao', 'Descrição', max: 2000, lines: 3),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('save-local'),
          onPressed: busy ? null : save,
          child: Text(busy ? 'Salvando…' : 'Salvar'),
        ),
      ],
    ),
  );
}
