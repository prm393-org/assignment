import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/certificate/presentation/providers/certificate_providers.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCertificatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chứng nhận')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _submit(context, ref),
        child: const Icon(Icons.upload_file),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(myCertificatesProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có chứng nhận',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = page.items[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              title: Text('${c.type.toUpperCase()} · ${c.certificateNo ?? ''}'),
              subtitle: Text(
                '${c.farmName ?? ''} · ${c.status}\n${Formatters.date(c.issuedAt)}',
              ),
              isThreeLine: true,
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final farms = await ref.read(myFarmsProvider.future);
    if (farms.isEmpty) return;
    if (!context.mounted) return;
    String farmId = farms.first.id;
    final no = TextEditingController();
    final issuer = TextEditingController(text: 'VietGAP');
    final url = TextEditingController();
    var uploading = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nộp chứng nhận'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: farmId,
                  items: [
                    for (final f in farms)
                      DropdownMenuItem(value: f.id, child: Text(f.name)),
                  ],
                  onChanged: (v) => setLocal(() => farmId = v ?? farmId),
                ),
                TextField(
                  controller: no,
                  decoration: const InputDecoration(labelText: 'Số chứng nhận'),
                ),
                TextField(
                  controller: issuer,
                  decoration: const InputDecoration(labelText: 'Đơn vị cấp'),
                ),
                TextField(
                  controller: url,
                  decoration: const InputDecoration(labelText: 'URL file'),
                  readOnly: true,
                ),
                const SizedBox(height: 8),
                if (uploading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (file == null) return;
                            setLocal(() => uploading = true);
                            try {
                              final urls = await ref
                                  .read(uploadRepositoryProvider)
                                  .uploadImages([file.path]);
                              if (urls.isNotEmpty) {
                                setLocal(() => url.text = urls.first);
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e is Failure ? e.message : '$e',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              setLocal(() => uploading = false);
                            }
                          },
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Ảnh'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (file == null) return;
                            setLocal(() => uploading = true);
                            try {
                              final urls = await ref
                                  .read(uploadRepositoryProvider)
                                  .uploadDocuments([file.path]);
                              if (urls.isNotEmpty) {
                                setLocal(() => url.text = urls.first);
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e is Failure ? e.message : '$e',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              setLocal(() => uploading = false);
                            }
                          },
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Tài liệu'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: uploading || url.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final now = DateTime.now();
      await ref.read(certificateRepositoryProvider).create({
        'farm_id': farmId,
        'type': 'vietgap',
        'certificate_no': no.text.trim(),
        'issuer': issuer.text.trim(),
        'issued_at': now.toIso8601String().substring(0, 10),
        'expires_at':
            DateTime(now.year + 1).toIso8601String().substring(0, 10),
        'file_url': url.text.trim(),
      });
      ref.invalidate(myCertificatesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }
}
