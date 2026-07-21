import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authNotifierProvider.notifier).login(
          _email.text.trim(),
          _password.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go(roleHomePath(ref.read(authNotifierProvider).role));
    }
  }

  Future<void> _signInWithGoogle() async {
    final ok = await ref.read(authNotifierProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go(roleHomePath(ref.read(authNotifierProvider).role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: () => context.go('/welcome'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.forest,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Chào mừng trở lại',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Đăng nhập để tiếp tục với Chuỗi Xanh Việt',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                SurfaceCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Nhập email' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'Hoặc',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : _signInWithGoogle,
                  icon: const Text(
                    'G',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  label: const Text('Tiếp tục với Google'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Quên mật khẩu?'),
                ),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Chưa có tài khoản? Đăng ký'),
                ),
                TextButton(
                  onPressed: () => context.push('/register-farmer-applicant'),
                  child: const Text('Đăng ký nông hộ qua HTX'),
                ),
                TextButton(
                  onPressed: () => context.go('/consumer'),
                  child: const Text('Tiếp tục xem chợ (khách)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
