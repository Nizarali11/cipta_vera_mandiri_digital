import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              floating: true,
              snap: true,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Pengaturan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Good contrast on light bg
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Profile Section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 252, 252, 252).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Nizar ali',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 51, 51, 51),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sibuk',
                                style: TextStyle(
                                   color: Color.fromARGB(255, 51, 51, 51),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.qr_code, color: Color.fromARGB(255, 85, 83, 83), size: 30),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    // First menu group
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _settingsTile(
                            icon: Icons.face,
                            text: 'Avatar',
                            onTap: () {},
                            isFirst: true,
                          ),
                          _divider(),
                          _settingsTile(
                            icon: Icons.star,
                            text: 'Berbintang',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Second menu group
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _settingsTile(
                            icon: Icons.person_outline,
                            text: 'Profil',
                            onTap: () {},
                            isFirst: true,
                          ),
                          _divider(),
                          _settingsTile(
                            icon: Icons.lock_outline,
                            text: 'Privasi',
                            onTap: () {},
                          ),
                          _divider(),
                          _settingsTile(
                            icon: Icons.chat_bubble_outline,
                            text: 'Chat',
                            onTap: () {},
                          ),
                          _divider(),
                          _settingsTile(
                            icon: Icons.notifications_none,
                            text: 'Pemberitahuan',
                            onTap: () {},
                          ),
                          _divider(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 0),
                    const SizedBox(height: 26),
                    // Third menu group
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _settingsTile(
                            icon: Icons.language,
                            text: 'Website',
                            onTap: () {},
                            isFirst: true,
                          ),
                        
                          _divider(),
                          _settingsTile(
                            icon: Icons.admin_panel_settings,
                            text: 'Admin',
                            onTap: () {},
                          ),
                          _divider(),
                          _settingsTile(
                            icon: Icons.info_outline,
                            text: 'Log Out',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Helper for menu tiles with icon, text, trailing arrow, and rounded corners for first and last
Widget _settingsTile({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
  bool isFirst = false,
  bool isLast = false,
}) {
  const Color iconTextColor = Color.fromARGB(255, 51, 51, 51);
  return ListTile(
    leading: Icon(icon, color: iconTextColor),
    title: Text(
      text,
      style: const TextStyle(
        color: iconTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, color: iconTextColor, size: 18),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    shape: isFirst
        ? const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          )
        : isLast
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              )
            : null,
    dense: true,
    horizontalTitleGap: 10,
    minLeadingWidth: 0,
  );
}
// Custom divider for menu groups
Widget _divider() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 1,
    color: Colors.white.withOpacity(0.13),
  );
}