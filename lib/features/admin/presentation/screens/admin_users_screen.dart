import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminUsersProvider(_q));
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hệ thống', style: Theme.of(context).textTheme.bodySmall),
            Text('Người dùng', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screen.copyWith(bottom: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên / email / SĐT',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (v) => setState(() => _q = v.trim()),
            ),
          ),
          Expanded(
            child: AsyncBody(
              value: async.asLike,
              onRetry: () => ref.invalidate(adminUsersProvider(_q)),
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Không có người dùng phù hợp',
              builder: (page) => ListView.separated(
                padding: AppSpacing.screen,
                itemCount: page.items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  final u = page.items[i];
                  final initial = u.fullName.isNotEmpty
                      ? u.fullName.characters.first.toUpperCase()
                      : '?';
                  final active = u.status.toLowerCase() == 'active';
                  return SurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.mint,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                u.email ?? u.phone ?? '—',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  StatusChip(
                                    label: u.role,
                                    tone: StatusTone.info,
                                  ),
                                  StatusChip(
                                    label: active ? 'Hoạt động' : u.status,
                                    tone: active
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (status) async {
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .patchUserStatus(u.id, status);
                              ref.invalidate(adminUsersProvider(_q));
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e is Failure ? e.message : '$e',
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'active',
                              child: Text('Kích hoạt'),
                            ),
                            PopupMenuItem(
                              value: 'suspended',
                              child: Text('Khoá'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
