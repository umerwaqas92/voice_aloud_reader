class Document {
  const Document({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.lastOpenedAt,
    required this.lastReadOffset,
    this.author = '',
    this.source = DocumentSource.unknown,
  });

  final String id;
  final String title;
  final String author;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastOpenedAt;
  final int lastReadOffset;
  final DocumentSource source;

  double get progress {
    final len = content.length;
    if (len == 0) return 0;
    return (lastReadOffset.clamp(0, len) / len).clamp(0.0, 1.0);
  }

  Document copyWith({
    String? title,
    String? author,
    String? content,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    int? lastReadOffset,
    DocumentSource? source,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastReadOffset: lastReadOffset ?? this.lastReadOffset,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'content': content,
    'createdAtMs': createdAt.millisecondsSinceEpoch,
    'updatedAtMs': updatedAt.millisecondsSinceEpoch,
    'lastOpenedAtMs': lastOpenedAt.millisecondsSinceEpoch,
    'lastReadOffset': lastReadOffset,
    'source': source.name,
  };

  static Document fromJson(Map<dynamic, dynamic> json) {
    DateTime dt(String key) {
      final v = json[key];
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final sourceName = json['source'];
    final source = DocumentSource.values.firstWhere(
      (e) => e.name == sourceName,
      orElse: () => DocumentSource.unknown,
    );

    return Document(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: dt('createdAtMs'),
      updatedAt: dt('updatedAtMs'),
      lastOpenedAt: dt('lastOpenedAtMs'),
      lastReadOffset: (json['lastReadOffset'] is int)
          ? json['lastReadOffset'] as int
          : int.tryParse((json['lastReadOffset'] ?? '0').toString()) ?? 0,
      source: source,
    );
  }
}

enum DocumentSource { unknown, importTxt, paste, scan }
