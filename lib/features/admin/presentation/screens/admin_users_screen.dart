import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
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
      appBar: AppBar(title: const Text('Người dùng')),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên/email/SĐT',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (v) => setState(() => _q = v.trim()),
            ),
          ),
          Expanded(
            child: AsyncBody(
              value: async.asLike,
              onRetry: () => ref.invalidate(adminUsersProvider(_q)),
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Không có người dùng',
              builder: (page) => ListView.separated(
                padding: AppSpacing.screen,
                itemCount: page.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u = page.items[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.hairline),
                    ),
                    title: Text(u.fullName),
                    subtitle: Text('${u.role} · ${u.email ?? u.phone ?? ''}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (status) async {
                        try {
                          await ref.read(adminRepositoryProvider).patchUserStatus(u.id, status);
                          ref.invalidate(adminUsersProvider(_q));
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e is Failure ? e.message : '$e')),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'active', child: Text('Kích hoạt')),
                        PopupMenuItem(value: 'suspended', child: Text('Khoá')),
                      ],
                      child: Chip(label: Text(u.status)),
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
