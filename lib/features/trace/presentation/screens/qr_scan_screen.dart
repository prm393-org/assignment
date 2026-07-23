import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:chuoi_xanh_viet/core/firebase/analytics_service.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR truy xuất')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: AppColors.ink.withValues(alpha: 0.55),
              padding: const EdgeInsets.all(16),
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
