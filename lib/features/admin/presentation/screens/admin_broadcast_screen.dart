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
