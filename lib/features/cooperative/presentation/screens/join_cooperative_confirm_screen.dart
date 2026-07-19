import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/cooperative/presentation/providers/cooperative_providers.dart';

class JoinCooperativeConfirmScreen extends ConsumerStatefulWidget {
  const JoinCooperativeConfirmScreen({
    super.key,
    required this.farmId,
    required this.htxId,
  });

  final String farmId;
  final String htxId;

  @override
  ConsumerState<JoinCooperativeConfirmScreen> createState() =>
      _JoinCooperativeConfirmScreenState();
}

class _JoinCooperativeConfirmScreenState
    extends ConsumerState<JoinCooperativeConfirmScreen> {
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(cooperativeRepositoryProvider).requestJoin(
            cooperativeUserId: widget.htxId,
            farmId: widget.farmId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu tham gia HTX')),
      );
      context.pop();
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(htxListForFarmProvider(widget.farmId));
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận tham gia')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () =>
            ref.invalidate(htxListForFarmProvider(widget.farmId)),
        builder: (list) {
          final htx = list.where((h) => h.id == widget.htxId).firstOrNull;
          return Padding(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Xác nhận gửi yêu cầu tham gia HTX?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  htx?.name ?? 'HTX #${widget.htxId}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.forest,
                      ),
                ),
                if (htx?.address != null && htx!.address!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(htx.address!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (htx?.description != null &&
                    htx!.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(htx.description!),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi yêu cầu'),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: _loading ? null : () => context.pop(),
                  child: const Text('Huỷ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
