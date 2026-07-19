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
