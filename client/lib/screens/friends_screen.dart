import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/friend_provider.dart';
import 'chat_screen.dart';
import 'search_user_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final fp = context.read<FriendProvider>();
    await Future.wait([fp.loadFriends(), fp.loadFriendRequests()]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通讯录'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: '添加好友',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchUserScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: '好友'),
            Tab(text: '请求'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendListTab(),
          _FriendRequestsTab(),
        ],
      ),
    );
  }
}

class _FriendListTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FriendProvider>();

    if (fp.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fp.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('还没有好友', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('添加好友'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchUserScreen()),
                );
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<FriendProvider>().loadFriends(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: fp.friends.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final friend = fp.friends[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(
                (friend.nickname ?? friend.username)[0].toUpperCase(),
              ),
            ),
            title: Text(friend.nickname ?? friend.username),
            subtitle: friend.bio != null ? Text(friend.bio!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    userId: friend.id,
                    userName: friend.nickname ?? friend.username,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FriendProvider>();

    if (fp.friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_disabled, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无好友请求', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<FriendProvider>().loadFriendRequests(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: fp.friendRequests.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final req = fp.friendRequests[index];
          final user = UserModel.fromJson(req['user'] as Map<String, dynamic>);
          final requestId = req['id'] as int;

          return ListTile(
            leading: CircleAvatar(
              child: Text((user.nickname ?? user.username)[0].toUpperCase()),
            ),
            title: Text(user.nickname ?? user.username),
            subtitle: Text('请求加你为好友'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () {
                    context.read<FriendProvider>().acceptRequest(requestId);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    context.read<FriendProvider>().rejectRequest(requestId);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
