import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
      _success = false;
    });
    final err = await ref.read(authNotifierProvider.notifier).resetPassword(
          token: _token.text.trim(),
          password: _password.text,
          confirmPassword: _confirm.text,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = err == null;
      _message = err ?? 'Đặt lại mật khẩu thành công. Vui lòng đăng nhập.';
    });
    if (err == null) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dán mã token từ email (nếu có), rồi nhập mật khẩu mới.',
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _token,
                decoration: const InputDecoration(
                  labelText: 'Token (từ email)',
                  hintText: 'Dán mã xác nhận tại đây',
                ),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nhập token' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                validator: (v) =>
                    v != _password.text ? 'Mật khẩu không khớp' : null,
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
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Đặt lại mật khẩu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
