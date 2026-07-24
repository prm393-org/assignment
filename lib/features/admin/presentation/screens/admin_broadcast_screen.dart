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
  final _formKey = GlobalKey<FormState>();
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

  bool get _isFormValid =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập tiêu đề'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'Nội dung'),
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập nội dung'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Đối tượng'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                DropdownMenuItem(value: 'consumers', child: Text('Người mua')),
                DropdownMenuItem(value: 'farmers', child: Text('Nông dân')),
                DropdownMenuItem(value: 'cooperatives', child: Text('HTX')),
              ],
              onChanged: (v) => setState(() => _audience = v ?? 'all'),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _loading || !_isFormValid ? null : _send,
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }
}
