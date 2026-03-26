import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../voice_aloud_tab.dart';
import 'app_state.dart';

final appControllerProvider =
    StateNotifierProvider<AppController, AppState>((ref) => AppController());

class AppController extends StateNotifier<AppState> {
  AppController() : super(AppState.defaults);

  void setTab(VoiceAloudTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void openDocument(String documentId) {
    state = state.copyWith(
      activeTab: VoiceAloudTab.read,
      activeDocumentId: documentId,
    );
  }

  void setActiveDocument(String? documentId) {
    state = state.copyWith(activeDocumentId: documentId);
  }
}
