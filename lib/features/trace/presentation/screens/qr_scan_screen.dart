import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/firebase/analytics_service.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.resultPath = '/consumer/trace'});

  final String resultPath;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR truy xuất')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
            errorBuilder: _errorBuilder,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: AppColors.ink.withValues(alpha: 0.55),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: const Text(
                'Đưa mã QR đơn vị bán vào khung hình',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
