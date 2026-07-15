import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../services/predict_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.api, required this.predictService});

  final ApiService api;
  final PredictService predictService;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

// Minimum confidence threshold — must match backend SCORE_THR
const double _kConfidenceThreshold = 0.001;
const double _kConfidenceHigh = 0.80;
const Set<String> _kIgnoredLabels = {};
const String _kNoValidDetectionMessage =
    'Tidak terdeteksi rak barang. Pastikan kamera diarahkan ke rak barang dengan jelas.';

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _busy = false;
  bool _cameraReady = false;
  String _status = 'Menyiapkan kamera...';
  List<Map<String, dynamic>> _detections = [];
  final Map<String, int> _manualCounts = {};
  String? _primaryLabel;
  List<CameraDescription> _cameras = [];
  String _saveStatus = '';
  XFile? _lastImage;
  final ImagePicker _picker = ImagePicker();
  bool _showingImage = false;
  Offset? _focusPoint;
  Timer? _focusTimer;

  /// Filter out detections below confidence threshold (client-side safety net)
  List<Map<String, dynamic>> _filterValid(List<Map<String, dynamic>> raw) {
    return raw.where((d) {
      final label = d['label']?.toString() ?? '';
      final score = (d['score'] as num?)?.toDouble() ?? 0;
      return score >= _kConfidenceThreshold && !_kIgnoredLabels.contains(label);
    }).toList();
  }

  /// Check if there is at least one valid detection to save
  bool get _hasValidDetections => _detections.any((d) {
    final label = d['label']?.toString() ?? '';
    final score = (d['score'] as num?)?.toDouble() ?? 0;
    return score >= _kConfidenceThreshold && !_kIgnoredLabels.contains(label);
  });

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _status = 'Tidak ada kamera. Gunakan upload foto.');
        return;
      }
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;
      _initFuture = controller.initialize();
      await _initFuture;
      await controller.setFlashMode(FlashMode.off);
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Failed to set FocusMode.auto: $e');
      }
      if (!mounted) return;
      setState(() {
        _cameraReady = true;
        _status = 'Arahkan kamera ke produk, lalu tekan Scan atau Upload foto.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Kamera tidak tersedia. Gunakan upload foto.');
    }
  }

  Future<void> _scanFrame() async {
    final controller = _controller;
    if (!_cameraReady || controller == null || _busy || !controller.value.isInitialized) return;
    _busy = true;
    setState(() {
      _status = 'Siapkan posisi kamera...';
      _saveStatus = '';
      _showingImage = false;
      _detections = [];
      _manualCounts.clear();
      _primaryLabel = null;
    });
    try {
      await controller.setFlashMode(FlashMode.off);
      if (controller.value.isTakingPicture) return;
      await _captureCountdown();
      final file = await controller.takePicture();
      _lastImage = file;
      await _processImage(file, emptyMessage: _kNoValidDetectionMessage);
    } catch (e) {
      if (mounted) setState(() => _status = 'Scan gagal: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _captureCountdown() async {
    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _status = 'Foto diambil dalam $i...');
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _processLastImage() async {
    final file = _lastImage;
    if (file == null || _busy) return;
    _busy = true;
    try {
      await _processImage(file, emptyMessage: _kNoValidDetectionMessage);
    } catch (e) {
      if (mounted) setState(() => _status = 'Proses gagal: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _processImage(XFile file, {required String emptyMessage}) async {
    setState(() {
      _lastImage = file;
      _showingImage = true;
      _status = 'Menganalisis gambar...';
      _saveStatus = '';
      _detections = [];
      _manualCounts.clear();
      _primaryLabel = null;
    });
    final rawDetections = await widget.predictService.predict(file);
    final detections = _filterValid(rawDetections);
    if (!mounted) return;
    setState(() {
      _detections = detections;
      _rehydrateManualCounts();
      _primaryLabel = detections.isEmpty ? null : detections.first['label']?.toString();
      _status = detections.isEmpty ? emptyMessage : 'Terdeteksi ${detections.length} produk';
    });
  }

  Future<void> _uploadPhoto() async {
    if (_busy) return;
    _busy = true;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (picked == null) return;
      await _processImage(picked, emptyMessage: _kNoValidDetectionMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Upload gagal: $e');
    } finally {
      _busy = false;
    }
  }

  void _resetToCamera() {
    setState(() {
      _showingImage = false;
      _detections = [];
      _manualCounts.clear();
      _primaryLabel = null;
      _saveStatus = '';
      _lastImage = null;
      _status = 'Arahkan kamera ke produk, lalu tekan Scan atau Upload foto.';
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        children: [
          // ── Header ──
          FadeSlideIn(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INVENTORY AUDIT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'SCAN ACTIVE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Camera Preview ──
          Container(
            height: 390,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder, width: 1),
              color: AppColors.surfaceLight,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPreviewArea(),
          ),
          const SizedBox(height: 16),

          // ── Action Buttons ──
          if (_showingImage)
            OutlinedButton.icon(
              onPressed: _resetToCamera,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              label: const Text('SCAN ULANG', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Ambil Foto',
                    color: AppColors.primary,
                    onTap: _busy ? null : _scanFrame,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    icon: Icons.image_outlined,
                    label: 'Upload Galeri',
                    color: AppColors.secondary,
                    onTap: _busy ? null : _uploadPhoto,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // ── Process Button ──
          GradientButton(
            label: 'Proses Gambar',
            icon: Icons.auto_fix_high_rounded,
            onPressed: _busy ? null : (_showingImage && _lastImage != null ? _processLastImage : _scanFrame),
            loading: _busy,
          ),
          const SizedBox(height: 20),

          // ── Results ──
          _buildResultsSection(),
          const SizedBox(height: 84),
        ],
      ),

      // ── Bottom Save Button ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GradientButton(
            label: _hasValidDetections ? 'SIMPAN HASIL' : 'TIDAK ADA DETEKSI VALID',
            icon: _hasValidDetections ? Icons.save_rounded : Icons.block_rounded,
            onPressed: _hasValidDetections ? _saveCurrentResult : null,
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_showingImage && _lastImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          kIsWeb
              ? Image.network(_lastImage!.path, fit: BoxFit.contain)
              : Image.file(File(_lastImage!.path), fit: BoxFit.contain),
          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: _DetectionOverlayPainter(
                  detections: _detections,
                  canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              );
            },
          ),
          _statusOverlay(),
        ],
      );
    }

    if (_controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(_status, style: const TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return GestureDetector(
          onTapDown: (TapDownDetails details) async {
            final controller = _controller;
            if (controller == null || !controller.value.isInitialized) return;
            try {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final Offset localPosition = box.globalToLocal(details.globalPosition);
              
              // Normalize coordinate values between 0.0 and 1.0
              final double dx = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
              final double dy = (localPosition.dy / box.size.height).clamp(0.0, 1.0);
              
              setState(() {
                _focusPoint = localPosition;
              });
              
              _focusTimer?.cancel();
              _focusTimer = Timer(const Duration(milliseconds: 800), () {
                if (mounted) {
                  setState(() => _focusPoint = null);
                }
              });

              await controller.setFocusPoint(Offset(dx, dy));
              await controller.setFocusMode(FocusMode.auto);
            } catch (e) {
              debugPrint('Tap to focus error: $e');
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              if (_focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 25,
                  top: _focusPoint!.dy - 25,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              _statusOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _statusOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.background.withOpacity(0.85),
              AppColors.background.withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            Expanded(
              child: Text(_status, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'ANALYSIS RESULTS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 14),

        if (_detections.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.shelves, size: 36, color: AppColors.textMuted),
                const SizedBox(height: 10),
                const Text(
                  'Arahkan kamera ke rak barang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aplikasi hanya dapat mendeteksi rak barang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          )
        else ...[
          ..._detections.map((det) {
            final label = det['label']?.toString() ?? '-';
            final scoreVal = ((det['score'] as num?) ?? 0).toDouble();
            final score = scoreVal.toStringAsFixed(2);
            final selected = label == _primaryLabel;
            final count = _manualCounts[label] ?? 1;

            // Confidence tier styling
            final isHigh = scoreVal >= _kConfidenceHigh;
            final tierLabel = isHigh ? '✓ VALID' : '⚠ VERIFIKASI';
            final tierColor = isHigh ? AppColors.success : AppColors.warning;
            final tierBgColor = isHigh ? AppColors.successBg : AppColors.warningBg;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? tierColor.withOpacity(0.5)
                      : AppColors.glassBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nama Produk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tierColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          tierLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tierColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Conf: $score', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBright,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: scoreVal.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [tierColor, tierColor.withOpacity(0.6)]),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah Terdeteksi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      Row(
                        children: [
                          _countButton('-', () => _decrementCount(label)),
                          const SizedBox(width: 14),
                          Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(width: 14),
                          _countButton('+', () => _incrementCount(label)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _deleteDetection(det),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                      label: const Text(
                        'HAPUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          _summaryCard(),
        ],
      ],
    );
  }

  Widget _summaryCard() {
    final items = _manualCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return GlassCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.summarize_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text('RINGKASAN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Total: ${_detections.length} produk terdeteksi', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('NAMA PRODUK', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textMuted))),
              SizedBox(width: 50, child: Text('JML', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textMuted))),
              SizedBox(width: 50, child: Text('CONF', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textMuted))),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((e) {
            final best = _detections.where((d) => d['label']?.toString() == e.key).map((d) => ((d['score'] as num?) ?? 0).toDouble()).fold<double>(0, (p, c) => c > p ? c : p);
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(e.key, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
                  SizedBox(width: 50, child: Text('${e.value}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary))),
                  SizedBox(width: 50, child: Text(best.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _countButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: AppColors.glassBorderLight),
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    );
  }

  void _rehydrateManualCounts() {
    _manualCounts.clear();
    for (final det in _detections) {
      final label = det['label']?.toString() ?? '-';
      _manualCounts[label] = (_manualCounts[label] ?? 0) + 1;
    }
  }

  void _incrementCount(String label) {
    setState(() {
      _manualCounts[label] = (_manualCounts[label] ?? 1) + 1;
      _primaryLabel = label;
    });
  }

  void _decrementCount(String label) {
    setState(() {
      final current = _manualCounts[label] ?? 1;
      _manualCounts[label] = current > 1 ? current - 1 : 1;
      _primaryLabel = label;
    });
  }

  void _deleteDetection(Map<String, dynamic> det) {
    setState(() {
      _detections.remove(det);
      _rehydrateManualCounts();
      final label = det['label']?.toString();
      if (label != null && !_manualCounts.containsKey(label)) {
        if (_primaryLabel == label) {
          _primaryLabel = _manualCounts.isNotEmpty ? _manualCounts.keys.first : null;
        }
      }
    });
  }

  Future<void> _addManualProduct() async {
    final productC = TextEditingController();
    var count = 1;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Input Manual'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: productC,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Nama produk'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah', style: TextStyle(color: AppColors.textSecondary)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: count > 1 ? () => setDialogState(() => count--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.textSecondary,
                          ),
                          Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          IconButton(
                            onPressed: () => setDialogState(() => count++),
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                TextButton(
                  onPressed: () {
                    final label = productC.text.trim();
                    if (label.isEmpty) return;
                    Navigator.pop(dialogContext, {'label': label, 'count': count});
                  },
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
    productC.dispose();
    if (result == null || !mounted) return;

    final label = result['label'] as String;
    final addedCount = result['count'] as int;
    setState(() {
      _detections.removeWhere((d) => d['label']?.toString() == label);
      for (var i = 0; i < addedCount; i++) {
        _detections.add({
          'label': label,
          'score': 1.0,
          'bbox_xyxy': [0, 0, 0, 0],
          'confidence_tier': 'manual',
          'is_valid': true,
        });
      }
      _manualCounts[label] = addedCount;
      _primaryLabel = label;
      _status = 'Input manual: $label x$addedCount';
    });
  }

  Future<void> _saveCurrentResult() async {
    if (_detections.isEmpty) return;
    final detectionsForSave = <Map<String, dynamic>>[];
    for (final entry in _manualCounts.entries) {
      final template = _detections.firstWhere(
        (d) => d['label']?.toString() == entry.key,
        orElse: () => {
          'label': entry.key,
          'score': 1.0,
          'bbox_xyxy': [0, 0, 0, 0],
          'confidence_tier': 'manual',
          'is_valid': true,
        },
      );
      for (var i = 0; i < entry.value; i++) {
        detectionsForSave.add(Map<String, dynamic>.from(template));
      }
    }

    try {
      await widget.api.saveAudit(
        imagePath: _lastImage?.path ?? '',
        algorithmUsed: 'fasterrcnn_resnet50_fpn',
        status: 'AMAN',
        sessionDate: DateTime.now().toIso8601String(),
        rawJson: {
          'detections': detectionsForSave,
          'counts': _manualCounts,
          'primary_label': _primaryLabel,
        },
      );
      if (!mounted) return;
      setState(() => _saveStatus = '✓ Hasil berhasil disimpan.');
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Berhasil'),
          content: const Text('Hasil scan sudah disimpan ke database.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveStatus = 'Gagal simpan: $e');
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gagal'),
          content: Text('Gagal simpan hasil.\n$e'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
        ),
      );
    }
  }
}

class _DetectionOverlayPainter extends CustomPainter {
  _DetectionOverlayPainter({required this.detections, required this.canvasSize});

  final List<Map<String, dynamic>> detections;
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;
    final imgW = (detections.first['image_width'] as num?)?.toDouble();
    final imgH = (detections.first['image_height'] as num?)?.toDouble();
    if (imgW == null || imgH == null || imgW <= 0 || imgH <= 0) return;

    final scaleX = canvasSize.width / imgW;
    final scaleY = canvasSize.height / imgH;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final renderW = imgW * scale;
    final renderH = imgH * scale;
    final offsetX = (canvasSize.width - renderW) / 2;
    final offsetY = (canvasSize.height - renderH) / 2;

    for (final det in detections) {
      final bbox = det['bbox_xyxy'];
      if (bbox is! List || bbox.length != 4) continue;

      final scoreVal = ((det['score'] as num?) ?? 0).toDouble();

      // Color-coded bounding boxes based on confidence tier
      final Color boxColor;
      if (scoreVal >= _kConfidenceHigh) {
        boxColor = const Color(0xFF00E5A0); // Green for HIGH
      } else {
        boxColor = const Color(0xFFFFB74D); // Orange for MEDIUM
      }

      final boxPaint = Paint()
        ..color = boxColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final xmin = (bbox[0] as num).toDouble();
      final ymin = (bbox[1] as num).toDouble();
      final xmax = (bbox[2] as num).toDouble();
      final ymax = (bbox[3] as num).toDouble();
      final rect = Rect.fromLTRB(
        offsetX + xmin * scale,
        offsetY + ymin * scale,
        offsetX + xmax * scale,
        offsetY + ymax * scale,
      );

      // Draw rounded rect instead of sharp
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), boxPaint);

      final label = det['label']?.toString() ?? '';
      final scoreStr = scoreVal.toStringAsFixed(2);
      final tierTag = scoreVal >= _kConfidenceHigh ? '✓' : '⚠';
      if (label.isEmpty) continue;

      final textBg = Paint()..color = boxColor.withOpacity(0.85);
      const textStyle = TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold);

      final tp = TextPainter(
        text: TextSpan(text: '$tierTag $label $scoreStr', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelY = rect.top - tp.height - 4;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left,
          labelY < offsetY ? rect.top : labelY,
          tp.width + 10,
          tp.height + 6,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(labelRect, textBg);
      tp.paint(canvas, Offset(labelRect.left + 5, labelRect.top + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionOverlayPainter old) =>
      old.detections != detections || old.canvasSize != canvasSize;
}
