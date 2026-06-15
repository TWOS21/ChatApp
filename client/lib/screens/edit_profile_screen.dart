import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _api = ApiService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nicknameCtrl.text = user?.nickname ?? '';
    _bioCtrl.text = user?.bio ?? '';
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    try {
      final url = await _api.uploadFile(picked.path);
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传图片失败')),
        );
      }
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      nickname: _nicknameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    if (mounted) {
      _saving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '保存成功' : '保存失败')),
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('编辑资料'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 头像
          Center(
            child: GestureDetector(
              onTap: () async {
                final url = await _pickImage();
                if (url != null && mounted) {
                  final ok = await auth.updateProfile(avatarUrl: url);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('头像已更新')),
                    );
                  }
                }
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(_api.imageUrl(user!.avatarUrl!))
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            (user?.nickname ?? user?.username ?? '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(fontSize: 40),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('点击更换头像',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(height: 32),

          // 昵称
          TextField(
            controller: _nicknameCtrl,
            decoration: const InputDecoration(
              labelText: '昵称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),

          // 签名
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: '个性签名',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.format_quote),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
