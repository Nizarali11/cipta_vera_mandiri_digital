import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onLogout;
  const HomeHeader({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/app/assets/images/cvm.png',
                  height: 38,
                ),
                const SizedBox(width: 5),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 9, 77, 186),
                    ),
                    children: [
                      const TextSpan(text: 'CIPTA '),
                      TextSpan(
                        text: 'VERA',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Notifikasi dengan badge merah
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_none,
                          color: Colors.blue[900], size: 26),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 0),
                IconButton(
                  icon: Icon(Icons.logout,
                      color: Colors.blue[900], size: 26),
                  onPressed: onLogout,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}