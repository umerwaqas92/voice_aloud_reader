import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tts_service.dart';
import 'dependencies.dart';

/// Caches the available TTS voices for the session so the picker opens instantly
/// after the first load.
final availableVoicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final tts = ref.watch(ttsServiceProvider);
      return tts.getVoices();
    });
