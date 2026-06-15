import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WsService _ws = WsService();

  List<MessageModel> _messages = [];
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = false;
  StreamSubscription? _wsSubscription;

  List<MessageModel> get messages => _messages;
  List<Map<String, dynamic>> get conversations => _conversations;
  bool get loading => _loading;
  WsService get ws => _ws;

  /// 初始化 WebSocket
  void initWs() {
    _ws.connect();
    _wsSubscription = _ws.messageStream.listen((msg) {
      // 收到新消息，如果当前在看对应聊天就追加
      if (_currentChatUserId != null &&
          (msg.senderId == _currentChatUserId ||
              msg.receiverId == _currentChatUserId)) {
        _messages.add(msg);
        notifyListeners();
      }
      // 刷新会话列表
      loadConversations();
    });
  }

  int? _currentChatUserId;
  void setCurrentChat(int userId) {
    _currentChatUserId = userId;
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  /// 加载会话列表
  Future<void> loadConversations() async {
    try {
      final raw = await _api.getConversations();
      _conversations = raw.cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (e) {
      print('加载会话失败: $e');
    }
  }

  /// 加载聊天历史
  Future<void> loadMessages(int userId) async {
    _loading = true;
    _currentChatUserId = userId;
    notifyListeners();

    try {
      _messages = await _api.getMessageHistory(userId);
    } catch (e) {
      print('加载消息失败: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// 通过 REST API 发送消息
  Future<void> sendMessage(int receiverId, String content,
      {String type = 'text'}) async {
    try {
      final msg = await _api.sendMessage(receiverId, content, type);
      _messages.add(msg);
      notifyListeners();
    } catch (e) {
      print('发送消息失败: $e');
    }
  }

  /// 通过 WebSocket 发送消息
  void sendMessageWs(int receiverId, String content,
      {String type = 'text'}) {
    _ws.sendMessage(receiverId, content, type: type);
  }

  /// 上传文件并发送
  Future<void> sendFile(int receiverId, String filePath,
      {String type = 'image'}) async {
    try {
      final url = await _api.uploadFile(filePath);
      sendMessageWs(receiverId, url, type: type);
    } catch (e) {
      print('上传文件失败: $e');
    }
  }
}
