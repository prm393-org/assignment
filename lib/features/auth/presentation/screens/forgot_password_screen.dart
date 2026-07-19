import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final err = await ref
        .read(authNotifierProvider.notifier)
        .forgotPassword(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = err == null;
      _message = err ?? 'Đã gửi hướng dẫn đặt lại mật khẩu tới email.';
    });
    if (err == null) {
      context.push('/reset-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nhập email đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.'),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _success ? AppColors.success : AppColors.error,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }
}
