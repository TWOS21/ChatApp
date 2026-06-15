import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config.dart';
import '../providers/moments_provider.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MomentsProvider>().loadMoments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moments = context.watch<MomentsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('动态'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: moments.loading
          ? const Center(child: CircularProgressIndicator())
          : moments.posts.isEmpty
              ? const Center(child: Text('暂无动态'))
              : RefreshIndicator(
                  onRefresh: moments.loadMoments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: moments.posts.length,
                    itemBuilder: (context, i) {
                      final post = moments.posts[i];
                      final user = post['user'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 用户信息
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Text(
                                      (user['nickname'] ?? user['username'])[0]
                                          .toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['nickname'] ?? user['username'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        _formatTime(post['created_at']),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // 文字内容
                              if (post['content'] != null &&
                                  post['content'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(post['content']),
                                ),
                              // 图片
                              if (post['images'] != null &&
                                  (post['images'] as List).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _buildImages(post['images'] as List),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildImages(List images) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: images.map<Widget>((url) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: '${AppConfig.baseUrl}$url',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    final moments = context.read<MomentsProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('发布动态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                decoration: const InputDecoration(
                  hintText: '说点什么...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await moments.createPost(
                      textCtrl.text.trim().isEmpty
                          ? null
                          : textCtrl.text.trim(),
                      null,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('发布成功')),
                      );
                    }
                  },
                  child: const Text('发布'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
