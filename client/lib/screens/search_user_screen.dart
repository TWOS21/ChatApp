import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/friend_provider.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _searchCtrl = TextEditingController();
  List<UserModel> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() => _searching = true);
    final fp = context.read<FriendProvider>();
    _results = await fp.searchUsers(q);
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加好友')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索用户名或昵称',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_results.isEmpty && _searchCtrl.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('未找到相关用户'),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return _UserTile(user: user);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTile extends StatefulWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  String _status = 'checking';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await context.read<FriendProvider>().checkStatus(widget.user.id);
    if (mounted) setState(() => _status = status);
  }

  Future<void> _sendRequest() async {
    final fp = context.read<FriendProvider>();
    final ok = await fp.sendRequest(widget.user.id);
    if (mounted) {
      if (ok) {
        setState(() => _status = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('好友请求已发送')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，可能已发送过请求')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text((widget.user.nickname ?? widget.user.username)[0].toUpperCase()),
      ),
      title: Text(widget.user.nickname ?? widget.user.username),
      subtitle: Text('@${widget.user.username}'),
      trailing: _buildAction(),
    );
  }

  Widget _buildAction() {
    switch (_status) {
      case 'accepted':
        return TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  userId: widget.user.id,
                  userName: widget.user.nickname ?? widget.user.username,
                ),
              ),
            );
          },
          child: const Text('发消息'),
        );
      case 'pending':
        return const Text('已请求', style: TextStyle(color: Colors.grey));
      case 'checking':
        return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
      default:
        return ElevatedButton(
          onPressed: _sendRequest,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('加好友'),
        );
    }
  }
}
