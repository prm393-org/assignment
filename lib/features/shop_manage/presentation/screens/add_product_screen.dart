import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/shop_manage_providers.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  String? _saleUnitId;
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _loading = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final urls =
          await ref.read(uploadRepositoryProvider).uploadImages([file.path]);
      if (urls.isNotEmpty) {
        setState(() => _imageUrl.text = urls.first);
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

  Future<void> _submit() async {
    if (_saleUnitId == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(shopManageRepositoryProvider).addProduct(widget.shopId, {
        'sale_unit_id': _saleUnitId,
        'name': _name.text.trim().isEmpty ? null : _name.text.trim(),
        'price': double.tryParse(_price.text) ?? 0,
        'stock_qty': double.tryParse(_stock.text),
        if (_imageUrl.text.trim().isNotEmpty)
          'image_url': _imageUrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sản phẩm')),
        );
        context.pop();
      }
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
    final units = ref.watch(availableSaleUnitsProvider(widget.shopId));
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm sản phẩm')),
      body: AsyncBody(
        value: units.asLike,
        onRetry: () =>
            ref.invalidate(availableSaleUnitsProvider(widget.shopId)),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Không còn đơn vị bán khả dụng',
        builder: (list) => ListView(
          padding: AppSpacing.screen,
          children: [
            DropdownButtonFormField<String>(
              value: _saleUnitId,
              decoration: const InputDecoration(labelText: 'Đơn vị bán'),
              items: [
                for (final u in list)
                  DropdownMenuItem(
                    value: u.id,
                    child: Text(
                      '${u.code} · ${u.cropName ?? ''} (${u.quantity} ${u.unit})',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _saleUnitId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration:
                  const InputDecoration(labelText: 'Tên sản phẩm (tuỳ chọn)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              decoration: const InputDecoration(labelText: 'Giá'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stock,
              decoration: const InputDecoration(labelText: 'Tồn kho'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrl,
              decoration: const InputDecoration(labelText: 'URL ảnh'),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(_uploading ? 'Đang tải...' : 'Chọn & tải ảnh'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}
