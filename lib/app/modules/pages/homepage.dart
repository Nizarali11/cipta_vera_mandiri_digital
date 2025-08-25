import 'package:cipta_vera_mandiri_digital/app/modules/home/views/home_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';


import 'chat_list_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomeView(
        onMenuSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        onLogout: () {
          setState(() {
            currentIndex = 0;
          });
        },
      ),
      const ChatListPage(),
      const CalendarPage(),
      const ProfilePage(),
      const SettingsPage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}