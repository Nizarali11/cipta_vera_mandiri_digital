import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/media_docs_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/starred_messages_page.dart';

class UserProfilePage extends StatelessWidget {
  final String peerUid;

  const UserProfilePage({Key? key, required this.peerUid}) : super(key: key);

  // Helpers: cari chatId antara current user dan peer
  Future<String?> _resolveChatId() async {
    final my = FirebaseAuth.instance.currentUser?.uid;
    if (my == null || my.isEmpty) return null;

    // 1) Cari chat yang memang sudah ada berdasarkan anggota (members)
    try {
      final qs = await FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: my)
          .limit(50)
          .get();
      for (final d in qs.docs) {
        final data = d.data();
        final members = (data['members'] is List) ? List.from(data['members']) : <dynamic>[];
        final type = (data['type'] ?? 'dm').toString();
        if (type == 'dm' && members.contains(peerUid)) {
          return d.id; // ketemu chat eksisting antara my ↔ peer
        }
      }
    } catch (_) {
      // abaikan error, lanjut fallback
    }

    // 2) Fallback ke pola id deterministik a_b bila app kamu memang memakainya
    final a = my.compareTo(peerUid) <= 0 ? my : peerUid;
    final b = my.compareTo(peerUid) <= 0 ? peerUid : my;
    final id1 = '${a}_$b';
    final id2 = '${b}_$a';
    final chats = FirebaseFirestore.instance.collection('chats');
    try {
      final d1 = await chats.doc(id1).get();
      if (d1.exists) return id1;
      final d2 = await chats.doc(id2).get();
      if (d2.exists) return id2;
    } catch (_) {
      // abaikan dan teruskan fallback terakhir
    }

    // 3) Jika tetap tidak ada, kembalikan null agar UI menampilkan info kosong
    return null;
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  Widget _sectionHeader(String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          if (onTap != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                    ),
                    child: const Text('Lihat semua', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text('Profil'),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                ),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.white.withOpacity(0.15)),
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
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(peerUid).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              final data = snap.data?.data() ?? <String, dynamic>{};
              final name = (data['name'] ?? data['displayName'] ?? 'Pengguna').toString();
              final role = (data['role'] ?? '').toString();
              final pin  = (data['pin']  ?? data['chatPin'] ?? '').toString();
              final about = (data['about'] ?? data['tentang'] ?? '').toString();
              final avatarUrl = (data['avatarUrl'] ?? '').toString();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 56, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kartu info (glass)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _rowItem('Nama', name),
                              const SizedBox(height: 8),
                              if (role.isNotEmpty) _rowItem('Role', role),
                              if (role.isNotEmpty) const SizedBox(height: 8),
                              if (pin.isNotEmpty) _rowItem('PIN', pin),
                              if (pin.isNotEmpty) const SizedBox(height: 8),
                              if (about.isNotEmpty) _rowItem('Tentang', about),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Aksi cepat (opsional)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _glassButtonIcon(
                            icon: Icons.chat_bubble_outline,
                            label: 'Chat',
                            onPressed: () {
                              Navigator.pop(context); // kembali ke chat yg sudah terbuka
                            },
                          ),
                          const SizedBox(width: 12),
                          _glassButtonIcon(
                            icon: Icons.call_outlined,
                            label: 'Telepon',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur telepon coming soon')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    FutureBuilder<String?>(
                      future: _resolveChatId(),
                      builder: (context, chatSnap) {
                        final chatId = chatSnap.data;
                        return _sectionHeader('Media & Dokumen', onTap: (chatId == null)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MediaDocsPage(chatId: chatId),
                                  ),
                                );
                              });
                      },
                    ),
                    FutureBuilder<String?>(
                      future: _resolveChatId(),
                      builder: (context, chatSnap) {
                        final chatId = chatSnap.data;
                        if (chatId == null) return const SizedBox();
                        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId)
                              .collection('messages')
                              .orderBy('ts', descending: true)
                              .limit(150)
                              .snapshots(),
                          builder: (context, msgSnap) {
                            if (msgSnap.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: CircularProgressIndicator(color: Colors.white)),
                              );
                            }
                            final docs = msgSnap.data?.docs ?? const [];
                            final images = <String>[];
                            final files = <Map<String, dynamic>>[];
                            for (final d in docs) {
                              final m = d.data();
                              final type = (m['type'] ?? '').toString();
                              final img = (m['imageUrl'] ?? m['photoUrl'] ?? '').toString();
                              final fileUrl = (m['fileUrl'] ?? '').toString();
                              final fileName = (m['fileName'] ?? '').toString();
                              if (img.isNotEmpty || type == 'image') {
                                if (img.isNotEmpty) images.add(img);
                              }
                              if (fileUrl.isNotEmpty || type == 'file') {
                                files.add({'url': fileUrl, 'name': fileName});
                              }
                              if (images.length >= 6 && files.length >= 6) break;
                            }

                            return _glassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Grid foto (jika ada)
                                    if (images.isNotEmpty)
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: images.length > 6 ? 6 : images.length,
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 6,
                                          mainAxisSpacing: 6,
                                        ),
                                        itemBuilder: (context, i) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(images[i], fit: BoxFit.cover),
                                          );
                                        },
                                      )
                                    else
                                      Row(
                                        children: const [
                                          Icon(Icons.photo_library_outlined, color: Colors.white70),
                                          SizedBox(width: 8),
                                          Expanded(child: Text('Belum ada media', style: TextStyle(color: Colors.white70))),
                                        ],
                                      ),

                                    if (files.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Divider(color: Colors.white.withOpacity(0.15), height: 1),
                                      const SizedBox(height: 12),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: files.length > 6 ? 6 : files.length,
                                        separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
                                        itemBuilder: (context, i) {
                                          final f = files[i];
                                          final name = (f['name'] ?? 'Dokumen').toString();
                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            leading: const Icon(Icons.insert_drive_file, color: Colors.white),
                                            title: Text(name, style: const TextStyle(color: Colors.white)),
                                            subtitle: Text((f['url'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            onTap: () {
                                              // TODO: buka viewer/download
                                            },
                                          );
                                        },
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    FutureBuilder<String?>(
                      future: _resolveChatId(),
                      builder: (context, chatSnap) {
                        final chatId = chatSnap.data;
                        return _sectionHeader('Pesan Berbintang', onTap: (chatId == null)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StarredMessagesPage(
                                      chatId: chatId,
                                      peerUid: peerUid,
                                      peerName: name,
                                    ),
                                  ),
                                );
                              });
                      },
                    ),
                    FutureBuilder<String?>(
                      future: _resolveChatId(),
                      builder: (context, chatSnap) {
                        final chatId = chatSnap.data;
                        if (chatId == null) return const SizedBox();
                        return Builder(
                          builder: (context) {
                            final myUid = FirebaseAuth.instance.currentUser?.uid;
                            if (myUid == null || myUid.isEmpty) {
                              return _glassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.info_outline, color: Colors.white70),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('Silakan login ulang untuk melihat pesan berbintang', style: TextStyle(color: Colors.white70))),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final starredStream = FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatId)
                                .collection('messages')
                                .where('starredBy', arrayContains: myUid)
                                .limit(100)
                                .snapshots();
                            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: starredStream,
                              builder: (context, starSnap) {
                                if (starSnap.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                  );
                                }
                                final docs = starSnap.data?.docs ?? const [];
                                if (docs.isEmpty) {
                                  return _glassCard(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.star_border, color: Colors.white70),
                                          SizedBox(width: 8),
                                          Expanded(child: Text('Belum ada pesan berbintang', style: TextStyle(color: Colors.white70))),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                // Sort client-side by starredAt -> createdAt/ts (desc)
                                final sorted = [...docs];
                                sorted.sort((a, b) {
                                  final am = a.data();
                                  final bm = b.data();
                                  final at = am['starredAt'] ?? am['createdAt'] ?? am['ts'];
                                  final bt = bm['starredAt'] ?? bm['createdAt'] ?? bm['ts'];
                                  DateTime ad, bd;
                                  if (at is Timestamp) {
                                    ad = at.toDate();
                                  } else if (at is DateTime) {
                                    ad = at;
                                  } else {
                                    ad = DateTime.fromMillisecondsSinceEpoch(0);
                                  }
                                  if (bt is Timestamp) {
                                    bd = bt.toDate();
                                  } else if (bt is DateTime) {
                                    bd = bt;
                                  } else {
                                    bd = DateTime.fromMillisecondsSinceEpoch(0);
                                  }
                                  return bd.compareTo(ad);
                                });

                                final first = sorted.first.data();
                                final text = (first['text'] ?? first['message'] ?? '[media]').toString();
                                final rawTs = first['starredAt'] ?? first['createdAt'] ?? first['ts'];
                                DateTime? ts;
                                if (rawTs is Timestamp) ts = rawTs.toDate();
                                if (rawTs is DateTime) ts = rawTs;
                                final timeStr = (ts != null)
                                    ? '${ts.day}/${ts.month}/${ts.year} • ${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}'
                                    : '';

                                return _glassCard(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    leading: const Icon(Icons.star, color: Colors.amber),
                                    title: Text(
                                      text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      timeStr,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    // Powered by
                    Center(
                      child: Column(
                        children: [
                          Text('Powered by', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('lib/app/assets/images/cvm.png', height: 18),
                              const SizedBox(width: 6),
                              const Text('Cipta Vera Mandiri Digital',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _rowItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _glassButtonIcon({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.32),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
          ),
          child: TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            label: Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}