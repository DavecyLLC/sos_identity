import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IdCaptureScreen extends StatefulWidget {
  final String title; // e.g. "Capture front side"
  const IdCaptureScreen({super.key, required this.title});

  @override
  State<IdCaptureScreen> createState() => _IdCaptureScreenState();
}

class _IdCaptureScreenState extends State<IdCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _flashOn = false;
  double _exposureOffset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _restoreOrientations();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreOrientations() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _init() async {
    setState(() => _initializing = true);

    await _lockLandscape();

    final cams = await availableCameras();
    // Prefer back camera
    final cam = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );

    final controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();

    // Try to enable continuous autofocus if supported
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {}

    // Exposure
    try {
      _exposureOffset = 0.0;
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}

    _controller = controller;

    if (!mounted) return;
    setState(() => _initializing = false);
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null) return;

    try {
      if (_flashOn) {
        await c.setFlashMode(FlashMode.off);
      } else {
        // torch gives constant light; if not supported it may throw
        await c.setFlashMode(FlashMode.torch);
      }
      setState(() => _flashOn = !_flashOn);
    } catch (_) {
      // fallback: do nothing if device doesn’t support torch
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flash/torch not supported on this device.')),
      );
    }
  }

  Future<void> _setExposure(double v) async {
    final c = _controller;
    if (c == null) return;

    setState(() => _exposureOffset = v);
    try {
      await c.setExposureOffset(v);
    } catch (_) {
      // some devices don’t support exposure offset
    }
  }

  Future<void> _takePhoto() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    try {
      final file = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop<String>(file.path); // return temp path; you will copy to permanent
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to take photo. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _initializing || c == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Camera preview is portrait by default; rotate to fit landscape
                Center(
                  child: RotatedBox(
                    quarterTurns: 1, // adjust if needed per device orientation
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio,
                      child: CameraPreview(c),
                    ),
                  ),
                ),

                // ID frame guide
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.70,
                      height: MediaQuery.of(context).size.height * 0.55,
                      decoration: BoxDecoration(
                        border: Border.all(width: 3, color: Colors.white),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                // Top-right controls
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'flash',
                        onPressed: _toggleFlash,
                        child: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
                      ),
                      const SizedBox(height: 12),
                      // Exposure slider (small)
                      Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Exposure', style: TextStyle(color: Colors.white)),
                            Slider(
                              value: _exposureOffset,
                              min: -2.0,
                              max: 2.0,
                              onChanged: _setExposure,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom capture bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Hold your ID inside the box.\nUse flash if dark.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Center(
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

