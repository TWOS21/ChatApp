import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../models/message.dart';

typedef MessageCallback = void Function(MessageModel message);

class WsService {
  WebSocketChannel? _channel;
  bool _connected = false;
  Timer? _heartbeatTimer;

  /// 连接 WebSocket
  Future<void> connect() async {
    if (_connected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsUrl}/ws?token=$token'),
      );
      _connected = true;
      _startHeartbeat();
    } catch (e) {
      print('WS 连接失败: $e');
    }
  }

  /// 断开连接
  void disconnect() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _connected = false;
  }

  /// 监听消息
  Stream<MessageModel> get messageStream {
    return _channel!.stream.map((data) {
      final json = jsonDecode(data as String);
      return MessageModel.fromJson(json);
    });
  }

  /// 发送消息（通过 WebSocket）
  void sendMessage(int receiverId, String content, {String type = 'text'}) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'receiver_id': receiverId,
      'content': content,
      'type': type,
    }));
  }

  /// 心跳保活
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_connected && _channel != null) {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  bool get isConnected => _connected;
}
