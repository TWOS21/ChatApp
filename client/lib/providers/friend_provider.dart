import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class FriendProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<UserModel> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  bool _loading = false;

  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  bool get loading => _loading;

  /// 加载好友列表
  Future<void> loadFriends() async {
    _loading = true;
    notifyListeners();

    try {
      final raw = await _api.getFriends();
      _friends = raw.map((e) {
        final user = e['user'] as Map<String, dynamic>;
        return UserModel.fromJson(user);
      }).toList();
    } catch (e) {
      print('加载好友列表失败: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// 加载好友请求
  Future<void> loadFriendRequests() async {
    try {
      final raw = await _api.getFriendRequests();
      _friendRequests = raw.cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (e) {
      print('加载好友请求失败: $e');
    }
  }

  /// 搜索用户
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final raw = await _api.searchUsers(query);
      return raw.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('搜索用户失败: $e');
      return [];
    }
  }

  /// 发送好友请求
  Future<bool> sendRequest(int friendId) async {
    try {
      await _api.sendFriendRequest(friendId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 同意好友请求
  Future<void> acceptRequest(int requestId) async {
    try {
      await _api.respondFriendRequest(requestId, true);
      await loadFriendRequests();
      await loadFriends();
    } catch (e) {
      print('同意好友请求失败: $e');
    }
  }

  /// 拒绝好友请求
  Future<void> rejectRequest(int requestId) async {
    try {
      await _api.respondFriendRequest(requestId, false);
      await loadFriendRequests();
    } catch (e) {
      print('拒绝好友请求失败: $e');
    }
  }

  /// 检查好友状态
  Future<String> checkStatus(int userId) async {
    try {
      final data = await _api.checkFriendStatus(userId);
      return data['status'] as String;
    } catch (e) {
      return 'none';
    }
  }
}
