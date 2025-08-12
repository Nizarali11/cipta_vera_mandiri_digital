import 'package:cipta_vera_mandiri_digital/app/modules/home/views/home_view.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';


import 'chat_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = const [
    HomeView(),
    ChatPage(),
    CalendarPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}