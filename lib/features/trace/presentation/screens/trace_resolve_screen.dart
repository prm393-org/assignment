import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/trace/domain/entities/trace_info.dart';
import 'package:chuoi_xanh_viet/features/trace/presentation/providers/trace_providers.dart';

class TraceDetailScreen extends ConsumerStatefulWidget {
  const TraceDetailScreen({super.key, required this.seasonId});

  final String seasonId;

  @override
  ConsumerState<TraceDetailScreen> createState() => _TraceDetailScreenState();
}

class _TraceDetailScreenState extends ConsumerState<TraceDetailScreen> {
  TraceSeasonDetail? _detail;
  TraceVerifyResult? _verify;
  bool _loading = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(traceRepositoryProvider)
          .getSeasonDetail(widget.seasonId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is Failure ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyChain() async {
    setState(() {
      _verifying = true;
      _verify = null;
    });
    try {
      final result = await ref
          .read(traceRepositoryProvider)
          .verifySeason(widget.seasonId);
      if (!mounted) return;
      setState(() => _verify = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is Failure ? e.message : 'Không xác minh được'),
        ),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _openMap(TraceSeasonDetail d) async {
    final Uri uri;
    if (d.hasGeo) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${d.latitude},${d.longitude}',
      );
    } else {
      final q = d.mapQuery;
      if (q == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có vị trí trang trại')),
        );
        return;
      }
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truy xuất nguồn gốc'),
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _detail == null
                  ? const EmptyState(message: 'Không có dữ liệu truy xuất')
                  : ListView(
                      padding: AppSpacing.screen,
                      children: [
                        Text(
                          _detail!.cropName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Mùa vụ: ${_detail!.seasonCode}'),
                        Text('Nông trại: ${_detail!.farmName}'),
                        Text('Chủ hộ: ${_detail!.ownerName ?? '—'}'),
                        Text(
                          'Địa phương: ${[
                            if (_detail!.district != null) _detail!.district,
                            if (_detail!.province != null) _detail!.province,
                          ].whereType<String>().join(', ')}',
                        ),
                        if (_detail!.status != null)
                          Text('Trạng thái: ${_detail!.status}'),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: () => _openMap(_detail!),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Xem bản đồ trang trại'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _verifying ? null : _verifyChain,
                          icon: _verifying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified_outlined),
                          label: Text(
                            _verifying
                                ? 'Đang xác minh...'
                                : 'Xác minh trên blockchain',
                          ),
                        ),
                        if (_verify != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _verify!.match
                                  ? AppColors.mint
                                  : AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _verify!.match
                                    ? AppColors.mintDeep
                                    : AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _verify!.match
                                      ? 'Dữ liệu khớp với chuỗi'
                                      : 'Không khớp hoặc chưa neo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _verify!.match
                                        ? AppColors.forest
                                        : AppColors.error,
                                  ),
                                ),
                                if (_verify!.anchor?.txHash != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tx: ${_verify!.anchor!.txHash}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (_detail!.anchors.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Neo dữ liệu',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (final a in _detail!.anchors.take(5))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.link,
                                color: AppColors.forest,
                              ),
                              title: Text(
                                a.checkpointType ??
                                    'Checkpoint ${a.checkpointNo ?? ''}',
                              ),
                              subtitle: Text(
                                [
                                  if (a.status != null) a.status!,
                                  if (a.anchoredAt != null)
                                    Formatters.dateTime(a.anchoredAt),
                                  if (a.txHash != null)
                                    'Tx: ${a.txHash!.length > 18 ? '${a.txHash!.substring(0, 18)}…' : a.txHash}',
                                ].join(' · '),
                              ),
                              onTap: a.txUrl == null
                                  ? null
                                  : () => launchUrl(
                                        Uri.parse(a.txUrl!),
                                        mode: LaunchMode.externalApplication,
                                      ),
                            ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Nhật ký canh tác',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_detail!.diaries.isEmpty)
                          const Text('Chưa có nhật ký'),
                        for (final d in _detail!.diaries)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              diaryEventLabels[d['eventType']] ??
                                  d['eventType'] ??
                                  '',
                            ),
                            subtitle: Text(d['description'] ?? ''),
                            trailing: Text(d['eventDate'] ?? ''),
                          ),
                      ],
                    ),
    );
  }
}

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
    });
    try {
      final unit = await ref
          .read(traceRepositoryProvider)
          .resolveByCode(_code.text.trim());
      if (!mounted) return;
      context.push('/trace/season/${unit.seasonId}');
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
        ],
      ),
    );
  }
}
