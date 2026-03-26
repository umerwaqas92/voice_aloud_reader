import '../models/document.dart';

abstract class DocumentRepository {
  Future<List<Document>> listDocuments();
  Future<Document?> getById(String id);
  Future<void> upsert(Document document);
  Future<void> delete(String id);
}

class MemoryDocumentRepository implements DocumentRepository {
  MemoryDocumentRepository({Map<String, Document>? seed})
      : _documents = {...?seed};

  final Map<String, Document> _documents;

  @override
  Future<void> delete(String id) async {
    _documents.remove(id);
  }

  @override
  Future<Document?> getById(String id) async => _documents[id];

  @override
  Future<List<Document>> listDocuments() async {
    final list = _documents.values.toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return list;
  }

  @override
  Future<void> upsert(Document document) async {
    _documents[document.id] = document;
  }
}

