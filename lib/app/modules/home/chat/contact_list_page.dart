// lib/app/modules/home/chat/contact_list_page.dart
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/chat_page.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  String? _myAvatarPath;

  Future<void> _loadMyLocalAvatar() async {
    final uid = _myUid;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dir = await getApplicationDocumentsDirectory();

      // candidate keys (support lama & baru)
      final keys = <String>[
        'fotoProfil_$uid',            // baru (disepakati)
        'profile_photo_$uid',         // kemungkinan lama
        'fotoProfil',                 // global lama
      ];

      String? savedPath;
      for (final k in keys) {
        final v = prefs.getString(k);
        if (v != null && v.isNotEmpty) {
          savedPath = v;
          break;
        }
      }

      // candidate fixed file paths (cek beberapa ekstensi)
      final candidates = <String>[
        '${dir.path}/profile_${uid}.jpg',
        '${dir.path}/profile_${uid}.jpeg',
        '${dir.path}/profile_${uid}.png',
        '${dir.path}/profile.jpg',           // sangat lama
      ];

      String? resolved;
      if (savedPath != null && savedPath.isNotEmpty && File(savedPath).existsSync()) {
        resolved = savedPath;
      } else {
        for (final p in candidates) {
          if (File(p).existsSync()) {
            resolved = p;
            break;
          }
        }
      }

      // self-heal key ke yang baru
      if (resolved != null) {
        await prefs.setString('fotoProfil_$uid', resolved);
      }

      if (mounted) {
        setState(() => _myAvatarPath = resolved);
      }
    } catch (_) {}
  }
  // Reusable glass icon button
  Widget _glassIconButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  String get _myUid => _auth.currentUser?.uid ?? '';
  String _q = '';

  // Controllers untuk tambah/edit kontak
  final TextEditingController _addPinCtrl = TextEditingController();
  final TextEditingController _aliasCtrl = TextEditingController();

  String? _lastFoundCollection; // menyimpan koleksi tempat PIN ditemukan terakhir

  String _normPin(String s) {
    return s
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), ''); // buang semua non-alfanumerik
  }

  static const List<String> _candidateUserCollections = [
    'users',
    'profiles',
    'user_profiles',
    'members',
  ];

  /// Fast lookup: pins/{PIN} -> { uid: ..., collection?: 'users' }
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findByPinsCollection(String normalizedPin) async {
    try {
      final doc = await _db.collection('pins').doc(normalizedPin).get();
      if (!doc.exists) return null;
      final data = (doc.data() ?? {}) as Map<String, dynamic>;
      final uid = (data['uid'] ?? data['userId'] ?? '').toString();
      if (uid.isEmpty) return null;
      final coll = (data['collection'] ?? 'users').toString();
      final userDoc = await _db.collection(coll).doc(uid).get();
      if (!userDoc.exists) return null;
      _lastFoundCollection = coll;
      // Bungkus ke QueryDocumentSnapshot-like via query ke 1 doc agar tipe tetap sama
      final snap = await _db.collection(coll).where(FieldPath.documentId, isEqualTo: uid).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first;
    } catch (_) {
      return null;
    }
  }

  /// Cari user berdasarkan beberapa kemungkinan nama field PIN di Firestore, lintas koleksi
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserByPin(String pinUpperNoSpace) async {
    for (final coll in _candidateUserCollections) {
      final tries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
        _db.collection(coll).where('pin', isEqualTo: pinUpperNoSpace).limit(1).get(),
        _db.collection(coll).where('userPin', isEqualTo: pinUpperNoSpace).limit(1).get(),
        _db.collection(coll).where('PIN', isEqualTo: pinUpperNoSpace).limit(1).get(),
        _db.collection(coll).where('pinUpper', isEqualTo: pinUpperNoSpace).limit(1).get(),
      ];
      for (final fut in tries) {
        try {
          final q = await fut;
          if (q.docs.isNotEmpty) {
            _lastFoundCollection = coll;
            return q.docs.first;
          }
        } catch (_) {
          // abaikan jika index/field tidak ada
        }
      }
    }
    return null;
  }

  /// LAST-RESORT: scan beberapa dokumen user (max 500) dan cocokan PIN setelah dinormalisasi, lintas koleksi
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _fallbackScanByPin(String normalizedPin) async {
    try {
      for (final coll in _candidateUserCollections) {
        final snap = await _db.collection(coll).limit(500).get();
        for (final d in snap.docs) {
          final data = d.data();
          final candidates = [data['pin'], data['userPin'], data['PIN'], data['pinUpper']];
          for (final c in candidates) {
            if (c == null) continue;
            final norm = _normPin(c.toString());
            if (norm == normalizedPin) {
              _lastFoundCollection = coll;
              return d;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final v = _searchCtrl.text.trim();
      if (v != _q) {
        setState(() => _q = v);
      }
    });
    _loadMyLocalAvatar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _addPinCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }

  // Membuat / mendapatkan DM chatId antara saya & peer
  Future<String?> _ensureDmChat(String myUid, String peerUid) async {
    try {
      // Cek apakah sudah ada chat DM dengan 2 anggota ini
      final q = await _db
          .collection('chats')
          .where('type', isEqualTo: 'dm')
          .where('members', arrayContains: myUid)
          .limit(50)
          .get();

      for (final d in q.docs) {
        final m = List<String>.from((d.data()['members'] ?? const []) as List);
        if (m.length == 2 && m.contains(peerUid)) {
          return d.id; // sudah ada DM
        }
      }

      // Buat baru
      final doc = _db.collection('chats').doc();
      await doc.set({
        'type': 'dm',
        'members': [myUid, peerUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': myUid,
        'unread': { peerUid: 0, myUid: 0 },
      }, SetOptions(merge: true));
      return doc.id;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat chat: $e')),
        );
      }
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _userStream() {
    final base = _db.collection('users');
    if (_q.isEmpty) {
      return base.orderBy('name', descending: false).limit(200).snapshots();
    }
    // simple search by name / pin (case-insensitive: simpan nameLower & pinUpper di users agar efisien)
    final qLower = _q.toLowerCase();
    return base
        .where('searchKeywords', arrayContains: qLower) // OPTIONAL index (lihat catatan bawah)
        .limit(200)
        .snapshots();
  }

  bool _matchLocal(Map<String, dynamic> u) {
    if (_q.isEmpty) return true;
    final name = (u['name'] ?? '').toString().toLowerCase();
    final pin = (u['pin'] ?? '').toString().toLowerCase();
    return name.contains(_q.toLowerCase()) || pin.contains(_q.toLowerCase());
  }

  // Stream daftar kontak saya (users/{uid}/contacts)
  Stream<QuerySnapshot<Map<String, dynamic>>> _contactsStream() {
    if (_myUid.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(_myUid)
        .collection('contacts')
        .orderBy('displayName', descending: false)
        .snapshots();
  }

  // Ambil profile user peer untuk melengkapi avatar/status jika ada, bisa lintas koleksi
  Future<Map<String, dynamic>> _fetchUserProfile(String uid, {String collection = 'users'}) async {
    try {
      final d = await _db.collection(collection).doc(uid).get();
      return d.data() ?? <String, dynamic>{};
    } catch (_) {
      // fallback coba ke 'users' kalau koleksi lain gagal
      try {
        final d2 = await _db.collection('users').doc(uid).get();
        return d2.data() ?? <String, dynamic>{};
      } catch (_) {
        return <String, dynamic>{};
      }
    }
  }

  void _showContactMenu({required String peerUid, required String currentAlias, required String currentDisplayName, required String currentPin}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kelola Kontak', style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.white),
                    title: const Text('Edit nama (alias)', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _editContactName(peerUid: peerUid, currentAlias: currentAlias, fallbackName: currentDisplayName);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.redAccent),
                    title: const Text('Hapus kontak', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _deleteContact(peerUid);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteContact(String peerUid) async {
    if (_myUid.isEmpty) return;
    try {
      await _db.collection('users').doc(_myUid).collection('contacts').doc(peerUid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kontak dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  Future<void> _editContactName({required String peerUid, required String currentAlias, required String fallbackName}) async {
    _aliasCtrl.text = currentAlias.isNotEmpty ? currentAlias : fallbackName;
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit nama kontak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aliasCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nama alias',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                              ),
                              child: TextButton(
                                onPressed: () async {
                                  final alias = _aliasCtrl.text.trim();
                                  Navigator.pop(ctx);
                                  try {
                                    await _db
                                        .collection('users')
                                        .doc(_myUid)
                                        .collection('contacts')
                                        .doc(peerUid)
                                        .set({'alias': alias}, SetOptions(merge: true));
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama disimpan')));
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAddContactSheet() {
    _addPinCtrl.clear();
    _aliasCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tambah Kontak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addPinCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Masukkan PIN (contoh: CV123456M)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _aliasCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nama alias (opsional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addContactByPin,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Tambah'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addContactByPin() async {
    final raw = _addPinCtrl.text;
    final pin = _normPin(raw);
    final alias = _aliasCtrl.text.trim();
    // Coba fast path via koleksi `pins`
    QueryDocumentSnapshot<Map<String, dynamic>>? peer;
    // debug log pin yang dicari (bisa dicek di log)
    // ignore: avoid_print
    print('[Contact] cari PIN: "$pin" (raw: "$raw")');
    Navigator.pop(context);
    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN wajib diisi')));
      return;
    }
    if (_myUid.isEmpty) return;

    try {
      peer = await _findByPinsCollection(pin);
      peer ??= await _findUserByPin(pin);
      peer ??= await _fallbackScanByPin(pin);
      if (peer == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN tidak ditemukan')));
        return;
      }
      if (peer.id == _myUid) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa menambahkan diri sendiri')));
        return;
      }

      // ignore: avoid_print
      print('[Contact] PIN ditemukan di koleksi: ${_lastFoundCollection ?? 'users'} docId=${peer.id}');
      // ignore: avoid_print
      print('[Contact] normalizedPin used: $pin');

      // simpan ke kontak saya
      await _db
          .collection('users').doc(_myUid)
          .collection('contacts').doc(peer.id)
          .set({
            'displayName': (peer.data()['name'] ?? peer.data()['displayName'] ?? peer.data()['username'] ?? peer.data()['fullName'] ?? ''),
            'pin': (peer.data()['pin'] ?? peer.data()['userPin'] ?? peer.data()['PIN'] ?? peer.data()['pinUpper'] ?? pin),
            'alias': alias,
            'collection': _lastFoundCollection ?? 'users',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kontak ditambahkan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambah kontak: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kontak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient under the AppBar (so it doesn't look black)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF007BC1), Color.fromARGB(255, 65, 143, 196)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Glass overlay + bottom border
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            onPressed: _openAddContactSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Cari nama / PIN',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_q.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => _searchCtrl.clear(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: true,
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Header: profil saya (per akun)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _myUid.isEmpty
                    ? const Stream.empty()
                    : _db.collection('users').doc(_myUid).snapshots(),
                builder: (context, snapMe) {
                  final data = snapMe.data?.data() ?? <String, dynamic>{};
                  final myName = (data['name'] ?? data['displayName'] ?? data['fullName'] ?? '').toString();
                  final myPin = (data['pin'] ?? data['userPin'] ?? data['PIN'] ?? '').toString();
                  final netAvatar = (data['avatarUrl'] ?? data['photoUrl'] ?? data['profilePhoto'] ?? '').toString();

                  ImageProvider avatarProvider;
                  if (_myAvatarPath != null && File(_myAvatarPath!).existsSync()) {
                    avatarProvider = FileImage(File(_myAvatarPath!));
                  } else if (netAvatar.isNotEmpty) {
                    avatarProvider = NetworkImage(netAvatar);
                  } else {
                    avatarProvider = const AssetImage('lib/app/assets/images/cvm.png');
                  }

                  // trigger reload local avatar on profile updates
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _loadMyLocalAvatar();
                  });

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 24, backgroundImage: avatarProvider),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      myName.isNotEmpty ? myName : 'Profil Saya',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                    if (myPin.isNotEmpty)
                                      Text('PIN: $myPin', style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                              _glassIconButton(
                                icon: Icons.refresh,
                                onTap: () {
                                  _loadMyLocalAvatar();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _contactsStream(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const SizedBox();
                    }
                    final contactDocs = snap.data!.docs.where((d) {
                      if (_q.isEmpty) return true;
                      final data = d.data();
                      final name = (data['displayName'] ?? '').toString().toLowerCase();
                      final pin = (data['pin'] ?? '').toString().toLowerCase();
                      return name.contains(_q.toLowerCase()) || pin.contains(_q.toLowerCase());
                    }).toList();

                    if (contactDocs.isEmpty) {
                      return const Center(
                        child: Text('Belum ada kontak. Tambahkan lewat tombol di AppBar.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(8, 8, 8, 24 + MediaQuery.of(context).padding.bottom),
                      itemCount: contactDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final d = contactDocs[i];
                        final c = d.data();
                        final peerUid = d.id; // docId = uid target
                        final displayName = (c['displayName'] ?? '').toString();
                        final pin = (c['pin'] ?? '').toString();
                        final alias = (c['alias'] ?? '').toString();
                        final shownName = alias.isNotEmpty ? alias : (displayName.isNotEmpty ? displayName : 'Tanpa Nama');

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _fetchUserProfile(peerUid, collection: (c['collection'] ?? 'users').toString()),
                          builder: (context, profSnap) {
                            final prof = profSnap.data ?? const {};
                            final avatar = (prof['avatarUrl'] ?? prof['photoUrl'] ?? prof['profilePhoto'] ?? '').toString();
                            final online = (prof['online'] ?? false) == true;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundImage: avatar.isNotEmpty
                                              ? NetworkImage(avatar)
                                              : const AssetImage('lib/app/assets/images/cvm.png') as ImageProvider,
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 12, height: 12,
                                            decoration: BoxDecoration(
                                              color: online ? const Color(0xFF25D366) : Colors.grey,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Text(shownName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    subtitle: Text(pin.isNotEmpty ? 'PIN: $pin' : displayName, style: const TextStyle(color: Colors.white70)),
                                    onTap: () async {
                                      final chatId = await _ensureDmChat(_myUid, peerUid);
                                      if (!mounted || chatId == null) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            chatId: chatId,
                                            peerName: shownName,
                                            peerAvatarUrl: avatar.isNotEmpty ? avatar : null,
                                          ),
                                        ),
                                      );
                                    },
                                    onLongPress: () => _showContactMenu(peerUid: peerUid, currentAlias: alias, currentDisplayName: displayName, currentPin: pin),
                                    trailing: _glassIconButton(
                                      icon: Icons.more_vert,
                                      onTap: () => _showContactMenu(
                                        peerUid: peerUid,
                                        currentAlias: alias,
                                        currentDisplayName: displayName,
                                        currentPin: pin,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Powered by
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Powered by', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('lib/app/assets/images/cvm.png', height: 18),
                        const SizedBox(width: 6),
                        const Text('Cipta Vera Mandiri Digital', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContactAction(String action, String peerUid, String alias, String displayName, String pin) {
    if (action == 'edit') {
      _editContactName(peerUid: peerUid, currentAlias: alias, fallbackName: displayName);
    } else if (action == 'delete') {
      _deleteContact(peerUid);
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMyLocalAvatar();
  }
}