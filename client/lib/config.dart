/// 后端 API 地址
// 开发环境：用电脑 IP，手机连同一局域网就能访问
// 生产环境：改成你的服务器域名
class AppConfig {
  // 如果手机模拟器和后端在同一台电脑，用 10.0.2.2 (Android 模拟器)
  // 如果真机测试，改成你电脑的局域网 IP，比如 192.168.x.x
  static const String baseUrl = 'http://10.200.65.152:8000';

  static const String wsUrl = 'ws://10.200.65.152:8000';

  // 真机测试时改为电脑 IP：
  // static const String baseUrl = 'http://192.168.1.100:8000';
  // static const String wsUrl = 'ws://192.168.1.100:8000';
}
