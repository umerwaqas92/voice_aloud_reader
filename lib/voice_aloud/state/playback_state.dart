class PlaybackState {
  const PlaybackState({
    required this.isPlaying,
    required this.documentId,
    required this.baseOffset,
    required this.currentOffset,
    required this.highlightStart,
    required this.highlightEnd,
    required this.lastError,
  });

  final bool isPlaying;
  final String? documentId;
  final int baseOffset;
  final int currentOffset;
  final int? highlightStart;
  final int? highlightEnd;

  final String? lastError;

  static const stopped = PlaybackState(
    isPlaying: false,
    documentId: null,
    baseOffset: 0,
    currentOffset: 0,
    highlightStart: null,
    highlightEnd: null,
    lastError: null,
  );

  PlaybackState copyWith({
    bool? isPlaying,
    String? documentId,
    int? baseOffset,
    int? currentOffset,
    int? highlightStart,
    int? highlightEnd,
    String? lastError,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      documentId: documentId ?? this.documentId,
      baseOffset: baseOffset ?? this.baseOffset,
      currentOffset: currentOffset ?? this.currentOffset,
      highlightStart: highlightStart ?? this.highlightStart,
      highlightEnd: highlightEnd ?? this.highlightEnd,
      lastError: lastError,
    );
  }
}
