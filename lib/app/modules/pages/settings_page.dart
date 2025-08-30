import 'dart:io';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/contact_list_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/widgets/floating_nav_bar.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/pages/profile_page.dart' as profile;
import 'package:cipta_vera_mandiri_digital/app/modules/pages/chat_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  final void Function(int)? onMenuSelected;
  final int profileTabIndex;

  const SettingsPage({
    super.key,
    this.onMenuSelected,
    this.profileTabIndex = 3, // sesuaikan index profil jika berbeda
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _nama = 'Nizar ali';
  String _tentang = 'Sibuk';
  File? _fotoProfil;

  // Per-UID helpers
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String _k(String base) => _uid == null ? base : '${base}_${_uid}';

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_k('nama'));
    final savedAbout = prefs.getString(_k('tentang'));
    final savedPath = prefs.getString(_k('fotoProfil'));

    final dir = await getApplicationDocumentsDirectory();
    final fixedPath = '${dir.path}/profile_${_uid ?? 'local'}.jpg';

    File? resolved;
    if (savedPath != null && File(savedPath).existsSync()) {
      resolved = File(savedPath);
    } else if (File(fixedPath).existsSync()) {
      resolved = File(fixedPath);
      await prefs.setString(_k('fotoProfil'), fixedPath); // self-heal
    } else {
      resolved = null;
      if (savedPath != null) {
        await prefs.remove(_k('fotoProfil'));
      }
    }

    setState(() {
      _nama = savedName ?? _nama;
      _tentang = savedAbout ?? _tentang;
      _fotoProfil = resolved;
    });
  }

  void _onProfileChanged() async {
    if (!mounted) return;
    await _loadProfile();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    profile.profileChanged.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    profile.profileChanged.removeListener(_onProfileChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
                    const SizedBox(height: 18),
                    // Profile Section (Firestore realtime + fallback local)
                    if (user == null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 252, 252, 252).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey,
                              backgroundImage: _fotoProfil != null ? FileImage(_fotoProfil!) : null,
                              child: _fotoProfil == null ? const Icon(Icons.person, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nama,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 51, 51, 51),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _tentang,
                                  style: const TextStyle(
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
                    ] else ...[
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data();
                          final nameFs = (data?['name'] ?? data?['nama'] ?? '').toString();
                          final aboutFs = (data?['about'] ?? data?['tentang'] ?? '').toString();
                          final fotoUrl = (data?['fotoProfil'] ?? '').toString();

                          final displayName = nameFs.isNotEmpty ? nameFs : _nama;
                          final displayAbout = aboutFs.isNotEmpty ? aboutFs : _tentang;

                          ImageProvider? avatar;
                          if (_fotoProfil != null) {
                            avatar = FileImage(_fotoProfil!);
                          } else if (fotoUrl.isNotEmpty) {
                            avatar = NetworkImage(fotoUrl);
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 252, 252, 252).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey,
                                  backgroundImage: avatar,
                                  child: avatar == null ? const Icon(Icons.person, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 51, 51, 51),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      displayAbout,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 51, 51, 51),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.qr_code, color: Color.fromARGB(255, 85, 83, 83), size: 30),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 15),
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
                            icon: Icons.contacts,
                            text: 'Kontak',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ContactListPage()),
                              );
                            },
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
                    const SizedBox(height: 15),
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
                            onTap: () async {
                              // Route via index ke tab Profil jika callback tersedia
                              if (widget.onMenuSelected != null) {
                                widget.onMenuSelected!(BottomNav.profile);
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                                return;
                              }
                              // Fallback lama: tetap dorong halaman Profile kalau belum ada callback
                              await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => const profile.ProfilePage()),
                              );
                              if (!mounted) return;
                              await _loadProfile();
                              if (!mounted) return;
                              setState(() {});
                            },
                            isFirst: true,
                          ),
                          _divider(),
                          _settingsTile(
                            icon: Icons.chat_bubble_outline,
                            text: 'Chat',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ChatListPage()),
                              );
                            },
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
                    const SizedBox(height: 15),
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

Widget _divider() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 1,
    color: Colors.white.withOpacity(0.13),
  );
}