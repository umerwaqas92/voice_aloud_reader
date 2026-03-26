import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/document.dart';
import '../runtime_flags.dart';
import 'dependencies.dart';

final documentsControllerProvider =
    AsyncNotifierProvider<DocumentsController, List<Document>>(
      DocumentsController.new,
    );

class DocumentsController extends AsyncNotifier<List<Document>> {
  final _uuid = const Uuid();

  @override
  Future<List<Document>> build() async {
    await ref.watch(appInitProvider.future);
    final repo = ref.watch(documentRepositoryProvider);
    final docs = await repo.listDocuments();

    if (isInTest) {
      return docs.isNotEmpty ? docs : _seedDemoDocuments();
    }
    return docs;
  }

  Future<Document> addFromText({
    required String title,
    required String content,
    String author = '',
    required DocumentSource source,
  }) async {
    final now = DateTime.now();
    final document = Document(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      author: author.trim(),
      content: content,
      createdAt: now,
      updatedAt: now,
      lastOpenedAt: now,
      lastReadOffset: 0,
      source: source,
    );

    final repo = ref.read(documentRepositoryProvider);
    await repo.upsert(document);

    final current = state.valueOrNull ?? const <Document>[];
    state = AsyncData([document, ...current]);
    return document;
  }

  Future<void> delete(String id) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.delete(id);
    final current = state.valueOrNull ?? const <Document>[];
    state = AsyncData(current.where((d) => d.id != id).toList());
  }

  Future<void> markOpened(String id) async {
    final current = state.valueOrNull ?? const <Document>[];
    final idx = current.indexWhere((d) => d.id == id);
    if (idx < 0) return;

    final now = DateTime.now();
    final updated = current[idx].copyWith(lastOpenedAt: now, updatedAt: now);
    final repo = ref.read(documentRepositoryProvider);
    await repo.upsert(updated);

    final next = [...current]..removeAt(idx);
    next.insert(0, updated);
    state = AsyncData(next);
  }

  Future<void> updateReadOffset(String id, int offset) async {
    final current = state.valueOrNull ?? const <Document>[];
    final idx = current.indexWhere((d) => d.id == id);
    if (idx < 0) return;

    final doc = current[idx];
    final bounded = offset.clamp(0, doc.content.length);
    if (bounded == doc.lastReadOffset) return;

    final now = DateTime.now();
    final updated = doc.copyWith(
      lastReadOffset: bounded,
      updatedAt: now,
    );
    final repo = ref.read(documentRepositoryProvider);
    await repo.upsert(updated);

    final next = [...current];
    next[idx] = updated;
    state = AsyncData(next);
  }

  Document? getById(String id) {
    final current = state.valueOrNull;
    if (current == null) return null;
    return current.cast<Document?>().firstWhere(
          (d) => d?.id == id,
          orElse: () => null,
        );
  }

  List<Document> _seedDemoDocuments() {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    final content =
        "To Sherlock Holmes she is always the woman. I have seldom heard him mention her under any other name. In his eyes she eclipses and predominates the whole of her sex.\n\n"
        "He was, I take it, the most perfect reasoning and observing machine that the world has seen, but as a lover he would have placed himself in a false position.\n\n"
        "But for the trained reasoner to admit such intrusions into his own delicate and finely adjusted temperament was to introduce a distracting factor which might throw a doubt upon all his mental results.";

    Document makeDoc({
      required String id,
      required String title,
      required String author,
      required int progressPercent,
    }) {
      final offset = ((content.length * progressPercent) / 100).round();
      return Document(
        id: id,
        title: title,
        author: author,
        content: content,
        createdAt: now,
        updatedAt: now,
        lastOpenedAt: now,
        lastReadOffset: offset,
        source: DocumentSource.unknown,
      );
    }

    return [
      makeDoc(
        id: 'demo_1',
        title: 'A Scandal in Bohemia',
        author: 'Arthur Conan Doyle',
        progressPercent: 12,
      ),
      makeDoc(
        id: 'demo_2',
        title: 'The Art of War',
        author: 'Sun Tzu',
        progressPercent: 45,
      ),
      makeDoc(
        id: 'demo_3',
        title: 'Web Article: Future of AI',
        author: 'TechCrunch',
        progressPercent: 0,
      ),
      makeDoc(
        id: 'demo_4',
        title: 'Alice in Wonderland',
        author: 'Lewis Carroll',
        progressPercent: 89,
      ),
    ];
  }
}
