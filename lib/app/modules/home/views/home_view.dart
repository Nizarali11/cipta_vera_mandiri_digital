import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/home_header.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/menu_grid.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/news_section.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/profile_card.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/homeview/upcoming_events_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';


class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 24),
                  const ProfileCard(),
                  const SizedBox(height: 28),
                  const MenuGrid(),
                  const SizedBox(height: 32),
                  const NewsSection(),
                  const SizedBox(height: 32),
                  UpcomingEventsSection(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
