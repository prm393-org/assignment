# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')
TEST = Path(r'd:\fpt\ky8\PRM393\assignment\test')


def w(rel: str, content: str, root: Path = ROOT) -> None:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(('test/' if root == TEST else '') + rel)


w('features/admin/presentation/screens/admin_home_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/providers/admin_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Quản trị')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(adminDashboardProvider),
        builder: (s) => ListView(
          padding: AppSpacing.screen,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _tile(context, 'Người dùng', '${s.totalUsers}'),
                _tile(context, 'Chứng nhận chờ', '${s.pendingCerts}'),
                _tile(context, 'User 7 ngày', '${s.newUsers7d}'),
                _tile(context, 'Đơn 7 ngày', '${s.newOrders7d}'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: const Icon(Icons.verified_user, color: AppColors.forest),
              title: const Text('Duyệt chứng nhận'),
              onTap: () => context.push('/admin/certificates'),
            ),
            ListTile(
              leading: const Icon(Icons.campaign, color: AppColors.forest),
              title: const Text('Gửi thông báo hàng loạt'),
              onTap: () => context.push('/admin/broadcast'),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.forest),
              title: const Text('Nhật ký kiểm toán'),
              onTap: () => context.push('/admin/audit-logs'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.forest)),
        ],
      ),
    );
  }
}
''')

w('features/admin/presentation/screens/admin_users_screen.dart', r'''
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
''')

w('features/admin/presentation/screens/admin_certificates_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/certificate/presentation/providers/certificate_providers.dart';

class AdminCertificatesScreen extends ConsumerWidget {
  const AdminCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingAdminCertificatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chứng nhận chờ duyệt')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(pendingAdminCertificatesProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Không còn chứng nhận chờ',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = page.items[i];
            return Card(
              child: ListTile(
                title: Text('${c.type} · ${c.certificateNo ?? ''}'),
                subtitle: Text(c.farmName ?? c.farmId),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.success),
                      onPressed: () async {
                        try {
                          await ref.read(certificateRepositoryProvider).approve(c.id);
                          ref.invalidate(pendingAdminCertificatesProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e is Failure ? e.message : '$e')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.error),
                      onPressed: () async {
                        try {
                          await ref.read(certificateRepositoryProvider).reject(c.id, 'Không đạt yêu cầu');
                          ref.invalidate(pendingAdminCertificatesProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e is Failure ? e.message : '$e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
''')

w('features/admin/presentation/screens/admin_broadcast_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/providers/admin_providers.dart';

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _audience = 'all';
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(adminRepositoryProvider).broadcast(
            title: _title.text.trim(),
            body: _body.text.trim(),
            audience: _audience,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi ${result['sentCount'] ?? result['recipientTotal'] ?? ''}')),
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast thông báo')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Tiêu đề')),
          const SizedBox(height: 12),
          TextField(controller: _body, decoration: const InputDecoration(labelText: 'Nội dung'), maxLines: 5),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _audience,
            decoration: const InputDecoration(labelText: 'Đối tượng'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              DropdownMenuItem(value: 'consumers', child: Text('Người mua')),
              DropdownMenuItem(value: 'farmers', child: Text('Nông dân')),
              DropdownMenuItem(value: 'cooperatives', child: Text('HTX')),
            ],
            onChanged: (v) => setState(() => _audience = v ?? 'all'),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _loading ? null : _send, child: const Text('Gửi')),
        ],
      ),
    );
  }
}
''')

w('features/admin/presentation/screens/admin_audit_logs_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/providers/admin_providers.dart';

class AdminAuditLogsScreen extends ConsumerWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký kiểm toán')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(auditLogsProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có log',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final log = page.items[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              title: Text('${log.module} · ${log.action}'),
              subtitle: Text(
                '${log.actorName ?? 'system'} · ${Formatters.dateTime(log.createdAt)}\n${log.path ?? ''}',
              ),
              isThreeLine: true,
              trailing: Text(
                log.status,
                style: TextStyle(
                  color: log.status == 'success' ? AppColors.success : AppColors.error,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
''')

print('admin screens done')
