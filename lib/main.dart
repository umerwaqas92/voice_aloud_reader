import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_aloud/voice_aloud_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoxlyApp());
}

class VoxlyApp extends StatelessWidget {
  const VoxlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Voice Aloud Reader',
        theme: ThemeData(
          useMaterial3: false,
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        home: const VoiceAloudRoot(),
      ),
    );
  }
}
