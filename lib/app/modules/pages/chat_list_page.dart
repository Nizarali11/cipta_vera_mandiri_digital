import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/chat_page.dart';


class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0; // 0: semua, 1: belum dibaca, 2: favorit, 3: grup

  final List<_ChatItem> _all = [
    _ChatItem(
      name: 'Ica',
      subtitle: 'disini blm lgii',
      time: '2.43 PM',
      unread: 1,
      isFavorite: true,
      isGroup: false,
      avatar: const AssetImage('lib/app/assets/images/cvm.png'),
    ),
    _ChatItem(
      name: 'Banjarmasin Growtopia',
      subtitle: '~Call: Nama world cefsm',
      time: '2.24 PM',
      unread: 89,
      isFavorite: false,
      isGroup: true,
      avatar: const AssetImage('lib/app/assets/images/cvm.png'),
    ),
    _ChatItem(
      name: 'Rsyd',
      subtitle: 'okee²',
      time: '2.09 PM',
      unread: 1,
      isFavorite: false,
      isGroup: false,
      avatar: const AssetImage('lib/app/assets/images/cvm.png'),
    ),
  ];

  List<_ChatItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final base = _all.where((c) {
      final hit = c.name.toLowerCase().contains(q) ||
          c.subtitle.toLowerCase().contains(q);
      return hit;
    });

    switch (_tabIndex) {
      case 1:
        return base.where((c) => c.unread > 0).toList();
      case 2:
        return base.where((c) => c.isFavorite).toList();
      case 3:
        return base.where((c) => c.isGroup).toList();
      default:
        return base.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 63,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 28,
            height: 1,
          ),
        ),
        actions: [
          _glassIconButton(
            icon: Icons.photo_camera_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _glassIconButton(
            icon: Icons.add,
            onTap: () {},
          ),
          const SizedBox(width: 12),
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.25),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _searchBar(),
              const SizedBox(height: 10),
              _filterChips(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemBuilder: (context, i) {
                    final item = _filtered[i];
                    return _chatTile(item);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: _filtered.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tanya AI atau cari',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _glassChip(
            label: 'Semua',
            selected: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          const SizedBox(width: 8),
          _glassChip(
            label: 'Belum Dibaca ${_all.where((e) => e.unread > 0).length}',
            selected: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
          const SizedBox(width: 8),
          _glassChip(
            label: 'Favorit ${_all.where((e) => e.isFavorite).length}',
            selected: _tabIndex == 2,
            onTap: () => setState(() => _tabIndex = 2),
          ),
          const SizedBox(width: 8),
          _glassChip(
            label: 'Grup',
            selected: _tabIndex == 3,
            onTap: () => setState(() => _tabIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _chatTile(_ChatItem c) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatPage()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: c.avatar,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(c.time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    if (c.unread > 0)
                      _badge(c.unread)
                    else
                      const SizedBox(height: 20),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0xFF25D366), // WA green
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Text(
        '$n',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _ChatItem {
  final String name;
  final String subtitle;
  final String time;
  final int unread;
  final bool isFavorite;
  final bool isGroup;
  final ImageProvider avatar;

  _ChatItem({
    required this.name,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.isFavorite,
    required this.isGroup,
    required this.avatar,
  });
}

Widget _glassChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (selected ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.16)),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ),
  );
}

Widget _glassIconButton({required IconData icon, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    ),
  );
}
