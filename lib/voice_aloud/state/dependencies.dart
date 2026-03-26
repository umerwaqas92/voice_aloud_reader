import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../runtime_flags.dart';
import '../repositories/document_repository.dart';
import '../repositories/hive_document_repository.dart';
import '../repositories/hive_settings_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/fake_ocr_service.dart';
import '../services/fake_tts_service.dart';
import '../services/flutter_tts_service.dart';
import '../services/mlkit_ocr_service.dart';
import '../services/ocr_service.dart';
import '../services/tts_service.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  if (isInTest) return;
  await Hive.initFlutter();
  await Hive.openBox<Map<dynamic, dynamic>>('documents');
  await Hive.openBox<Map<dynamic, dynamic>>('prefs');
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  if (isInTest) return MemoryDocumentRepository();
  return HiveDocumentRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (isInTest) return MemorySettingsRepository();
  return HiveSettingsRepository();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  if (isInTest) return FakeTtsService();
  return FlutterTtsService();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  if (isInTest) return FakeOcrService();
  final service = MlkitOcrService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
