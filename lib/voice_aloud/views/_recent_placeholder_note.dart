import 'package:flutter/material.dart';

class RecentPlaceholderNote extends StatelessWidget {
  const RecentPlaceholderNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        'Recents are now in their own screen. Use “Open Recents” above.',
        style: TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    );
  }
}
