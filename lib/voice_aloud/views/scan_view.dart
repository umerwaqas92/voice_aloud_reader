import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/document.dart';
import '../runtime_flags.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/lucide_svg_icon.dart';
import '../widgets/press_effect.dart';
import '../voice_aloud_tab.dart';

class ScanView extends ConsumerStatefulWidget {
  const ScanView({super.key});

  @override
  ConsumerState<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends ConsumerState<ScanView>
    with WidgetsBindingObserver {
  CameraController? _camera;
  bool _isInitializing = false;
  bool _permissionDenied = false;
  String? _cameraInitError;
  bool _isBusy = false;
  Timer? _backgroundOcrTimer;
  double _zoom = 1.0;
  double _maxZoom = 1.0;
  bool _torchOn = false;
  double _scaleBaseZoom = 1.0;
  ProviderSubscription<VoiceAloudTab>? _tabSubscription;
  bool _allowAutoCapture = false;
  DateTime? _lastFocusAt;
  ResolutionPreset _activeResolutionPreset = ResolutionPreset.veryHigh;

  Future<void> _disposeCamera({required bool updateState}) async {
    final camera = _camera;
    if (camera == null) return;

    _stopBackgroundOcrPolling();

    if (updateState && mounted) {
      setState(() {
        _camera = null;
        _torchOn = false;
        _zoom = 1.0;
        _maxZoom = 1.0;
        _allowAutoCapture = false;
        _lastFocusAt = null;
      });
    } else {
      _camera = null;
      _torchOn = false;
      _zoom = 1.0;
      _maxZoom = 1.0;
      _allowAutoCapture = false;
      _lastFocusAt = null;
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
          unawaited(_disposeCamera(updateState: true));
        }
      },
    );

    if (!isInTest) {
      unawaited(_initCamera());
    }
  }

  @override
  void dispose() {
    _stopBackgroundOcrPolling();
    unawaited(_disposeCamera(updateState: false));
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

    _stopBackgroundOcrPolling();

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
      _allowAutoCapture = false;
      _lastFocusAt = null;
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

      CameraController? controller;
      Object? initError;
      for (final preset in const [
        ResolutionPreset.veryHigh,
        ResolutionPreset.high,
      ]) {
        try {
          controller = await _createInitializedController(back, preset);
          _activeResolutionPreset = preset;
          break;
        } catch (e) {
          initError = e;
        }
      }

      if (controller == null) {
        throw initError ?? StateError('Camera initialization failed');
      }

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
        _allowAutoCapture = false;
        _lastFocusAt = null;
      });
      _startBackgroundOcrPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _camera = null;
        _isInitializing = false;
        _cameraInitError =
            'Camera failed to start at high quality (${_activeResolutionPreset.name}): ${e.toString()}';
      });
    }
  }

  Future<CameraController> _createInitializedController(
    CameraDescription back,
    ResolutionPreset preset,
  ) async {
    final controller = CameraController(
      back,
      preset,
      enableAudio: false,
      imageFormatGroup:
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
              ? ImageFormatGroup.yuv420
              : null,
    );

    try {
      await controller.initialize().timeout(const Duration(seconds: 10));
      return controller;
    } catch (_) {
      try {
        await controller.dispose();
      } catch (_) {}
      rethrow;
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

  void _stopBackgroundOcrPolling() {
    _backgroundOcrTimer?.cancel();
    _backgroundOcrTimer = null;
  }

  void _startBackgroundOcrPolling() {
    if (isInTest) return;
    _stopBackgroundOcrPolling();
    _backgroundOcrTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      if (_isBusy) return;
      if (!_allowAutoCapture) return;

      final lastFocusAt = _lastFocusAt;
      if (lastFocusAt == null) return;
      if (DateTime.now().difference(lastFocusAt) <
          const Duration(milliseconds: 700)) {
        return;
      }

      final camera = _camera;
      if (camera == null) return;

      setState(() => _isBusy = true);
      try {
        final file = await camera.takePicture();
        final text = await ref
            .read(ocrServiceProvider)
            .recognizeTextFromFilePath(file.path);
        if (text.trim().length >= 80) {
          await _showReviewSheet(text, source: DocumentSource.scan);
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    });
  }

  Future<void> _focusOnPoint(Offset localPosition, Size size) async {
    final camera = _camera;
    if (camera == null || _isBusy) return;

    final dx = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final dy = (localPosition.dy / size.height).clamp(0.0, 1.0);
    try {
      await camera.setFocusPoint(Offset(dx, dy));
      await camera.setExposurePoint(Offset(dx, dy));
      await camera.setFocusMode(FocusMode.auto);
      await camera.setExposureMode(ExposureMode.auto);
      _allowAutoCapture = true;
      _lastFocusAt = DateTime.now();
    } catch (_) {}
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

    // [CameraPreview] already applies AspectRatio (and Android rotation). Do not
    // wrap it in another AspectRatio — that distorts the preview (stretched text).
    final size = MediaQuery.sizeOf(context);
    final screenAspectRatio = size.width / size.height;
    var scale = screenAspectRatio * camera.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown:
              (details) => _focusOnPoint(details.localPosition, size),
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
          child: ClipRect(
            child: Transform.scale(
              scale: scale,
              filterQuality: FilterQuality.none,
              alignment: Alignment.center,
              child: Center(
                child: CameraPreview(camera),
              ),
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    if (isInTest) {
      return const _MockScanUi();
    }

    if (_permissionDenied) {
      return AnimatedPageEntrance(
        child: _PermissionDeniedView(
          onRetry: _initCamera,
          onBack:
              () => ref
                  .read(appControllerProvider.notifier)
                  .setTab(VoiceAloudTab.library),
        ),
      );
    }

    final error = _cameraInitError;
    if (error != null) {
      return AnimatedPageEntrance(
        child: _CameraInitErrorView(
          message: error,
          onRetry: _initCamera,
          onBack:
              () => ref
                  .read(appControllerProvider.notifier)
                  .setTab(VoiceAloudTab.library),
        ),
      );
    }

    return AnimatedPageEntrance(
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
        children: [
          Positioned.fill(child: _buildLivePreview()),
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
                        const SizedBox(width: 48, height: 48),
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
    ));
  }
}

class _MockScanUi extends StatelessWidget {
  const _MockScanUi();

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
                          onTap: () {},
                          child: const LucideSvgIcon(
                            'chevron-left',
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _BlackCircleButton(
                          onTap: () {},
                          child: const LucideSvgIcon(
                            'zap',
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
                        const SizedBox(width: 48, height: 48),
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

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
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
    return PressEffect(
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
    return PressEffect(
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
