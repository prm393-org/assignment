# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


w('features/forum/presentation/screens/forum_list_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class ForumListScreen extends ConsumerWidget {
  const ForumListScreen({super.key, this.basePath = '/consumer'});

  final String basePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(forumPostsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diễn đàn')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('$basePath/forum/create'),
        child: const Icon(Icons.edit),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(forumPostsProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có bài viết',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final p = page.items[i];
            return ListTile(
              onTap: () => context.push('$basePath/forum/${p.id}'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(p.title),
              subtitle: Text(
                '${p.author?.fullName ?? 'Ẩn danh'} · ${Formatters.dateTime(p.createdAt)} · ${p.commentCount} bình luận',
              ),
            );
          },
        ),
      ),
    );
  }
}
''')

w('features/forum/presentation/screens/forum_post_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class ForumPostScreen extends ConsumerStatefulWidget {
  const ForumPostScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<ForumPostScreen> createState() => _ForumPostScreenState();
}

class _ForumPostScreenState extends ConsumerState<ForumPostScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(forumRepositoryProvider).createComment(widget.postId, text);
      _comment.clear();
      ref.invalidate(forumCommentsProvider(widget.postId));
      ref.invalidate(forumPostProvider(widget.postId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(forumPostProvider(widget.postId));
    final comments = ref.watch(forumCommentsProvider(widget.postId));
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: AsyncBody(
        value: post.asLike,
        onRetry: () => ref.invalidate(forumPostProvider(widget.postId)),
        builder: (p) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screen,
                children: [
                  Text(p.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${p.author?.fullName ?? ''} · ${Formatters.dateTime(p.createdAt)}',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(p.content),
                  const Divider(height: 32),
                  Text('Bình luận', style: Theme.of(context).textTheme.titleMedium),
                  AsyncBody(
                    value: comments.asLike,
                    isEmpty: (list) => list.isEmpty,
                    emptyMessage: 'Chưa có bình luận',
                    builder: (list) => Column(
                      children: [
                        for (final c in list)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.author?.fullName ?? 'Người dùng'),
                            subtitle: Text(c.content),
                            trailing: Text(Formatters.date(c.createdAt)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: AppSpacing.screen,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        decoration: const InputDecoration(
                          hintText: 'Viết bình luận...',
                        ),
                      ),
                    ),
                    IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''')

w('features/forum/presentation/screens/create_forum_post_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class CreateForumPostScreen extends ConsumerStatefulWidget {
  const CreateForumPostScreen({super.key});

  @override
  ConsumerState<CreateForumPostScreen> createState() =>
      _CreateForumPostScreenState();
}

class _CreateForumPostScreenState extends ConsumerState<CreateForumPostScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(forumRepositoryProvider).createPost(
            title: _title.text.trim(),
            content: _content.text.trim(),
          );
      ref.invalidate(forumPostsProvider);
      if (mounted) context.pop();
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
      appBar: AppBar(title: const Text('Tạo bài viết')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _content,
            decoration: const InputDecoration(labelText: 'Nội dung'),
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: const Text('Đăng bài'),
          ),
        ],
      ),
    );
  }
}
''')

w('features/profile/presentation/screens/profile_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.roleLinks = const []});

  final List<ProfileLink> roleLinks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.lime.withValues(alpha: 0.3),
            child: Text(
              (user?.fullName.isNotEmpty == true)
                  ? user!.fullName.characters.first.toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 28, color: AppColors.forest),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(user?.fullName ?? '', style: Theme.of(context).textTheme.titleLarge),
          Text(user?.email ?? ''),
          Text(user?.phone ?? ''),
          if (user?.authRole != null)
            Chip(label: Text(roleLabel(user!.authRole!))),
          const SizedBox(height: AppSpacing.xl),
          for (final link in roleLinks)
            ListTile(
              leading: Icon(link.icon, color: AppColors.forest),
              title: Text(link.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(link.path),
            ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.forest),
            title: const Text('Thông báo'),
            onTap: () {
              final base = roleHomePath(auth.role);
              context.push('$base/notifications');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Đăng xuất'),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class ProfileLink {
  const ProfileLink({required this.label, required this.path, required this.icon});
  final String label;
  final String path;
  final IconData icon;
}
''')

w('features/notification/presentation/screens/notifications_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(notificationsProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Không có thông báo',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final n = page.items[i];
            return ListTile(
              tileColor: n.read ? AppColors.surface : AppColors.lime.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              title: Text(n.title),
              subtitle: Text('${n.content}\n${Formatters.dateTime(n.createdAt)}'),
              isThreeLine: true,
              onTap: () async {
                if (!n.read) {
                  await ref.read(notificationRepositoryProvider).markRead(n.id);
                  ref.invalidate(notificationsProvider);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
''')

w('features/trace/presentation/screens/trace_resolve_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/trace/domain/entities/trace_info.dart';
import 'package:chuoi_xanh_viet/features/trace/presentation/providers/trace_providers.dart';

class TraceResolveScreen extends ConsumerStatefulWidget {
  const TraceResolveScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<TraceResolveScreen> createState() => _TraceResolveScreenState();
}

class _TraceResolveScreenState extends ConsumerState<TraceResolveScreen> {
  late final TextEditingController _code;
  bool _loading = false;
  String? _error;
  TraceSaleUnit? _unit;
  TraceSeasonDetail? _detail;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
      _unit = null;
      _detail = null;
    });
    try {
      final repo = ref.read(traceRepositoryProvider);
      final unit = await repo.resolveByCode(_code.text.trim());
      final detail = await repo.getSeasonDetail(unit.seasonId);
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _detail = detail;
      });
    } catch (e) {
      setState(() => _error = e is Failure ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truy xuất nguồn gốc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/consumer/trace/scan'),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          TextField(
            controller: _code,
            decoration: const InputDecoration(
              labelText: 'Mã truy xuất / short code',
              prefixIcon: Icon(Icons.qr_code),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _loading ? null : _resolve,
            child: Text(_loading ? 'Đang tra cứu...' : 'Tra cứu'),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          if (_unit != null && _detail != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(_detail!.cropName, style: Theme.of(context).textTheme.headlineMedium),
            Text('Mùa vụ: ${_detail!.seasonCode}'),
            Text('Nông trại: ${_detail!.farmName}'),
            Text('Chủ hộ: ${_detail!.ownerName ?? '—'}'),
            Text('Địa phương: ${_detail!.province ?? '—'}'),
            Text('Đơn vị bán: ${_unit!.code}'),
            const SizedBox(height: AppSpacing.xl),
            Text('Nhật ký', style: Theme.of(context).textTheme.titleLarge),
            for (final d in _detail!.diaries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(diaryEventLabels[d['eventType']] ?? d['eventType'] ?? ''),
                subtitle: Text(d['description'] ?? ''),
                trailing: Text(d['eventDate'] ?? ''),
              ),
          ],
        ],
      ),
    );
  }
}
''')

w('features/trace/presentation/screens/qr_scan_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

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
    final code = raw.contains('/') ? raw.split('/').last : raw;
    context.pushReplacement('/consumer/trace?code=${Uri.encodeComponent(code)}');
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
''')

print('forum profile notify trace done')
