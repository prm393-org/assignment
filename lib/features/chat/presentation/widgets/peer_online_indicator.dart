import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';

/// Green dot overlay for avatar when peer is online.
class PeerOnlineDot extends ConsumerWidget {
  const PeerOnlineDot({super.key, required this.backendUserId});

  final String backendUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (backendUserId.isEmpty) return const SizedBox.shrink();
    final online = ref.watch(peerOnlineByBackendIdProvider(backendUserId));
    final isOnline = online.valueOrNull ?? false;
    if (!isOnline) return const SizedBox.shrink();
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 2),
        ),
      ),
    );
  }
}

/// Subtitle under chat title: "Đang hoạt động" / "Ngoại tuyến".
class PeerOnlineSubtitle extends ConsumerWidget {
  const PeerOnlineSubtitle({super.key, required this.backendUserId});

  final String backendUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (backendUserId.isEmpty) return const SizedBox.shrink();
    final online = ref.watch(peerOnlineByBackendIdProvider(backendUserId));
    final isOnline = online.valueOrNull ?? false;
    return Text(
      isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isOnline ? AppColors.success : AppColors.muted,
          ),
    );
  }
}

/// Compact online label for conversation list rows.
class PeerOnlineLabel extends ConsumerWidget {
  const PeerOnlineLabel({super.key, required this.backendUserId});

  final String backendUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (backendUserId.isEmpty) return const SizedBox.shrink();
    final online = ref.watch(peerOnlineByBackendIdProvider(backendUserId));
    final isOnline = online.valueOrNull ?? false;
    if (!isOnline) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        '• online',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
