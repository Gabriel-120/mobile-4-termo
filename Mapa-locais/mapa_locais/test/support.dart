import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mapa_locais/models/local.dart';
import 'package:mapa_locais/services/local_service.dart';

List<Local> fixture() =>
    (jsonDecode(File('tool/seed.json').readAsStringSync()) as List)
        .map(
          (row) => Local.fromMap(
            row['id'] as String,
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();

// Apenas teste de interface. Não é usado como backend ou fallback na aplicação.
class TestRepository implements LocalRepository {
  TestRepository([List<Local>? initial]) : data = initial ?? fixture();
  final List<Local> data;
  final changes = StreamController<void>.broadcast();
  Object? error;
  int next = 0;
  void close() {
    changes.close();
  }

  @override
  Stream<List<Local>> listarLocais() async* {
    if (error != null) throw error!;
    yield List.of(data);
    await for (final _ in changes.stream) {
      yield List.of(data);
    }
  }

  @override
  Stream<Local?> observar(String id) async* {
    yield data.where((l) => l.id == id).firstOrNull;
    await for (final _ in changes.stream) {
      yield data.where((l) => l.id == id).firstOrNull;
    }
  }

  @override
  Future<String> adicionar(Local local) async {
    final id = 'test-${next++}';
    data.add(Local.fromMap(id, local.toMap()));
    changes.add(null);
    return id;
  }

  @override
  Future<void> atualizar(Local local) async {
    data[data.indexWhere((l) => l.id == local.id)] = local;
    changes.add(null);
  }

  @override
  Future<void> excluir(String id) async {
    data.removeWhere((l) => l.id == id);
    changes.add(null);
  }

  @override
  Future<void> alterarFavorito(String id, bool value) async {
    final l = data.firstWhere((l) => l.id == id);
    await atualizar(Local.fromMap(id, {...l.toMap(), 'favorito': value}));
  }
}
