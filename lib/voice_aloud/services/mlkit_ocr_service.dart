import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

class MlkitOcrService implements OcrService {
  MlkitOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer();

  final TextRecognizer _recognizer;

  @override
  Future<String> recognizeTextFromFilePath(String path) async {
    final input = InputImage.fromFilePath(path);
    final text = await _recognizer.processImage(input);
    return text.text;
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

