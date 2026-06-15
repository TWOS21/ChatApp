import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('ChatApp'), centerTitle: true),
      body: chat.conversations.isEmpty
          ? const Center(child: Text('暂无消息'))
          : RefreshIndicator(
              onRefresh: chat.loadConversations,
              child: ListView.separated(
                itemCount: chat.conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final conv = chat.conversations[i];
                  final user = conv['user'];
                  final lastMsg = conv['last_message'];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((user['nickname'] ?? user['username'])[0]
                          .toUpperCase()),
                    ),
                    title: Text(
                      user['nickname'] ?? user['username'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      lastMsg?['content'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: lastMsg?['created_at'] != null
                        ? Text(
                            _formatTime(lastMsg['created_at']),
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            userId: user['id'],
                            userName: user['nickname'] ?? user['username'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
