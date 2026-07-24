import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/firebase/analytics_service.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';

const _scanBorderColor = Color(0xFF56CCF2);

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.resultPath = '/consumer/trace'});

  final String resultPath;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Rect _scanWindow(Size size) {
    final side = min(size.width * 0.72, size.height * 0.44);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: side,
      height: side,
    );
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    unawaited(AnalyticsService.logScanQr(
      widget.resultPath.startsWith('/farmer') ? 'farmer' : 'consumer',
    ));
    final code = raw.contains('/') ? raw.split('/').last : raw;
    context.pushReplacement(
      '${widget.resultPath}?code=${Uri.encodeComponent(code)}',
    );
  }

  Future<void> _pickFromGallery() async {
    if (_handled) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    final capture = await _controller.analyzeImage(file.path);
    if (!mounted) return;

    if (capture == null || capture.barcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã QR trong ảnh')),
      );
      return;
    }
    _handleCapture(capture);
  }

  Widget _errorBuilder(BuildContext context, MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final unsupported = error.errorCode == MobileScannerErrorCode.unsupported;
    final message = denied
        ? 'Cần quyền camera để quét mã QR. Mở cài đặt và cấp quyền camera.'
        : unsupported
            ? 'Thiết bị không có camera hoặc không hỗ trợ quét QR.'
            : (error.errorDetails?.message ??
                'Không thể mở camera. Thử lại hoặc kiểm tra quyền.');
    return ErrorState(
      message: message,
      retryLabel: denied ? 'Mở cài đặt' : 'Thử lại',
      onRetry: denied
          ? () => Geolocator.openAppSettings()
          : () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onPrimary,
        iconTheme: const IconThemeData(color: AppColors.onPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.onPrimary),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onPrimary,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Quét mã QR',
          style: TextStyle(color: AppColors.onPrimary),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (!state.isInitialized ||
                  state.torchState == TorchState.unavailable) {
                return const SizedBox(width: 48);
              }
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: 'Bật/tắt đèn flash',
                onPressed: _controller.toggleTorch,
                icon: Icon(
                  torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: AppColors.onPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scanWindow = _scanWindow(constraints.biggest);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      scanWindow: scanWindow,
                      onDetect: _handleCapture,
                      errorBuilder: _errorBuilder,
                      overlayBuilder: (context, _) {
                        return ScanWindowOverlay(
                          controller: _controller,
                          scanWindow: scanWindow,
                          borderRadius: BorderRadius.circular(16),
                          borderColor: _scanBorderColor,
                          borderWidth: 2,
                          color: AppColors.ink.withValues(alpha: 0.58),
                        );
                      },
                    ),
                    Positioned(
                      top: scanWindow.top + AppSpacing.md,
                      left: scanWindow.left + AppSpacing.lg,
                      right:
                          constraints.maxWidth - scanWindow.right + AppSpacing.lg,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Di chuyển camera vào mã QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.ink.withValues(alpha: 0.88),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: AppColors.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _pickFromGallery,
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.ink,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Tải ảnh lên',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
