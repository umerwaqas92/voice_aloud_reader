import 'package:hive/hive.dart';

import '../models/document.dart';
import 'document_repository.dart';

class HiveDocumentRepository implements DocumentRepository {
  HiveDocumentRepository({this.boxName = 'documents'});

  final String boxName;

  Box<Map<dynamic, dynamic>> _box() => Hive.box<Map<dynamic, dynamic>>(boxName);

  @override
  Future<void> delete(String id) async {
    await _box().delete(id);
  }

  @override
  Future<Document?> getById(String id) async {
    final raw = _box().get(id);
    if (raw == null) return null;
    return Document.fromJson(raw);
  }

  @override
  Future<List<Document>> listDocuments() async {
    final docs =
        _box()
            .values
            .map(Document.fromJson)
            .where((d) => d.id.isNotEmpty)
            .toList()
          ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return docs;
  }

  @override
  Future<void> upsert(Document document) async {
    await _box().put(document.id, document.toJson());
  }
}

