import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LucideSvgIcon extends StatelessWidget {
  const LucideSvgIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color = const Color(0xFF111827),
    this.strokeWidth = 2,
  });

  final String name;
  final double size;
  final Color color;
  final double strokeWidth;

  static const Set<String> _stroke15Icons = {'skip-back', 'skip-forward'};
  static const Set<String> _stroke25Icons = {
    'book',
    'camera',
    'file-text',
    'settings',
  };

  String get _assetPath {
    if (strokeWidth == 1.5 && _stroke15Icons.contains(name)) {
      return 'assets/icons/lucide/${name}_sw1_5.svg';
    }
    if (strokeWidth == 2.5 && _stroke25Icons.contains(name)) {
      return 'assets/icons/lucide/${name}_sw2_5.svg';
    }
    return 'assets/icons/lucide/$name.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
