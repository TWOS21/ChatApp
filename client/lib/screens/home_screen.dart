import 'package:flutter/material.dart';

import 'chat_list_screen.dart';
import 'friends_screen.dart';
import 'moments_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = [
    const ChatListScreen(),
    const FriendsScreen(),
    const MomentsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: '消息'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: '通讯录'),
          NavigationDestination(icon: Icon(Icons.explore), label: '动态'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
