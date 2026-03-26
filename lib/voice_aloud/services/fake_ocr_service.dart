import 'ocr_service.dart';

class FakeOcrService implements OcrService {
  @override
  Future<String> recognizeTextFromFilePath(String path) async => '';
}

