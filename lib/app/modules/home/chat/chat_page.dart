// Chat detail page (not ChatListPage)
import 'dart:ui';

import 'dart:io';

import 'dart:async';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/user_profile_page.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/chat/starred_messages_page.dart';

class ChatPage extends StatefulWidget {
  final String? chatId; // null = fallback dummy mode
  final String? peerName;
  final String? peerAvatarUrl;
  ChatPage({super.key, this.chatId, this.peerName, this.peerAvatarUrl});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<void> _saveImageForMessage({String? localPath, String? imageUrl}) async {
    try {
      dynamic result;
      if (localPath != null && localPath.isNotEmpty) {
        // Simpan langsung dari file lokal
        result = await ImageGallerySaver.saveFile(localPath);
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        // Unduh bytes lalu simpan ke galeri
        final uri = Uri.parse(imageUrl);
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final Uint8List bytes = Uint8List.fromList(resp.bodyBytes);
          result = await ImageGallerySaver.saveImage(
            bytes,
            quality: 90,
            name: 'chat_${DateTime.now().millisecondsSinceEpoch}',
          );
        } else {
          throw 'HTTP ${resp.statusCode}';
        }
      } else {
        throw 'Tidak ada sumber gambar';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar disimpan ke galeri')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan gambar: $e')),
      );
    }
  }
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  String get _myUid => _auth.currentUser?.uid ?? '';

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _localMediaPreview = {};
  String get _localMediaPrefsKey => 'chatLocalMedia_${widget.chatId ?? 'dummy'}';

  final List<_Msg> _messages = <_Msg>[
    _Msg(text: 'Halo! 👋', isMe: false, time: const TimeOfDay(hour: 9, minute: 12), delivered: true, readBy: const []),
    _Msg(text: 'Selamat datang di chat.', isMe: false, time: const TimeOfDay(hour: 9, minute: 12), delivered: true, readBy: const []),
  ];

  // Guard to prevent multiple forward sheets stacking
  bool _forwardSheetOpen = false;

  bool _markedReadOnce = false;
  String? _peerUid;

  StreamSubscription? _connSub;
  bool _isOnline = true; // koneksi perangkat ini

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _peerPresenceSub;
  String _peerPresenceText = 'online';

  Timer? _presenceTimer;

  Future<String?> _getPeerUid(String chatId) async {
    try {
      final doc = await _db.collection('chats').doc(chatId).get();
      final data = doc.data() ?? {};
      final members = List<String>.from((data['members'] ?? const []) as List);
      final p = members.firstWhere((m) => m != _myUid, orElse: () => '');
      if (p.isEmpty) return null;
      _peerUid = p;
      return p;
    } catch (_) {
      return null;
    }
  }

  Future<void> _markRead() async {
    if (widget.chatId == null || _myUid.isEmpty) return;
    try {
      final chatRef = _db.collection('chats').doc(widget.chatId!);
      await chatRef.set({'unread': { _myUid: 0 }}, SetOptions(merge: true));

      // Tandai pesan lawan sebagai dibaca: tambahkan myUid ke readBy jika belum ada
      final snap = await chatRef.collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();
      final batch = _db.batch();
      for (final m in snap.docs) {
        final data = m.data();
        if (data['senderId'] == _myUid) continue; // hanya pesan lawan
        final List read = (data['readBy'] ?? []);
        if (!read.contains(_myUid)) {
          batch.set(m.reference, {
            'readBy': FieldValue.arrayUnion([_myUid])
          }, SetOptions(merge: true));
        }
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    if (widget.chatId != null && _myUid.isNotEmpty) {
      _getPeerUid(widget.chatId!);
      // Monitor konektivitas perangkat sendiri
      _connSub = Connectivity().onConnectivityChanged.listen((result) {
        final online = result != ConnectivityResult.none;
        if (mounted) setState(() => _isOnline = online);
      });

      // Heartbeat presence saya
      _startPresenceHeartbeat();

      // Listen presence peer
      _listenPeerPresence();
      _rehydrateLocalPreviews();
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _connSub?.cancel();
    _peerPresenceSub?.cancel();
    _presenceTimer?.cancel();
    // persist local media cache
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = json.encode(_localMediaPreview);
        await prefs.setString(_localMediaPrefsKey, jsonStr);
      } catch (_) {}
    }();
    // set offline lastSeen
    if (_myUid.isNotEmpty) {
      _db.collection('users').doc(_myUid).set({
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    super.dispose();
  }

  Future<void> _send() async {
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty) return;

    _textCtrl.clear();

    if (widget.chatId == null) {
      // Fallback: local dummy mode
      setState(() {
        _messages.add(_Msg(text: txt, isMe: true, time: TimeOfDay.now()));
      });
    } else {
      try {
        final chatId = widget.chatId!;
        // Ensure we know peer uid to increment their unread
        _peerUid ??= await _getPeerUid(chatId);
        final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
        final chatRef = _db.collection('chats').doc(chatId);
        final batch = _db.batch();

        batch.set(msgRef, {
          'text': txt,
          'senderId': _myUid,
          'type': 'text',
          'createdAt': FieldValue.serverTimestamp(),
          'readBy': _myUid.isNotEmpty ? [_myUid] : [],
          'delivered': false,
        });

        final updateMap = {
          'lastMessage': txt,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': _myUid,
        };
        if (_peerUid != null && _peerUid!.isNotEmpty) {
          updateMap['unread'] = { _peerUid!: FieldValue.increment(1) };
        }
        batch.set(chatRef, updateMap, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal kirim: $e')),
          );
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    });
  }

  void _startPresenceHeartbeat() {
    // Simpan status online & lastSeen ke Firestore users/{uid}
    if (_myUid.isEmpty) return;
    _presenceTimer?.cancel();
    // initial set
    _db.collection('users').doc(_myUid).set({
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _presenceTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _db.collection('users').doc(_myUid).set({
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void _listenPeerPresence() async {
    if (widget.chatId == null) return;
    // pastikan peer uid
    _peerUid ??= await _getPeerUid(widget.chatId!);
    final peer = _peerUid;
    if (peer == null || peer.isEmpty) return;

    _peerPresenceSub?.cancel();
    _peerPresenceSub = _db.collection('users').doc(peer).snapshots().listen((doc) {
      final data = doc.data() ?? {};
      final online = (data['online'] ?? false) == true;
      if (online) {
        if (mounted) setState(() => _peerPresenceText = 'online');
      } else {
        final ts = data['lastSeen'];
        String last = 'offline';
        if (ts is Timestamp) {
          final dt = ts.toDate();
          final hh = dt.hour.toString().padLeft(2, '0');
          final mm = dt.minute.toString().padLeft(2, '0');
          last = 'terakhir online $hh:$mm';
        }
        if (mounted) setState(() => _peerPresenceText = last);
      }
    });
  }

  Future<void> _openPeerProfile() async {
    if (widget.chatId == null) return;
    // pastikan kita punya peer uid
    _peerUid ??= await _getPeerUid(widget.chatId!);
    final peer = _peerUid;
    if (!mounted || peer == null || peer.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfilePage(peerUid: peer)),
    );
  }

  Future<void> _openStarredMessages() async {
    if (widget.chatId == null) return;
    // Pastikan peer uid tersedia (untuk read receipt / judul opsional)
    _peerUid ??= await _getPeerUid(widget.chatId!);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StarredMessagesPage(
          chatId: widget.chatId,
          peerUid: _peerUid,
          peerName: widget.peerName,
        ),
      ),
    );
  }

  Future<void> _openAttachSheet() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_camera, color: Colors.white),
                      title: const Text('Kamera', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickFromCamera();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library, color: Colors.white),
                      title: const Text('Media', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickFromGallery();
                      },
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

  Future<void> _pickFromCamera() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (x == null) return;
      await _sendImageFromXFile(x);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil kamera: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (x == null) return;
      await _sendImageFromXFile(x);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil media: $e')),
      );
    }
  }

  Future<void> _sendImageFromXFile(XFile xfile) async {
    // Jika belum ada chatId (dummy mode), tampilkan di UI saja
    if (widget.chatId == null) {
      setState(() {
        _messages.add(_Msg(
          text: 'Foto',
          isMe: true,
          time: TimeOfDay.now(),
          imageUrl: null,
          localPath: xfile.path,
        ));
      });
      return;
    }

    try {
      final chatId = widget.chatId!;
      _peerUid ??= await _getPeerUid(chatId);
      final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
      final chatRef = _db.collection('chats').doc(chatId);
      final batch = _db.batch();

      // Karena belum pakai Firebase Storage, kirim metadata text saja.
      batch.set(msgRef, {
        'type': 'image',
        'imageUrl': null, // isi nanti jika Storage sudah aktif
        'text': 'Foto',
        'senderId': _myUid,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': _myUid.isNotEmpty ? [_myUid] : [],
        'delivered': false,
      });

      final updateMap = {
        'lastMessage': '[Foto]',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': _myUid,
      };
      if (_peerUid != null && _peerUid!.isNotEmpty) {
        updateMap['unread'] = { _peerUid!: FieldValue.increment(1) };
      }
      batch.set(chatRef, updateMap, SetOptions(merge: true));

      await batch.commit();

      // simpan path lokal untuk preview pada pengirim
      _localMediaPreview[msgRef.id] = xfile.path;
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = json.encode(_localMediaPreview);
        await prefs.setString(_localMediaPrefsKey, jsonStr);
      } catch (_) {}
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim foto: $e')),
      );
    }
  }
  Future<void> _rehydrateLocalPreviews() async {
    if (widget.chatId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_localMediaPrefsKey);
      if (mapJson != null && mapJson.isNotEmpty) {
        final Map<String, dynamic> raw = json.decode(mapJson) as Map<String, dynamic>;
        _localMediaPreview
          ..clear()
          ..addAll(raw.map((k, v) => MapEntry(k, v.toString())));
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _showForwardSheet({required Map<String, dynamic> msgData}) async {
    if (_forwardSheetOpen) return;
    _forwardSheetOpen = true;
    try {
      // Ambil daftar chat milik user ini (kecuali current chat) untuk tujuan forward
      final qs = await _db
          .collection('chats')
          .where('members', arrayContains: _myUid)
          .limit(30)
          .get();

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        title: Text('Teruskan ke…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: qs.docs.length,
                          itemBuilder: (context, i) {
                            final cd = qs.docs[i];
                            if (cd.id == widget.chatId) {
                              // Sembunyikan chat yang sedang dibuka
                              return const SizedBox.shrink();
                            }
                            final data = cd.data();
                            final members = List<String>.from((data['members'] ?? const []) as List);
                            String peer = '';
                            if (members.length >= 2) {
                              peer = members.firstWhere((m) => m != _myUid, orElse: () => '');
                            }
                            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              future: peer.isEmpty ? null : _db.collection('users').doc(peer).get(),
                              builder: (context, snap) {
                                final name = snap.data?.data()?['name'] ?? 'Chat';
                                final avatar = snap.data?.data()?['avatarUrl'] as String?;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                                        ? NetworkImage(avatar)
                                        : const AssetImage('lib/app/assets/images/cvm.png') as ImageProvider,
                                  ),
                                  title: Text(name.toString(), style: const TextStyle(color: Colors.white)),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _forwardToChat(targetChatId: cd.id, original: msgData);
                                  },
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
            ),
          );
        },
      );
    } finally {
      _forwardSheetOpen = false;
    }
  }

  Future<void> _forwardToChat({required String targetChatId, required Map<String, dynamic> original}) async {
    try {
      final msgRef = _db.collection('chats').doc(targetChatId).collection('messages').doc();
      final chatRef = _db.collection('chats').doc(targetChatId);

      final String type = (original['type'] ?? 'text').toString();
      final String text = (original['text'] ?? '').toString();
      final String? imageUrl = original['imageUrl'] as String?;

      final Map<String, dynamic> payload = {
        'senderId': _myUid,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': _myUid.isNotEmpty ? [_myUid] : [],
        'delivered': false,
      };

      if (type == 'image') {
        payload['type'] = 'image';
        // jika sudah pakai Storage, imageUrl akan terisi dan bisa ikut diteruskan
        payload['imageUrl'] = imageUrl; // bisa null untuk sekarang
        payload['text'] = 'Foto';
      } else {
        payload['type'] = 'text';
        payload['text'] = text;
      }

      final batch = _db.batch();
      batch.set(msgRef, payload);
      batch.set(chatRef, {
        'lastMessage': type == 'image' ? '[Foto]' : text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': _myUid,
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan diteruskan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal meneruskan: $e')),
      );
    }
  }

  void _showMessageActions({required String msgId, required bool isMe, required bool isStarred, String? localPath, String? imageUrl}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((localPath != null && localPath.isNotEmpty) || (imageUrl != null && imageUrl.isNotEmpty))
                    ListTile(
                      leading: const Icon(Icons.download_rounded, color: Colors.white),
                      title: const Text('Unduh gambar', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(context);
                        await _saveImageForMessage(localPath: localPath, imageUrl: imageUrl);
                      },
                    ),
                  ListTile(
                    leading: Icon(isStarred ? Icons.star : Icons.star_border, color: Colors.amber),
                    title: Text(isStarred ? 'Hapus bintang' : 'Bintangi pesan', style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _toggleStar(msgId: msgId, value: !isStarred);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.visibility_off, color: Colors.white),
                    title: const Text('Hapus untuk saya', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _deleteForMe(msgId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pesan dihapus untuk Anda')),
                      );
                    },
                  ),
                  if (isMe)
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.white),
                      title: const Text('Hapus untuk semua orang', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(context);
                        await _deleteForAll(msgId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pesan dihapus untuk semua')),
                        );
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

  Future<void> _deleteForMe(String msgId) async {
    if (widget.chatId == null || _myUid.isEmpty) return;
    await _db
        .collection('chats')
        .doc(widget.chatId!)
        .collection('messages')
        .doc(msgId)
        .set({'deletedFor': FieldValue.arrayUnion([_myUid])}, SetOptions(merge: true));
  }

  Future<void> _deleteForAll(String msgId) async {
    if (widget.chatId == null) return;
    await _db
        .collection('chats')
        .doc(widget.chatId!)
        .collection('messages')
        .doc(msgId)
        .set({'isDeleted': true}, SetOptions(merge: true));
  }

  Future<void> _toggleStar({required String msgId, required bool value}) async {
    if (widget.chatId == null) return;
    final ref = _db
        .collection('chats')
        .doc(widget.chatId!)
        .collection('messages')
        .doc(msgId);

    final data = <String, dynamic>{
      'starred': value,
      'starredAt': FieldValue.serverTimestamp(),
    };
    if (_myUid.isNotEmpty) {
      data['starredBy'] = value
          ? FieldValue.arrayUnion([_myUid])
          : FieldValue.arrayRemove([_myUid]);
    }

    await ref.set(data, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Pesan dibintangi' : 'Bintang dihapus'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _openPeerProfile,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.peerAvatarUrl != null
                      ? NetworkImage(widget.peerAvatarUrl!)
                      : const AssetImage('lib/app/assets/images/cvm.png') as ImageProvider,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.peerName ?? 'CVM Support',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(_peerPresenceText, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              // optional: implement call action
            },
          ),
        ],
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
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: widget.chatId == null
                        ? ListView.builder(
                            controller: _scrollCtrl,
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final m = _messages[index];
                              final prevIsMe = index > 0 ? _messages[index - 1].isMe : null;
                              final nextIsMe = index < _messages.length - 1 ? _messages[index + 1].isMe : null;
                              return _Bubble(
                                msg: m,
                                startGroup: prevIsMe == null || prevIsMe != m.isMe,
                                endGroup: nextIsMe == null || nextIsMe != m.isMe,
                              );
                            },
                          )
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _db
                                .collection('chats')
                                .doc(widget.chatId!)
                                .collection('messages')
                                .orderBy('createdAt', descending: false)
                                .limit(500)
                                .snapshots(),
                            builder: (context, snap) {
                              // Hindari spinner saat keyboard muncul / saat mengirim pesan
                              // Tampilkan data terakhir jika ada, atau kosong tanpa loading
                              final docs = snap.data?.docs ?? const [];
                              if (docs.isEmpty) {
                                return const SizedBox();
                              }

                              // One-time mark as read
                              if (!_markedReadOnce) {
                                _markedReadOnce = true;
                                _markRead();
                              }

                              // Auto-scroll ke bawah ketika pesan baru tiba
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollCtrl.hasClients) {
                                  _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                                }
                              });

                              return ListView.builder(
                                controller: _scrollCtrl,
                                physics: const BouncingScrollPhysics(),
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final doc = snap.data!.docs[index];
                                  final d = doc.data();
                                  final List<String> deletedFor = List<String>.from((d['deletedFor'] ?? const []) as List);
                                  if (deletedFor.contains(_myUid)) {
                                    return const SizedBox.shrink(); // tersembunyi untuk saya
                                  }

                                  final isDeleted = (d['isDeleted'] ?? false) == true;
                                  final isMe = d['senderId'] == _myUid;
                                  final text = isDeleted ? 'Pesan ini telah dihapus' : ((d['text'] ?? '') as String);
                                  final ts = d['createdAt'];
                                  DateTime time;
                                  if (ts is Timestamp) {
                                    time = ts.toDate();
                                  } else if (ts is DateTime) {
                                    time = ts;
                                  } else {
                                    time = DateTime.now();
                                  }

                                  final delivered = (d['delivered'] ?? false) == true;
                                  final List<String> readBy = List<String>.from((d['readBy'] ?? const []) as List);

                                  // Jika pesan dari lawan dan belum ditandai delivered -> tandai sekarang
                                  if (!isMe && !delivered && widget.chatId != null) {
                                    _db
                                        .collection('chats')
                                        .doc(widget.chatId!)
                                        .collection('messages')
                                        .doc(doc.id)
                                        .set({'delivered': true}, SetOptions(merge: true));
                                  }

                                  final prevIsMe = index > 0 ? (snap.data!.docs[index - 1].data()['senderId'] == _myUid) : null;
                                  final nextIsMe = index < snap.data!.docs.length - 1 ? (snap.data!.docs[index + 1].data()['senderId'] == _myUid) : null;
                                  final String type = (d['type'] ?? 'text').toString();
                                  final String? imageUrl = d['imageUrl'] as String?;
                                  final String? localPreview = _localMediaPreview[doc.id];

                                  return GestureDetector(
                                    onLongPress: () => _showMessageActions(
                                      msgId: doc.id,
                                      isMe: isMe,
                                      isStarred: (d['starred'] ?? false) == true,
                                      localPath: localPreview,
                                      imageUrl: imageUrl,
                                    ),
                                    onHorizontalDragUpdate: (details) {
                                      // no-op, we check on end by velocity & delta using primaryDelta via details
                                    },
                                    onHorizontalDragEnd: (details) {
                                      // geser ke kanan => velocity positif yang cukup besar
                                      if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
                                        final msgData = {
                                          'type': type,
                                          'text': text,
                                          'imageUrl': imageUrl,
                                        };
                                        _showForwardSheet(msgData: msgData);
                                      }
                                    },
                                    child: _Bubble(
                                      msg: _Msg(
                                        text: text,
                                        isMe: isMe,
                                        time: TimeOfDay.fromDateTime(time),
                                        delivered: delivered,
                                        readBy: readBy,
                                        isDeleted: isDeleted,
                                        imageUrl: imageUrl,
                                        localPath: localPreview,
                                      ),
                                      startGroup: prevIsMe == null || prevIsMe != isMe,
                                      endGroup: nextIsMe == null || nextIsMe != isMe,
                                      peerUid: _peerUid ?? '',
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  _Composer(controller: _textCtrl, onSend: _send),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      final emoji = await showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) {
                          final emojis = [
                            '😀','😁','😂','🤣','😊','😍','😘','😎','🤩','🤗','🤔','😴','🙏','👍','👎','👏','🙌','💪','🔥','💯','🎉','🥰','😇','😢','😡','🤝','👌','✨','🌟','🎁','🥳',
                          ];
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                  ),
                                  itemCount: emojis.length,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () => Navigator.pop(context, emojis[index]),
                                      child: Center(
                                        child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );

                      if (emoji != null && emoji.isNotEmpty) {
                        final text = controller.text;
                        final sel = controller.selection;
                        final insertAt = sel.isValid ? sel.start : text.length;
                        final newText = text.replaceRange(insertAt, insertAt, emoji);
                        controller.text = newText;
                        final newOffset = insertAt + emoji.length;
                        controller.selection = TextSelection.collapsed(offset: newOffset);
                      }
                    },
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Ketik pesan',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                              if (controller.text.trim().isNotEmpty) {
                                onSend();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            final _ChatPageState? state = context.findAncestorStateOfType<_ChatPageState>();
                            state?._openAttachSheet();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                            ),
                            child: IconButton(
                              icon: Icon(hasText ? Icons.send : Icons.mic, color: Colors.white),
                              onPressed: hasText
                                  ? () {
                                      FocusScope.of(context).unfocus();
                                      onSend();
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, this.startGroup = true, this.endGroup = true, this.peerUid = ''});
  final _Msg msg;
  final bool startGroup;
  final bool endGroup;
  final String peerUid;

  @override
  Widget build(BuildContext context) {
    final align = msg.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = msg.isMe ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.92);

    final bool isPureImage = ((msg.imageUrl != null && msg.imageUrl!.isNotEmpty) || (msg.localPath != null && msg.localPath!.isNotEmpty)) && (msg.text.isEmpty || msg.text == 'Foto');

    final br = BorderRadius.only(
      topLeft: Radius.circular(msg.isMe ? 16 : (startGroup ? 16 : 6)),
      topRight: Radius.circular(msg.isMe ? (startGroup ? 16 : 6) : 16),
      bottomLeft: Radius.circular(msg.isMe ? 16 : (endGroup ? 2 : 6)),
      bottomRight: Radius.circular(msg.isMe ? (endGroup ? 2 : 6) : 16),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: EdgeInsets.only(
            left: msg.isMe ? 64 : 8,
            right: msg.isMe ? 8 : 64,
            top: startGroup ? 6 : 2,
            bottom: endGroup ? 6 : 2,
          ),
          padding: isPureImage ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 8, 8, 6),
          decoration: BoxDecoration(
            color: isPureImage ? Colors.transparent : color,
            borderRadius: isPureImage ? BorderRadius.circular(12) : br,
            boxShadow: isPureImage ? const [] : const [
              BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((msg.imageUrl != null && msg.imageUrl!.isNotEmpty) || (msg.localPath != null && msg.localPath!.isNotEmpty))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: (msg.localPath != null && msg.localPath!.isNotEmpty)
                              ? Image.file(
                                  File(msg.localPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Center(child: Icon(Icons.image, size: 40))),
                                )
                              : Image.network(
                                  msg.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Center(child: Icon(Icons.broken_image, size: 40))),
                                ),
                        ),
                      ),
                    if (msg.text.isNotEmpty && (msg.text != 'Foto'))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.25,
                            fontStyle: msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                            color: msg.isDeleted ? Colors.grey[700] : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _fmtTime(msg.time),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (msg.isMe && !msg.isDeleted) ...[
                const SizedBox(width: 2),
                if (!msg.delivered)
                  const Icon(Icons.check, size: 16, color: Colors.grey),
                if (msg.delivered && !(msg.readBy.contains(peerUid)))
                  const Icon(Icons.done_all, size: 16, color: Colors.grey),
                if (msg.readBy.contains(peerUid))
                  const Icon(Icons.done_all, size: 16, color: Color(0xFF34B7F1)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Msg {
  final String text;
  final bool isMe;
  final TimeOfDay time;
  final bool delivered;            
  final List<String> readBy;       
  final bool isDeleted;            
  final String? imageUrl;         
  final String? localPath;         

  _Msg({
    required this.text,
    required this.isMe,
    required this.time,
    this.delivered = false,
    this.readBy = const [],
    this.isDeleted = false,
    this.imageUrl,
    this.localPath,
  });
}