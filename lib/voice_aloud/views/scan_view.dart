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
import '../widgets/lucide_svg_icon.dart';
import '../voice_aloud_tab.dart';

class ScanView extends ConsumerStatefulWidget {
  const ScanView({super.key});

  @override
  ConsumerState<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends ConsumerState<ScanView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;

  CameraController? _camera;
  bool _isInitializing = false;
  bool _permissionDenied = false;
  String? _cameraInitError;
  bool _isBusy = false;
  bool _autoScan = false;
  Timer? _autoScanTimer;
  double _zoom = 1.0;
  double _maxZoom = 1.0;
  bool _torchOn = false;
  double _scaleBaseZoom = 1.0;
  ProviderSubscription<VoiceAloudTab>? _tabSubscription;

  Future<void> _disposeCamera({required bool updateState}) async {
    final camera = _camera;
    if (camera == null) return;

    if (updateState && mounted) {
      setState(() {
        _camera = null;
        _torchOn = false;
        _zoom = 1.0;
        _maxZoom = 1.0;
      });
    } else {
      _camera = null;
      _torchOn = false;
      _zoom = 1.0;
      _maxZoom = 1.0;
    }

    try {
      await camera.setFlashMode(FlashMode.off);
    } catch (_) {}
    try {
      await camera.dispose();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabSubscription = ref.listenManual<VoiceAloudTab>(
      appControllerProvider.select((s) => s.activeTab),
      (previous, next) {
        if (next == VoiceAloudTab.scan) {
          if (_camera != null || _permissionDenied || _isInitializing) return;
          if (_cameraInitError != null) return;
          unawaited(_initCamera());
          return;
        }

        if (previous == VoiceAloudTab.scan) {
          _setAutoScan(false);
          unawaited(_disposeCamera(updateState: true));
        }
      },
    );

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
    unawaited(_disposeCamera(updateState: false));
    _pulseController.dispose();
    _tabSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (isInTest) return;
    if (!mounted) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_disposeCamera(updateState: true));
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_camera != null || _isInitializing) return;
      if (_permissionDenied) {
        final status = await Permission.camera.status;
        if (status.isGranted) {
          if (mounted) {
            setState(() => _permissionDenied = false);
          }
        } else {
          return;
        }
      }
      unawaited(_initCamera());
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;

    final old = _camera;
    if (old != null) {
      setState(() => _camera = null);
      try {
        await old.dispose();
      } catch (_) {}
    }

    setState(() {
      _isInitializing = true;
      _cameraInitError = null;
      _permissionDenied = false;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isInitializing = false;
        });
      }
      return;
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 6),
      );
      if (cameras.isEmpty) {
        throw StateError('No cameras found');
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize().timeout(const Duration(seconds: 10));
      _maxZoom = await controller.getMaxZoomLevel();
      await controller.setZoomLevel(_zoom.clamp(1.0, _maxZoom));
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _camera = controller;
        _isInitializing = false;
        _cameraInitError = null;
        _permissionDenied = false;
        _torchOn = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _camera = null;
        _isInitializing = false;
        _cameraInitError = e.toString();
      });
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash not available on this device.')),
        );
      }
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

  Future<void> _recognizeAndReview(
    String filePath, {
    required DocumentSource source,
  }) async {
    setState(() => _isBusy = true);
    try {
      final text = await ref
          .read(ocrServiceProvider)
          .recognizeTextFromFilePath(filePath);
      await _showReviewSheet(text, source: source);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showReviewSheet(
    String text, {
    required DocumentSource source,
  }) async {
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

    final doc = await ref
        .read(documentsControllerProvider.notifier)
        .addFromText(
          title: titleController.text,
          content: textController.text.trim(),
          source: source,
        );
    ref.read(appControllerProvider.notifier).openDocument(doc.id);
  }

  Widget _buildLivePreview() {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final screenAspectRatio = size.width / size.height;
    var scale = camera.value.aspectRatio / screenAspectRatio;
    if (scale < 1) scale = 1 / scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (_) => _scaleBaseZoom = _zoom,
      onScaleUpdate: (details) async {
        if (_isBusy) return;
        final next = (_scaleBaseZoom * details.scale).clamp(1.0, _maxZoom);
        if ((next - _zoom).abs() < 0.02) return;
        try {
          await camera.setZoomLevel(next);
          if (mounted) setState(() => _zoom = next);
        } catch (_) {}
      },
      child: Transform.scale(
        scale: scale,
        child: Center(
          child: AspectRatio(
            aspectRatio: camera.value.aspectRatio,
            child: CameraPreview(camera),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinderOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final holeWidth = mathMin(size.width * 0.84, 360);
        final holeHeight = (holeWidth * 1.25).clamp(260.0, size.height * 0.62);
        final hole = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: holeWidth,
          height: holeHeight,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ViewfinderDimPainter(
                  holeRect: hole,
                  holeRadius: 16,
                  overlayColor: Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: holeWidth,
                height: holeHeight,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: -4,
                      left: -4,
                      child: _CornerAccent(top: true, left: true),
                    ),
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: _CornerAccent(top: true, left: false),
                    ),
                    const Positioned(
                      bottom: -4,
                      left: -4,
                      child: _CornerAccent(top: false, left: true),
                    ),
                    const Positioned(
                      bottom: -4,
                      right: -4,
                      child: _CornerAccent(top: false, left: false),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final opacity =
                                0.45 + (_pulseController.value * 0.55);
                            return Opacity(
                              opacity: opacity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: const Text(
                                  'Keep text inside frame',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
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
    );
  }

  Widget _buildZoomPill() {
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        '${_zoom.toStringAsFixed(_zoom < 2 ? 1 : 0)}×',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Future<void> _openAutoScanSheet() async {
    final next = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  }

  @override
  Widget build(BuildContext context) {
    if (isInTest) {
      return _MockScanUi(pulse: _pulseController);
    }

    if (_permissionDenied) {
      return _PermissionDeniedView(
        onRetry: _initCamera,
        onBack:
            () => ref
                .read(appControllerProvider.notifier)
                .setTab(VoiceAloudTab.library),
      );
    }

    final error = _cameraInitError;
    if (error != null) {
      return _CameraInitErrorView(
        message: error,
        onRetry: _initCamera,
        onBack:
            () => ref
                .read(appControllerProvider.notifier)
                .setTab(VoiceAloudTab.library),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(child: _buildLivePreview()),
          Positioned.fill(child: _buildViewfinderOverlay()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _BlackCircleButton(
                          onTap: () {
                            ref
                                .read(appControllerProvider.notifier)
                                .setTab(VoiceAloudTab.library);
                          },
                          child: const LucideSvgIcon(
                            'chevron-left',
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _BlackCircleButton(
                          onTap: _toggleTorch,
                          child: LucideSvgIcon(
                            'zap',
                            size: 20,
                            color: _torchOn ? VAColors.yellow400 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _setAutoScan(!_autoScan),
                      child: _GlassPill(
                        borderColor: VAColors.yellow400.withValues(
                          alpha: _autoScan ? 0.9 : 0.25,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Text(
                          _autoScan ? 'AUTO SCAN ON' : 'AUTO SCAN',
                          style: const TextStyle(
                            color: VAColors.yellow400,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleZoom,
                      child: _buildZoomPill(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _GlassPanel(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GrayCircleButton(
                          onTap: _pickFromGallery,
                          child: const LucideSvgIcon(
                            'image',
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 84,
                            height: 84,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.95),
                                width: 5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
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
                          onTap: _openAutoScanSheet,
                          child: const LucideSvgIcon(
                            'settings',
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isBusy || _isInitializing)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_desaturate50),
                  child: Image.asset(
                    'assets/images/scan_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final holeWidth = mathMin(size.width * 0.84, 360);
                final holeHeight = (holeWidth * 1.25).clamp(
                  260.0,
                  size.height * 0.62,
                );
                final hole = Rect.fromCenter(
                  center: Offset(size.width / 2, size.height / 2),
                  width: holeWidth,
                  height: holeHeight,
                );

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ViewfinderDimPainter(
                          holeRect: hole,
                          holeRadius: 16,
                          overlayColor: Colors.black.withValues(alpha: 0.42),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: holeWidth,
                        height: holeHeight,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 1,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: -4,
                              left: -4,
                              child: _CornerAccent(top: true, left: true),
                            ),
                            const Positioned(
                              top: -4,
                              right: -4,
                              child: _CornerAccent(top: true, left: false),
                            ),
                            const Positioned(
                              bottom: -4,
                              left: -4,
                              child: _CornerAccent(top: false, left: true),
                            ),
                            const Positioned(
                              bottom: -4,
                              right: -4,
                              child: _CornerAccent(top: false, left: false),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: pulse,
                                  builder: (context, _) {
                                    final opacity = 0.45 + (pulse.value * 0.55);
                                    return Opacity(
                                      opacity: opacity,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.35,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Keep text inside frame',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BlackCircleButton(
                      onTap: () {},
                      child: const LucideSvgIcon(
                        'zap',
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    _GlassPill(
                      borderColor: VAColors.yellow400.withValues(alpha: 0.25),
                      child: const Text(
                        'AUTO SCAN',
                        style: TextStyle(
                          color: VAColors.yellow400,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const _GlassPill(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '1.0×',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _GlassPanel(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GrayCircleButton(
                          onTap: () {},
                          child: const LucideSvgIcon(
                            'image',
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 84,
                            height: 84,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.95),
                                width: 5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        _GrayCircleButton(
                          onTap: () {},
                          child: const LucideSvgIcon(
                            'settings',
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onRetry, required this.onBack});

  final Future<void> Function() onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _BlackCircleButton(
                  onTap: onBack,
                  child: const LucideSvgIcon(
                    'chevron-left',
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Camera permission required',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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
        ],
      ),
    );
  }
}

class _CameraInitErrorView extends StatelessWidget {
  const _CameraInitErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _BlackCircleButton(
                  onTap: onBack,
                  child: const LucideSvgIcon(
                    'chevron-left',
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Camera failed to start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async => onRetry(),
                    child: const Text('Retry'),
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
        ],
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

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
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
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Center(child: child),
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
