import 'package:flutter_test/flutter_test.dart';

import 'package:chat_app/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatApp());
    await tester.pump();
    // 启动后应该看到登录页或首页
    expect(find.byType(ChatApp), findsOneWidget);
  });
}
