import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_feedback.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _controller = TextEditingController();
  final List<_AiMessage> _messages = const [
    _AiMessage(
      text:
          'Hi Amit, ask me to find documents, summarize a policy or remind you about expiry dates.',
      fromUser: false,
    ),
  ].toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.ai),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.blue.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VaultOne AI', style: AppTextStyles.heading),
                        Text(
                          'Smart helper for your digital locker',
                          style: AppTextStyles.body.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemCount: _messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: message.fromUser ? AppColors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: message.fromUser
                            ? null
                            : Border.all(color: AppColors.fieldBorder),
                      ),
                      child: Text(
                        message.text,
                        style: AppTextStyles.body.copyWith(
                          color: message.fromUser
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask VaultOne AI',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_AiMessage(text: text, fromUser: true));
      _messages.add(
        const _AiMessage(
          text:
              'AI backend connect hote hi yahan smart response aayega. UI flow ready hai.',
          fromUser: false,
        ),
      );
      _controller.clear();
    });
    AppFeedback.showSnackBar(context, message: 'AI message sent');
  }
}

class _AiMessage {
  const _AiMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}
