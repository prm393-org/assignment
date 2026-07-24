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
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _isEmailValid {
    final email = _email.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nhập email đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.',
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final email = (v ?? '').trim();
                  if (email.isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
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
                onPressed: _loading || !_isEmailValid ? null : _submit,
                child: const Text('Gửi yêu cầu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
