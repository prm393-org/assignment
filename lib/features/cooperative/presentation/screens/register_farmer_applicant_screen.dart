import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/cooperative/domain/entities/htx_item.dart';
import 'package:chuoi_xanh_viet/features/cooperative/presentation/providers/cooperative_providers.dart';

class RegisterFarmerApplicantScreen extends ConsumerStatefulWidget {
  const RegisterFarmerApplicantScreen({super.key});

  @override
  ConsumerState<RegisterFarmerApplicantScreen> createState() =>
      _RegisterFarmerApplicantScreenState();
}

class _RegisterFarmerApplicantScreenState
    extends ConsumerState<RegisterFarmerApplicantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _farmName = TextEditingController();
  String? _htxId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _farmName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_htxId == null || _htxId!.isEmpty) {
      setState(() => _error = 'Vui lòng chọn HTX');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session =
          await ref.read(cooperativeRepositoryProvider).registerFarmerApplicant(
                cooperativeUserId: _htxId!,
                email: _email.text.trim(),
                fullName: _fullName.text.trim(),
                phone: _phone.text.trim(),
                password: _password.text,
                confirmPassword: _confirm.text,
                farmName: _farmName.text.trim(),
              );
      await ref.read(authNotifierProvider.notifier).applySession(session);
      if (!mounted) return;
      context.go(roleHomePath(ref.read(authNotifierProvider).role));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is Failure ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final htxAsync = ref.watch(htxListProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký nông dân (HTX)')),
      body: AsyncBody(
        value: htxAsync.asLike,
        onRetry: () => ref.invalidate(htxListProvider(null)),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có HTX nào',
        builder: (List<HtxItem> htxList) {
          return SingleChildScrollView(
            padding: AppSpacing.screen,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _htxId,
                    decoration: const InputDecoration(labelText: 'HTX'),
                    items: [
                      for (final h in htxList)
                        DropdownMenuItem(value: h.id, child: Text(h.name)),
                    ],
                    onChanged: (v) => setState(() => _htxId = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Chọn HTX' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _phone,
                    decoration:
                        const InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _farmName,
                    decoration:
                        const InputDecoration(labelText: 'Tên nông trại'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Tối thiểu 6 ký tự'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Mật khẩu không khớp' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đăng ký'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
