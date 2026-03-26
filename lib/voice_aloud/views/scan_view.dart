import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/document.dart';
import '../runtime_flags.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../widgets/blur_panel.dart';
import '../widgets/lucide_svg_icon.dart';

class ScanView extends ConsumerStatefulWidget {
  const ScanView({super.key});

  @override
  ConsumerState<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends ConsumerState<ScanView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  CameraController? _camera;
  bool _permissionDenied = false;
  bool _isBusy = false;
  bool _autoScan = false;
  Timer? _autoScanTimer;
  double _zoom = 1.0;
  double _maxZoom = 1.0;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (isInTest) {
      _pulseController.value = 1;
    } else {
      _pulseController.repeat(reverse: true);
      unawaited(_initCamera());
    }
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _camera?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.isNotEmpty ? cameras.first : throw StateError('No cameras found'),
    );

    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    _maxZoom = await controller.getMaxZoomLevel();
    await controller.setZoomLevel(_zoom);
    await controller.setFlashMode(FlashMode.off);

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _permissionDenied = false;
      _camera = controller;
    });
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;

    try {
      if (_torchOn) {
        await camera.setFlashMode(FlashMode.off);
      } else {
        await camera.setFlashMode(FlashMode.torch);
      }
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
    }
  }

  Future<void> _toggleZoom() async {
    final camera = _camera;
    if (camera == null) return;

    final next = _zoom < 1.5 ? mathMin(2.0, _maxZoom) : 1.0;
    try {
      await camera.setZoomLevel(next);
      if (mounted) setState(() => _zoom = next);
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    if (_isBusy) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _recognizeAndReview(picked.path, source: DocumentSource.scan);
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _isBusy) return;

    setState(() => _isBusy = true);
    try {
      final file = await camera.takePicture();
      await _recognizeAndReview(file.path, source: DocumentSource.scan);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _setAutoScan(bool enabled) {
    if (_autoScan == enabled) return;
    setState(() => _autoScan = enabled);
    _autoScanTimer?.cancel();
    if (!enabled) return;

    _autoScanTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || !_autoScan) return;
      if (_isBusy) return;

      final camera = _camera;
      if (camera == null) return;

      setState(() => _isBusy = true);
      try {
        final file = await camera.takePicture();
        final text = await ref
            .read(ocrServiceProvider)
            .recognizeTextFromFilePath(file.path);
        if (text.trim().length >= 80) {
          _setAutoScan(false);
          await _showReviewSheet(text, source: DocumentSource.scan);
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    });
  }

  Future<void> _recognizeAndReview(String filePath, {required DocumentSource source}) async {
    setState(() => _isBusy = true);
    try {
      final text =
          await ref.read(ocrServiceProvider).recognizeTextFromFilePath(filePath);
      await _showReviewSheet(text, source: source);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showReviewSheet(String text, {required DocumentSource source}) async {
    final content = text.trim();
    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found. Try again.')),
        );
      }
      return;
    }

    final titleController = TextEditingController(text: _titleFrom(content));
    final textController = TextEditingController(text: content);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Review scan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    minLines: 6,
                    maxLines: 12,
                    decoration: const InputDecoration(labelText: 'Text'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Save to Library'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (saved != true) return;

    final doc =
        await ref.read(documentsControllerProvider.notifier).addFromText(
              title: titleController.text,
              content: textController.text.trim(),
              source: source,
            );
    ref.read(appControllerProvider.notifier).openDocument(doc.id);
  }

  @override
  Widget build(BuildContext context) {
    if (isInTest) {
      return _MockScanUi(pulse: _pulseController);
    }

    if (_permissionDenied) {
      return _PermissionDeniedView(onRetry: _initCamera);
    }

    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        final hole = Rect.fromCenter(
                          center: Offset(size.width / 2, size.height / 2),
                          width: 280,
                          height: 400,
                        );

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: _camera == null
                                  ? const ColoredBox(color: Colors.black)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _camera!.value.previewSize?.height ?? size.width,
                                          height: _camera!.value.previewSize?.width ?? size.height,
                                          child: CameraPreview(_camera!),
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned.fill(
                              child: ColoredBox(
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ViewfinderDimPainter(
                                  holeRect: hole,
                                  holeRadius: 12,
                                  overlayColor: Colors.black.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 280,
                                height: 400,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      top: -4,
                                      left: -4,
                                      child: _CornerAccent(
                                        top: true,
                                        left: true,
                                      ),
                                    ),
                                    const Positioned(
                                      top: -4,
                                      right: -4,
                                      child: _CornerAccent(
                                        top: true,
                                        left: false,
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: -4,
                                      left: -4,
                                      child: _CornerAccent(
                                        top: false,
                                        left: true,
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: -4,
                                      right: -4,
                                      child: _CornerAccent(
                                        top: false,
                                        left: false,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Center(
                                        child: AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, _) {
                                            final opacity =
                                                0.5 +
                                                (_pulseController.value * 0.5);
                                            return Opacity(
                                              opacity: opacity,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(
                                                    alpha: 0.35,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Position text in frame',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                BlurPanel(
                  borderRadius: BorderRadius.zero,
                  sigma: 18,
                  color: Colors.black.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GrayCircleButton(
                          child: const LucideSvgIcon(
                            'image',
                            size: 20,
                            color: Colors.white,
                          ),
                          onTap: _pickFromGallery,
                        ),
                        GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 80,
                            height: 80,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 5),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        _GrayCircleButton(
                          child: const LucideSvgIcon(
                            'settings',
                            size: 20,
                            color: Colors.white,
                          ),
                          onTap: () async {
                            final next = await showModalBottomSheet<bool>(
                              context: context,
                              showDragHandle: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) {
                                return SafeArea(
                                  top: false,
                                  child: SwitchListTile(
                                    title: const Text('Auto Scan'),
                                    value: _autoScan,
                                    onChanged: (v) => Navigator.of(context).pop(v),
                                  ),
                                );
                              },
                            );
                            if (next != null) _setAutoScan(next);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BlackCircleButton(
                      child: LucideSvgIcon(
                        'zap',
                        size: 20,
                        color: _torchOn ? VAColors.yellow400 : Colors.white,
                      ),
                      onTap: _toggleTorch,
                    ),
                    GestureDetector(
                      onTap: () => _setAutoScan(!_autoScan),
                      child: BlurPanel(
                        borderRadius: BorderRadius.circular(999),
                        sigma: 12,
                        color: Colors.black.withValues(alpha: 0.6),
                        border: Border.all(
                          color: VAColors.yellow400.withValues(
                            alpha: _autoScan ? 0.9 : 0.3,
                          ),
                          width: 1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Text(
                            _autoScan ? 'Auto Scan On' : 'Auto Scan',
                            style: const TextStyle(
                              color: VAColors.yellow400,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _BlackCircleButton(
                      child: const LucideSvgIcon(
                        'maximize',
                        size: 20,
                        color: Colors.white,
                      ),
                      onTap: _toggleZoom,
                    ),
                  ],
                ),
              ),
            ),
            if (_isBusy)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MockScanUi extends StatelessWidget {
  const _MockScanUi({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        final hole = Rect.fromCenter(
                          center: Offset(size.width / 2, size.height / 2),
                          width: 280,
                          height: 400,
                        );

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.5,
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.matrix(
                                      _desaturate50,
                                    ),
                                    child: Image.asset(
                                      'assets/images/scan_bg.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: ColoredBox(
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ViewfinderDimPainter(
                                  holeRect: hole,
                                  holeRadius: 12,
                                  overlayColor: Colors.black.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 280,
                                height: 400,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      top: -4,
                                      left: -4,
                                      child: _CornerAccent(
                                        top: true,
                                        left: true,
                                      ),
                                    ),
                                    const Positioned(
                                      top: -4,
                                      right: -4,
                                      child: _CornerAccent(
                                        top: true,
                                        left: false,
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: -4,
                                      left: -4,
                                      child: _CornerAccent(
                                        top: false,
                                        left: true,
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: -4,
                                      right: -4,
                                      child: _CornerAccent(
                                        top: false,
                                        left: false,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Center(
                                        child: AnimatedBuilder(
                                          animation: pulse,
                                          builder: (context, _) {
                                            final opacity = 0.5 + (pulse.value * 0.5);
                                            return Opacity(
                                              opacity: opacity,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(
                                                    alpha: 0.35,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Position text in frame',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                BlurPanel(
                  borderRadius: BorderRadius.zero,
                  sigma: 18,
                  color: Colors.black.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GrayCircleButton(
                          child: const LucideSvgIcon(
                            'image',
                            size: 20,
                            color: Colors.white,
                          ),
                          onTap: () {},
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        _GrayCircleButton(
                          child: const LucideSvgIcon(
                            'settings',
                            size: 20,
                            color: Colors.white,
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BlackCircleButton(
                      child: const LucideSvgIcon(
                        'zap',
                        size: 20,
                        color: Colors.white,
                      ),
                      onTap: () {},
                    ),
                    BlurPanel(
                      borderRadius: BorderRadius.circular(999),
                      sigma: 12,
                      color: Colors.black.withValues(alpha: 0.6),
                      border: Border.all(
                        color: VAColors.yellow400.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Text(
                          'Auto Scan',
                          style: TextStyle(
                            color: VAColors.yellow400,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    _BlackCircleButton(
                      child: const LucideSvgIcon(
                        'maximize',
                        size: 20,
                        color: Colors.white,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Camera permission required',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enable camera permission to scan documents.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async => onRetry(),
                child: const Text('Try again'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  const _CornerAccent({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top:
                top
                    ? const BorderSide(color: VAColors.yellow400, width: 4)
                    : BorderSide.none,
            bottom:
                !top
                    ? const BorderSide(color: VAColors.yellow400, width: 4)
                    : BorderSide.none,
            left:
                left
                    ? const BorderSide(color: VAColors.yellow400, width: 4)
                    : BorderSide.none,
            right:
                !left
                    ? const BorderSide(color: VAColors.yellow400, width: 4)
                    : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(12) : Radius.zero,
            topRight: top && !left ? const Radius.circular(12) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                !top && !left ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _BlackCircleButton extends StatelessWidget {
  const _BlackCircleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BlurPanel(
        borderRadius: BorderRadius.circular(999),
        sigma: 12,
        color: Colors.black.withValues(alpha: 0.4),
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    );
  }
}

class _GrayCircleButton extends StatelessWidget {
  const _GrayCircleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: VAColors.gray800,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ViewfinderDimPainter extends CustomPainter {
  _ViewfinderDimPainter({
    required this.holeRect,
    required this.holeRadius,
    required this.overlayColor,
  });

  final Rect holeRect;
  final double holeRadius;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    canvas.drawRect(rect, Paint()..color = overlayColor);

    final holeRRect = RRect.fromRectAndRadius(
      holeRect,
      Radius.circular(holeRadius),
    );
    canvas.drawRRect(holeRRect, Paint()..blendMode = BlendMode.clear);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ViewfinderDimPainter oldDelegate) {
    return holeRect != oldDelegate.holeRect ||
        holeRadius != oldDelegate.holeRadius ||
        overlayColor != oldDelegate.overlayColor;
  }
}

double mathMin(double a, double b) => a < b ? a : b;

String _titleFrom(String content) {
  final firstLine = content.split('\n').first.trim();
  if (firstLine.isEmpty) return 'Scan';
  return firstLine.length > 32 ? '${firstLine.substring(0, 32)}…' : firstLine;
}

const List<double> _desaturate50 = <double>[
  0.6063,
  0.3576,
  0.0361,
  0,
  0,
  0.1063,
  0.8576,
  0.0361,
  0,
  0,
  0.1063,
  0.3576,
  0.5361,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];
