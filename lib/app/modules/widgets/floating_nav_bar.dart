import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNav {
  static const int home = 0;
  static const int chat = 1;
  static const int calendar = 2;
  static const int profile = 3;
  static const int settings = 4;

  static IconData iconFor(int index) {
    switch (index) {
      case home:
        return Icons.home;
      case chat:
        return Icons.chat;
      case calendar:
        return Icons.calendar_today;
      case profile:
        return Icons.person;
      case settings:
        return Icons.settings;
      default:
        return Icons.home;
    }
  }

  static String labelFor(int index) {
    switch (index) {
      case home:
        return 'Home';
      case chat:
        return 'Chat';
      case calendar:
        return 'Calendar';
      case profile:
        return 'Profile';
      case settings:
        return 'Pengaturan';
      default:
        return 'Home';
    }
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent.withOpacity(0.0),
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            //boxShadow: [
             // BoxShadow(
               // color: Colors.black.withOpacity(0.05),
               // blurRadius: 10,
               // offset: Offset(0, 0),
              //),
            //],
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final icon = BottomNav.iconFor(index);
              final label = BottomNav.labelFor(index);
              final selected = index == currentIndex;
              final color = selected ? const Color.fromARGB(255, 51, 144, 215) : const Color.fromARGB(255, 108, 108, 108);

              return InkWell(
                onTap: () => onTap?.call(index),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Transform.translate(
                    offset: const Offset(0, -6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: color,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}