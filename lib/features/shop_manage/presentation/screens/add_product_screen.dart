import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/data/local/pending_product_draft.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/pending_product_draft_queue_provider.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/shop_manage_providers.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
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

  bool get _isFormValid {
    final price = double.tryParse(_price.text.trim());
    final stock = double.tryParse(_stock.text.trim());
    return _saleUnitId != null &&
        _name.text.trim().isNotEmpty &&
        price != null &&
        price > 0 &&
        stock != null &&
        _stock.text.trim().isNotEmpty;
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
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_price.text.trim());
    final stockQty = double.parse(_stock.text.trim());
    final name = _name.text.trim();
    final imageUrl =
        _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim();
    setState(() => _loading = true);
    try {
      await ref.read(shopManageRepositoryProvider).addProduct(widget.shopId, {
        'sale_unit_id': _saleUnitId,
        'name': name,
        'price': price,
        'stock_qty': stockQty,
        'image_url': ?imageUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sản phẩm')),
        );
        context.pop();
      }
    } on NetworkFailure {
      await ref.read(pendingProductDraftQueueProvider.notifier).enqueue(
            PendingProductDraft(
              localId: DateTime.now().microsecondsSinceEpoch.toString(),
              shopId: widget.shopId,
              saleUnitId: _saleUnitId!,
              name: name,
              price: price,
              stockQty: stockQty,
              imageUrl: imageUrl,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu offline, sẽ đồng bộ khi có mạng'),
          ),
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
        builder: (list) => Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _saleUnitId,
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
                validator: (v) =>
                    v == null ? 'Vui lòng chọn đơn vị bán' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên sản phẩm'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập giá';
                  }
                  final price = double.tryParse(v.trim());
                  if (price == null) return 'Giá không hợp lệ';
                  if (price <= 0) return 'Giá phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _stock,
                decoration: const InputDecoration(labelText: 'Tồn kho'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập tồn kho';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Tồn kho không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(labelText: 'URL ảnh'),
                readOnly: true,
              ),
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _loading || !_isFormValid ? null : _submit,
                child: const Text('Thêm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
