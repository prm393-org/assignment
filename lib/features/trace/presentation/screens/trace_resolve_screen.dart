import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/trace/domain/entities/trace_info.dart';
import 'package:chuoi_xanh_viet/features/trace/presentation/providers/trace_providers.dart';

class TraceResolveScreen extends ConsumerStatefulWidget {
  const TraceResolveScreen({
    super.key,
    this.initialCode,
    this.scanPath = '/consumer/trace/scan',
  });
  final String? initialCode;
  final String scanPath;

  @override
  ConsumerState<TraceResolveScreen> createState() => _TraceResolveScreenState();
}

class _TraceResolveScreenState extends ConsumerState<TraceResolveScreen> {
  late final TextEditingController _code;
  bool _loading = false;
  String? _error;
  TraceSaleUnit? _unit;
  TraceSeasonDetail? _detail;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
      _unit = null;
      _detail = null;
    });
    try {
      final repo = ref.read(traceRepositoryProvider);
      final unit = await repo.resolveByCode(_code.text.trim());
      final detail = await repo.getSeasonDetail(unit.seasonId);
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _detail = detail;
      });
    } catch (e) {
      setState(() => _error = e is Failure ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truy xuất nguồn gốc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push(widget.scanPath),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          TextField(
            controller: _code,
            decoration: const InputDecoration(
              labelText: 'Mã truy xuất / short code',
              prefixIcon: Icon(Icons.qr_code),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _loading ? null : _resolve,
            child: Text(_loading ? 'Đang tra cứu...' : 'Tra cứu'),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          if (_unit != null && _detail != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(_detail!.cropName, style: Theme.of(context).textTheme.headlineMedium),
            Text('Mùa vụ: ${_detail!.seasonCode}'),
            Text('Nông trại: ${_detail!.farmName}'),
            Text('Chủ hộ: ${_detail!.ownerName ?? '—'}'),
            Text('Địa phương: ${_detail!.province ?? '—'}'),
            Text('Đơn vị bán: ${_unit!.code}'),
            const SizedBox(height: AppSpacing.xl),
            Text('Nhật ký', style: Theme.of(context).textTheme.titleLarge),
            for (final d in _detail!.diaries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(diaryEventLabels[d['eventType']] ?? d['eventType'] ?? ''),
                subtitle: Text(d['description'] ?? ''),
                trailing: Text(d['eventDate'] ?? ''),
              ),
          ],
        ],
      ),
    );
  }
}
