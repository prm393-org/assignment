# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


w('features/shop_manage/presentation/screens/shop_manage_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/shop_manage_providers.dart';

class ShopManageScreen extends ConsumerWidget {
  const ShopManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myShopsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gian hàng của tôi')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createShop(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(myShopsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có gian hàng',
        builder: (list) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final s = list[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(s.name),
              subtitle: Text(s.farmName ?? s.status),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/farmer/shop/${s.id}/add-product'),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createShop(BuildContext context, WidgetRef ref) async {
    final farms = await ref.read(myFarmsProvider.future);
    if (farms.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần tạo nông trại trước')),
      );
      return;
    }
    String farmId = farms.first.id;
    final name = TextEditingController(text: 'Gian hàng ${farms.first.name}');
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tạo gian hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: farmId,
                items: [
                  for (final f in farms)
                    DropdownMenuItem(value: f.id, child: Text(f.name)),
                ],
                onChanged: (v) => setLocal(() => farmId = v ?? farmId),
                decoration: const InputDecoration(labelText: 'Nông trại'),
              ),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên gian hàng')),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Mô tả')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(shopManageRepositoryProvider).createShop(
            farmId: farmId,
            name: name.text.trim(),
            description: desc.text.trim().isEmpty ? null : desc.text.trim(),
          );
      ref.invalidate(myShopsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }
}
''')

w('features/shop_manage/presentation/screens/add_product_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/shop_manage_providers.dart';

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
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
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
        onRetry: () => ref.invalidate(availableSaleUnitsProvider(widget.shopId)),
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
                    child: Text('${u.code} · ${u.cropName ?? ''} (${u.quantity} ${u.unit})'),
                  ),
              ],
              onChanged: (v) => setState(() => _saleUnitId = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên sản phẩm (tuỳ chọn)')),
            const SizedBox(height: 12),
            TextField(controller: _price, decoration: const InputDecoration(labelText: 'Giá'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: _stock, decoration: const InputDecoration(labelText: 'Tồn kho'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            FilledButton(onPressed: _loading ? null : _submit, child: const Text('Thêm')),
          ],
        ),
      ),
    );
  }
}
''')

w('features/order/presentation/screens/earnings_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopEarningsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Doanh thu')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(shopEarningsProvider),
        builder: (e) => ListView(
          padding: AppSpacing.screen,
          children: [
            _card('Đã thanh toán cho bạn', Formatters.money(e.finalizedSellerPayout)),
            _card('GMV đã chốt', Formatters.money(e.totalGmvFinalized)),
            _card('Hoa hồng nền tảng', Formatters.money(e.totalPlatformCommissionFinalized)),
            _card('Ước tính đang chờ', Formatters.money(e.pipelineEstimatedPayout)),
            _card('Số đơn đã chốt', '${e.finalizedOrderCount}'),
            _card('Số đơn pipeline', '${e.pipelineOrderCount}'),
          ],
        ),
      ),
    );
  }

  Widget _card(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
      ),
    );
  }
}
''')

w('features/certificate/presentation/screens/certificates_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/certificate/presentation/providers/certificate_providers.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';

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
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = page.items[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              title: Text('${c.type.toUpperCase()} · ${c.certificateNo ?? ''}'),
              subtitle: Text('${c.farmName ?? ''} · ${c.status}\n${Formatters.date(c.issuedAt)}'),
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
    String farmId = farms.first.id;
    final no = TextEditingController();
    final issuer = TextEditingController(text: 'VietGAP');
    final url = TextEditingController(text: 'https://example.com/cert.pdf');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nộp chứng nhận'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: farmId,
                items: [for (final f in farms) DropdownMenuItem(value: f.id, child: Text(f.name))],
                onChanged: (v) => setLocal(() => farmId = v ?? farmId),
              ),
              TextField(controller: no, decoration: const InputDecoration(labelText: 'Số chứng nhận')),
              TextField(controller: issuer, decoration: const InputDecoration(labelText: 'Đơn vị cấp')),
              TextField(controller: url, decoration: const InputDecoration(labelText: 'URL file')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi')),
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
        'expires_at': DateTime(now.year + 1).toIso8601String().substring(0, 10),
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
''')

w('features/ai/presentation/screens/ai_assistant_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/ai/presentation/providers/ai_providers.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _input = TextEditingController();
  final _messages = <Map<String, String>>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _sendChat() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
      _input.clear();
    });
    try {
      final repo = ref.read(chatbotRepositoryProvider);
      final reply = _tabs.index == 1
          ? await repo.market(text)
          : await repo.chat(text, history: _messages);
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      setState(() => _messages.add({
            'role': 'assistant',
            'content': e is Failure ? e.message : '$e',
          }));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _diagnose() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final reply = await ref.read(chatbotRepositoryProvider).diagnose(imagePath: file.path);
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      setState(() => _messages.add({
            'role': 'assistant',
            'content': e is Failure ? e.message : '$e',
          }));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Thị trường'),
            Tab(text: 'Chẩn đoán'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.screen,
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.forest : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: isUser ? null : Border.all(color: AppColors.hairline),
                    ),
                    child: Text(
                      m['content'] ?? '',
                      style: TextStyle(color: isUser ? AppColors.onPrimary : AppColors.ink),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_tabs.index == 2)
            Padding(
              padding: AppSpacing.screen,
              child: FilledButton.icon(
                onPressed: _loading ? null : _diagnose,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Chọn ảnh cây trồng'),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: AppSpacing.screen,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: const InputDecoration(hintText: 'Nhập câu hỏi...'),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _sendChat,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
''')

w('features/agri_trend/presentation/screens/agri_trend_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/presentation/providers/agri_trend_providers.dart';

class AgriTrendScreen extends ConsumerWidget {
  const AgriTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agriTrendProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xu hướng nông nghiệp'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(agriTrendProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(agriTrendProvider),
        builder: (t) => ListView(
          padding: AppSpacing.screen,
          children: [
            Text(Formatters.dateTime(t.generatedAt), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Text(t.summary),
            const SizedBox(height: AppSpacing.xl),
            Text('Cây trồng nóng', style: Theme.of(context).textTheme.titleLarge),
            for (final c in t.hotCrops)
              Card(
                child: ListTile(
                  title: Text(c['name'] ?? ''),
                  subtitle: Text(c['reason'] ?? ''),
                  trailing: Text(c['sentiment'] ?? ''),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('Cảnh báo', style: Theme.of(context).textTheme.titleLarge),
            for (final a in t.alerts)
              ListTile(
                leading: const Icon(Icons.warning_amber, color: AppColors.warning),
                title: Text(a['message'] ?? ''),
                subtitle: Text('${a['type']} · ${a['severity']}'),
              ),
          ],
        ),
      ),
    );
  }
}
''')

print('farmer extras done')
