import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class MomentsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _posts = [];
  bool _loading = false;

  List<Map<String, dynamic>> get posts => _posts;
  bool get loading => _loading;

  /// 加载动态
  Future<void> loadMoments() async {
    _loading = true;
    notifyListeners();

    try {
      final raw = await _api.getMoments();
      _posts = raw.cast<Map<String, dynamic>>();
    } catch (e) {
      print('加载动态失败: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// 发布动态
  Future<bool> createPost(String? content, List<String>? imagePaths) async {
    try {
      // 先上传图片
      List<String>? imageUrls;
      if (imagePaths != null && imagePaths.isNotEmpty) {
        imageUrls = [];
        for (final path in imagePaths) {
          final url = await _api.uploadFile(path);
          imageUrls.add(url);
        }
      }

      await _api.createPost(content, imageUrls);
      await loadMoments(); // 刷新
      return true;
    } catch (e) {
      print('发布动态失败: $e');
      return false;
    }
  }

  /// 选择图片
  Future<List<String>?> pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return null;
    return files.map((f) => f.path).toList();
  }
}
