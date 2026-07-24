import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_providers.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _contactAddress = TextEditingController();
  final _zaloUserId = TextEditingController();
  String? _avatarUrl;
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _fullName.text = user?.fullName ?? '';
    _phone.text = user?.phone ?? '';
    _contactAddress.text = user?.contactAddress ?? '';
    _zaloUserId.text = user?.zaloUserId ?? '';
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _contactAddress.dispose();
    _zaloUserId.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_fullName.text.trim().isEmpty) return false;
    final phone = _phone.text.trim();
    if (phone.isEmpty) return true;
    return phone.replaceAll(RegExp(r'\D'), '').length >= 9;
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final urls =
          await ref.read(uploadRepositoryProvider).uploadImages([file.path]);
      if (urls.isNotEmpty) {
        setState(() => _avatarUrl = urls.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ref.read(authRepositoryProvider).updateProfile({
        'fullName': _fullName.text.trim(),
        'full_name': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'contactAddress': _contactAddress.text.trim(),
        'contact_address': _contactAddress.text.trim(),
        'zaloUserId': _zaloUserId.text.trim(),
        'zalo_user_id': _zaloUserId.text.trim(),
        if (_avatarUrl != null) ...{
          'avatarUrl': _avatarUrl,
          'avatar_url': _avatarUrl,
        },
      });
      ref.read(authNotifierProvider.notifier).setUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ')),
      );
      context.pop();
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
      appBar: AppBar(title: const Text('Sửa hồ sơ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.lime.withValues(alpha: 0.3),
                    backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null || _avatarUrl!.isEmpty
                        ? const Icon(Icons.person, size: 40, color: AppColors.forest)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: AppColors.forest,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploading ? null : _pickAvatar,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: AppColors.onPrimary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _fullName,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập họ và tên'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final phone = (v ?? '').trim();
                if (phone.isEmpty) return null;
                final digits = phone.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 9) {
                  return 'Số điện thoại ít nhất 9 chữ số';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _contactAddress,
              decoration: const InputDecoration(labelText: 'Địa chỉ liên hệ'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _zaloUserId,
              decoration: const InputDecoration(labelText: 'Zalo User ID'),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _loading || !_isFormValid ? null : _save,
              child: Text(_loading ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
