import '../voice_aloud_tab.dart';

class AppState {
  const AppState({required this.activeTab, required this.activeDocumentId});

  final VoiceAloudTab activeTab;
  final String? activeDocumentId;

  AppState copyWith({VoiceAloudTab? activeTab, String? activeDocumentId}) {
    return AppState(
      activeTab: activeTab ?? this.activeTab,
      activeDocumentId: activeDocumentId ?? this.activeDocumentId,
    );
  }

  static const defaults = AppState(
    activeTab: VoiceAloudTab.library,
    activeDocumentId: null,
  );
}

