import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0; // 0: semua, 1: belum dibaca, 2: favorit, 3: grup

  Stream<QuerySnapshot<Map<String, dynamic>>>? _chatStream;
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      _chatStream = FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: u.uid)
          .snapshots();
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        if (user == null) {
          _chatStream = null;
        } else {
          _chatStream = FirebaseFirestore.instance
              .collection('chats')
              .where('members', arrayContains: user.uid)
              .snapshots();
        }
      });
    });
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
            onTap: () => _startChatByPin(context),
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
                child: Builder(
                  builder: (context) {
                    if (_chatStream == null) {
                      return const Center(child: Text('Harus login', style: TextStyle(color: Colors.white)));
                    }
                    final user = FirebaseAuth.instance.currentUser;
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _chatStream,
                      builder: (ctx, snap) {
                        final waiting = snap.connectionState == ConnectionState.waiting && !(snap.hasData && snap.data!.docs.isNotEmpty);
                        if (waiting && !_firstLoadDone) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasData) {
                          _firstLoadDone = true;
                        }
                        final docs = snap.data?.docs ?? [];
                        var items = docs.map((d) {
                          final data = d.data();
                          final members = List<String>.from(data['members'] ?? []);
                          final peerUid = members.firstWhere((m) => m != user?.uid, orElse: () => user?.uid ?? '');
                          final peerInfo = (data['memberInfo'] ?? {})[peerUid] ?? {};
                          return {
                            'chatId': d.id,
                            'name': peerInfo['name'] ?? 'Unknown',
                            'avatarUrl': peerInfo['avatarUrl'] ?? '',
                            'lastMessage': data['lastMessage'] ?? '',
                            'lastMessageAt': data['lastMessageAt'],
                            'unread': (data['unread']?[user?.uid] ?? 0) as int,
                            'membersCount': members.length,
                          };
                        }).toList();

                        // Sort by lastMessageAt descending (client-side)
                        items.sort((a, b) {
                          final A = a['lastMessageAt'];
                          final B = b['lastMessageAt'];
                          DateTime toDt(x) {
                            if (x is Timestamp) return x.toDate();
                            if (x is DateTime) return x;
                            return DateTime.fromMillisecondsSinceEpoch(0);
                          }
                          final ad = A == null ? DateTime.fromMillisecondsSinceEpoch(0) : toDt(A);
                          final bd = B == null ? DateTime.fromMillisecondsSinceEpoch(0) : toDt(B);
                          return bd.compareTo(ad); // desc
                        });

                        // filter search
                        final q = _searchCtrl.text.trim().toLowerCase();
                        if (q.isNotEmpty) {
                          items = items.where((c) =>
                              (c['name'] as String).toLowerCase().contains(q) ||
                              (c['lastMessage'] as String).toLowerCase().contains(q)).toList();
                        }

                        // filter tab
                        switch (_tabIndex) {
                          case 1:
                            items = items.where((c) => (c['unread'] ?? 0) > 0).toList();
                            break;
                          case 2:
                            items = []; // Could implement if you store a 'favorite' field
                            break;
                          case 3:
                            items = items.where((c) => (c['membersCount'] ?? 0) > 2).toList();
                            break;
                        }

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('Belum ada chat', style: TextStyle(color: Colors.white70)),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemBuilder: (context, i) {
                            final c = items[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    chatId: c['chatId'],
                                    peerName: c['name'],
                                    peerAvatarUrl: (c['avatarUrl'] as String).isEmpty ? null : c['avatarUrl'],
                                  ),
                                ));
                              },
                              child: _chatTileDynamic(c),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: items.length,
                        );
                      },
                    );
                  },
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
    // Since _all is removed, we can't count unread/favorite as before.
    // Show static labels or implement counting from Firestore if needed.
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
            label: 'Belum Dibaca',
            selected: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
          const SizedBox(width: 8),
          _glassChip(
            label: 'Favorit',
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

  Widget _chatTileDynamic(Map c) {
    String timeString = '';
    final lastMessageAt = c['lastMessageAt'];
    if (lastMessageAt != null) {
      DateTime dt;
      if (lastMessageAt is Timestamp) {
        dt = lastMessageAt.toDate();
      } else if (lastMessageAt is DateTime) {
        dt = lastMessageAt;
      } else {
        dt = DateTime.now();
      }
      // Show time as 'HH:mm' or 'dd/MM' if not today
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        timeString = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        timeString = '${dt.day}/${dt.month}';
      }
    }
    return ClipRRect(
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
                backgroundImage: (c['avatarUrl'] as String).isNotEmpty
                    ? NetworkImage(c['avatarUrl'])
                    : const AssetImage('lib/app/assets/images/cvm.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['name'] ?? '',
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
                      c['lastMessage'] ?? '',
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
                  Text(timeString, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  if ((c['unread'] ?? 0) > 0)
                    _badge(c['unread'] ?? 0)
                  else
                    const SizedBox(height: 20),
                ],
              )
            ],
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
  bool _pinEquals(Map<String, dynamic> data, String target) {
    String norm(dynamic v) => v == null ? '' : v.toString().replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final t = norm(target);
    final candidates = [
      data['pin'], data['userPin'], data['chatPin'], data['PIN'], data['Pin'],
    ];
    for (final c in candidates) {
      if (norm(c) == t && t.isNotEmpty) return true;
    }
    return false;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserByPin(String inputPin) async {
    final pin = inputPin.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final db = FirebaseFirestore.instance;

    // 1) Fast path: direct queries to likely fields
    try {
      var snap = await db.collection('users').where('pin', isEqualTo: pin).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first;

      snap = await db.collection('users').where('userPin', isEqualTo: pin).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first;

      snap = await db.collection('users').where('chatPin', isEqualTo: pin).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first;

      if (await _collectionExists('profiles')) {
        snap = await db.collection('profiles').where('pin', isEqualTo: pin).limit(1).get();
        if (snap.docs.isNotEmpty) return snap.docs.first;

        snap = await db.collection('profiles').where('userPin', isEqualTo: pin).limit(1).get();
        if (snap.docs.isNotEmpty) return snap.docs.first;

        snap = await db.collection('profiles').where('chatPin', isEqualTo: pin).limit(1).get();
        if (snap.docs.isNotEmpty) return snap.docs.first;
      }
    } catch (_) {
      // ignore and continue
    }

    // 2) PIN index collection: pins/{PIN} -> uid -> users/{uid}
    try {
      final pinDoc = await db.collection('pins').doc(pin).get();
      if (pinDoc.exists) {
        final data = pinDoc.data();
        final uid = (data?['uid'] ?? '').toString();
        if (uid.isNotEmpty) {
          final userDoc = await db.collection('users').doc(uid).get();
          if (userDoc.exists) return userDoc;
        }
      }
    } catch (_) {
      // ignore and continue
    }

    // 3) Fallback: client-side scan (bounded) on users, then profiles
    Future<DocumentSnapshot<Map<String, dynamic>>?> scan(String coll) async {
      try {
        final snap = await db.collection(coll).limit(500).get();
        for (final d in snap.docs) {
          final data = d.data();
          if (_pinEquals(data, pin)) return d;
        }
      } catch (_) {}
      return null;
    }

    final u = await scan('users');
    if (u != null) return u;

    if (await _collectionExists('profiles')) {
      final p = await scan('profiles');
      if (p != null) return p;
    }

    return null;
  }

  Future<bool> _collectionExists(String name) async {
    try {
      final db = FirebaseFirestore.instance;
      final s = await db.collection(name).limit(1).get();
      // If no exception thrown, assume exists (even if empty)
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startChatByPin(BuildContext ctx) async {
    final ctrl = TextEditingController();
    final pin = await showDialog<String>(
      context: ctx,
      barrierColor: Colors.black54,
      builder: (c) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Chat via PIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: TextField(
                            controller: ctrl,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => Navigator.pop(c, ctrl.text.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Masukkan PIN (mis. CV123456M)',
                              hintStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.key, color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Material(
                              color: Colors.white.withOpacity(0.10),
                              child: InkWell(
                                onTap: () => Navigator.pop(c),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Text('Batal', style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Material(
                              color: Colors.white.withOpacity(0.22),
                              child: InkWell(
                                onTap: () => Navigator.pop(c, ctrl.text.trim()),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (pin == null || pin.isEmpty) return;

    final normalizedPin = pin.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Harus login terlebih dahulu')));
      return;
    }

    // Cek apakah PIN itu milik sendiri
    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = myDoc.data() ?? const {};
      final mine = [data['pin'], data['userPin'], data['chatPin']]
          .where((v) => v != null)
          .map((v) => v.toString().replaceAll(RegExp(r'\s+'), '').toUpperCase())
          .toSet();
      if (mine.contains(normalizedPin)) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Itu adalah PIN Anda sendiri')));
        return;
      }
    } catch (_) {}

    // Cari user by PIN (multi-collection/field)
    final peer = await _findUserByPin(normalizedPin);
    if (peer == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('PIN tidak ditemukan')));
      return;
    }

    final peerUid = peer.id;
    if (peerUid == user.uid) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Itu adalah PIN Anda sendiri')));
      return;
    }

    final myUid = user.uid;
    final ids = [myUid, peerUid]..sort();
    final chatId = ids.join('_');

    final myProfileSnap = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    final myProfile = myProfileSnap.data() ?? <String, dynamic>{};
    final peerData = peer.data() ?? <String, dynamic>{};

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.set({
      'members': ids,
      'memberInfo': {
        myUid: {
          'pin': (myProfile['pin'] ?? '').toString(),
          'name': (myProfile['name'] ?? (user.displayName ?? 'Saya')).toString(),
          'avatarUrl': (myProfile['avatarUrl'] ?? '').toString(),
        },
        peerUid: {
          'pin': (peerData['pin'] ?? peerData['userPin'] ?? '').toString(),
          'name': (peerData['name'] ?? '').toString(),
          'avatarUrl': (peerData['avatarUrl'] ?? '').toString(),
        },
      },
      'lastMessage': FieldValue.delete(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          peerName: (peerData['name'] ?? '').toString(),
          peerAvatarUrl: (peerData['avatarUrl'] ?? '').toString().isEmpty ? null : (peerData['avatarUrl'] as String),
        ),
      ),
    );
  }
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
