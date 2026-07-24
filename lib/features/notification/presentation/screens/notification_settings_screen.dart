import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/providers/messaging_providers.dart';

/// Notification permission status + the device's FCM token, copyable in-app so
/// a tester can paste it into Firebase Console without reading the run logs.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isGranted = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final messaging = ref.read(messagingServiceProvider);
    final granted = await messaging.hasPermission();
    final token = granted ? await messaging.getToken() : null;
    if (!mounted) return;
    setState(() {
      _isGranted = granted;
      _token = token;
      _isLoading = false;
    });
  }

  Future<void> _enable() async {
    final messaging = ref.read(messagingServiceProvider);
    final granted = await messaging.requestPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa được cấp quyền. Mở Cài đặt hệ thống của thiết bị để bật '
            'thông báo cho ứng dụng.',
          ),
        ),
      );
    }
    await _load();
  }

  Future<void> _copyToken() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép FCM token')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.screen,
              children: [
                SurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isGranted
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: AppColors.forest,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isGranted
                                  ? 'Đã bật thông báo'
                                  : 'Chưa bật thông báo',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _isGranted
                                  ? 'Thiết bị này sẽ nhận thông báo đẩy.'
                                  : 'Bật để nhận thông báo đơn hàng, chứng '
                                      'nhận, tin nhắn và thông báo chung.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isGranted) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _enable,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Bật thông báo'),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text('FCM token', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Dùng để gửi thử thông báo từ Firebase Console.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _token ?? 'Chưa có token. Hãy bật thông báo trước.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (_token == null || _token!.isEmpty)
                                  ? null
                                  : _copyToken,
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Sao chép'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }
}
