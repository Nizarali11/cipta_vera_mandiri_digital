import 'dart:ui';

import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

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
              IconData icon;
              String label;
              switch (index) {
                case 0:
                  icon = Icons.home;
                  label = 'Home';
                  break;
                case 1:
                  icon = Icons.chat;
                  label = 'Chat';
                  break;
                case 2:
                  icon = Icons.calendar_today;
                  label = 'Calendar';
                  break;
                case 3:
                  icon = Icons.person;
                  label = 'Profile';
                  break;
                case 4:
                  icon = Icons.settings;
                  label = 'Pengaturan';
                  break;
                default:
                  icon = Icons.home;
                  label = 'Home';
              }
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