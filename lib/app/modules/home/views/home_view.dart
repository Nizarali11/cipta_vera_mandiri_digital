import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/home_header.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/menu_grid.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/news_section.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/profile_card.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/upcoming_events_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';


class HomeView extends StatelessWidget {
  final void Function(int) onMenuSelected;
  final void Function() onLogout;

  const HomeView({
    super.key,
    required this.onMenuSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    Get.find<HomeController>();
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
            stops: [0.5, 2.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(
                    onLogout: () {
                      // Call the passed in onLogout to allow parent handling
                      onLogout();
                      // Navigate to the login page after logout
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                  const SizedBox(height: 0),
                  const ProfileCard(),
                  const SizedBox(height: 28),
                  MenuGrid(onMenuSelected: onMenuSelected),
                  const SizedBox(height: 20),
                  const NewsSection(),
                  const SizedBox(height: 20),
                  UpcomingEventsSection(
                    onMenuSelected: onMenuSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}