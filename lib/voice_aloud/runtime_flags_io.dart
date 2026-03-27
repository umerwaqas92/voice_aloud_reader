import 'dart:io';

bool get isInTestImpl => Platform.environment.containsKey('FLUTTER_TEST');
