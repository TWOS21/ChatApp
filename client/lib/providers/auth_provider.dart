import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  bool _loading = false;
  String? _error;
  String? _token;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && _token != null;
  String? get token => _token;

  /// 尝试自动登录（从本地取 token）
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    if (savedToken == null) return false;

    _token = savedToken;
    try {
      _user = await _api.getMe();
      notifyListeners();
      return true;
    } catch (e) {
      _token = null;
      await prefs.remove('token');
      return false;
    }
  }

  /// 注册
  Future<bool> register(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(username, password);
      _token = data['access_token'];
      _user = UserModel(
        id: data['user_id'],
        username: data['username'],
      );
      await _saveToken(_token!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      _token = data['access_token'];
      _user = UserModel(
        id: data['user_id'],
        username: data['username'],
      );
      await _saveToken(_token!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  /// 更新个人资料
  Future<bool> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      _user = await _api.updateProfile(
        nickname: nickname,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      notifyListeners();
      return true;
    } catch (e) {
      print('更新资料失败: $e');
      return false;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      try {
        final dioErr = e as dynamic;
        if (dioErr.response != null) {
          final statusCode = dioErr.response?.statusCode;
          final data = dioErr.response?.data;
          if (data is Map && data.containsKey('detail')) {
            return '${data['detail']} (HTTP $statusCode)';
          }
          if (data is String) {
            return '服务器返回: ${data.substring(0, data.length.clamp(0, 100))} (HTTP $statusCode)';
          }
          if (statusCode != null) {
            return 'HTTP $statusCode: 服务器返回异常';
          }
        }
      } catch (_) {}
      final str = e.toString();
      if (str.contains('timeout')) return '连接超时，请检查网络';
      if (str.contains('Connection refused')) return '服务器未启动';
      if (str.contains('SocketException')) return '网络异常';
      return '请求失败\n(${str.substring(0, str.length.clamp(0, 200))})';
    }
    return '未知错误';
  }
}
