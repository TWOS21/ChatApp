import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/user.dart';
import '../models/message.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // 请求拦截器：自动带 token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ========== 认证 ==========

  Future<Map<String, dynamic>> register(
      String username, String password) async {
    final res = await _dio.post('/api/auth/register', data: {
      'username': username,
      'password': password,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    return res.data;
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/api/auth/me');
    return UserModel.fromJson(res.data);
  }

  // ========== 消息 ==========

  Future<MessageModel> sendMessage(
      int receiverId, String content, String msgType) async {
    final res = await _dio.post('/api/messages/send', data: {
      'receiver_id': receiverId,
      'content': content,
      'msg_type': msgType,
    });
    return MessageModel.fromJson(res.data);
  }

  Future<List<MessageModel>> getMessageHistory(int userId) async {
    final res = await _dio.get('/api/messages/history/$userId');
    return (res.data as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<List<dynamic>> getConversations() async {
    final res = await _dio.get('/api/messages/conversations');
    return res.data;
  }

  // ========== 文件上传 ==========

  Future<String> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/api/upload', data: formData);
    return res.data['url']; // 返回 /static/xxx/xxx.png 格式
  }

  // ========== 动态 ==========

  Future<Map<String, dynamic>> createPost(
      String? content, List<String>? images) async {
    final res = await _dio.post('/api/moments', data: {
      'content': content,
      'images': images,
    });
    return res.data;
  }

  Future<List<dynamic>> getMoments({int page = 1}) async {
    final res = await _dio.get('/api/moments', queryParameters: {
      'page': page,
    });
    return res.data;
  }

  /// 生成完整的图片 URL
  String imageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AppConfig.baseUrl}$path';
  }

  // ========== 个人资料 ==========

  /// 更新个人资料
  Future<UserModel> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    final res = await _dio.put('/api/auth/profile', data: {
      if (nickname != null) 'nickname': nickname,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return UserModel.fromJson(res.data);
  }

  // ========== 好友 ==========

  /// 搜索用户
  Future<List<dynamic>> searchUsers(String query) async {
    final res = await _dio.get('/api/friends/search', queryParameters: {'q': query});
    return res.data;
  }

  /// 发送好友请求
  Future<void> sendFriendRequest(int friendId) async {
    await _dio.post('/api/friends/request', data: {'friend_id': friendId});
  }

  /// 同意/拒绝好友请求
  Future<void> respondFriendRequest(int requestId, bool accept) async {
    await _dio.post('/api/friends/respond', data: {
      'request_id': requestId,
      'accept': accept,
    });
  }

  /// 好友列表
  Future<List<dynamic>> getFriends() async {
    final res = await _dio.get('/api/friends/');
    return res.data;
  }

  /// 收到的好友请求列表
  Future<List<dynamic>> getFriendRequests() async {
    final res = await _dio.get('/api/friends/requests');
    return res.data;
  }

  /// 查看好友状态
  Future<Map<String, dynamic>> checkFriendStatus(int userId) async {
    final res = await _dio.get('/api/friends/status/$userId');
    return res.data;
  }
}
