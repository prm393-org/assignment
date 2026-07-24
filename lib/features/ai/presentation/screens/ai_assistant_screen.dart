import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
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
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _input.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    final message = e is Failure ? e.message : 'Không thể trả lời lúc này';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendChat() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;
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
      if (!mounted) return;
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _diagnose() async {
    if (_loading) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final reply =
          await ref.read(chatbotRepositoryProvider).diagnose(imagePath: file.path);
      if (!mounted) return;
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDiagnose = _tabs.index == 2;
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
            child: _messages.isEmpty && !_loading
                ? EmptyState(
                    message: isDiagnose
                        ? 'Chọn ảnh cây trồng để chẩn đoán sâu bệnh'
                        : 'Xin chào! Hãy hỏi về canh tác, thị trường hoặc nông sản',
                    icon: Icons.smart_toy_outlined,
                  )
                : ListView.builder(
                    padding: AppSpacing.screen,
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_loading && i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isUser ? AppColors.forest : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: isUser
                                ? null
                                : Border.all(color: AppColors.hairline),
                          ),
                          child: Text(
                            m['content'] ?? '',
                            style: TextStyle(
                              color: isUser ? AppColors.onPrimary : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (isDiagnose)
            SafeArea(
              child: Padding(
                padding: AppSpacing.screen,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _diagnose,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(_loading ? 'Đang chẩn đoán...' : 'Chọn ảnh cây trồng'),
                ),
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
                        enabled: !_loading,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendChat(),
                        decoration: const InputDecoration(
                          hintText: 'Nhập câu hỏi...',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: _loading ? null : _sendChat,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
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
