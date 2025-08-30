import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Halaman daftar semua Pesan Berbintang untuk satu chat.
///
/// Beri salah satu dari [chatId] atau [peerUid]. Jika [chatId] null,
/// halaman akan mencoba resolve berdasarkan kombinasi uid saat ini + peerUid.
class StarredMessagesPage extends StatefulWidget {
  final String? chatId;
  final String? peerUid;
  final String? peerName;

  const StarredMessagesPage({Key? key, this.chatId, this.peerUid, this.peerName}) : super(key: key);

  @override
  State<StarredMessagesPage> createState() => _StarredMessagesPageState();
}

class _StarredMessagesPageState extends State<StarredMessagesPage> {
  String? _resolvedChatId;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _ensureChatId();
  }

  Future<void> _ensureChatId() async {
    if (_resolvedChatId != null) return;
    setState(() => _resolving = true);
    final cid = await _resolveChatId(widget.chatId, widget.peerUid);
    if (!mounted) return;
    setState(() {
      _resolvedChatId = cid;
      _resolving = false;
    });
  }

  Future<String?> _resolveChatId(String? chatId, String? peerUid) async {
    if (chatId != null && chatId.isNotEmpty) return chatId;
    final my = FirebaseAuth.instance.currentUser?.uid;
    if (my == null || peerUid == null || peerUid.isEmpty) return null;
    // urutkan supaya konsisten
    final a = my.compareTo(peerUid) <= 0 ? my : peerUid;
    final b = my.compareTo(peerUid) <= 0 ? peerUid : my;
    final id1 = '${a}_$b';
    final id2 = '${b}_$a';
    final chats = FirebaseFirestore.instance.collection('chats');
    final d1 = await chats.doc(id1).get();
    if (d1.exists) return id1;
    final d2 = await chats.doc(id2).get();
    if (d2.exists) return id2;
    // fallback: pakai id1 (biar tetap tampil jika koleksi belum dibuat)
    return id1;
  }

  @override
  Widget build(BuildContext context) {
    final hasPeer = (widget.peerName != null && widget.peerName!.trim().isNotEmpty);
    final titleText = hasPeer ? 'Pesan Berbintang • ${widget.peerName}' : 'Pesan Berbintang';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          child: _resolving
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : (_resolvedChatId == null
                  ? _emptyState('Chat belum ditemukan')
                  : _StarredList(chatId: _resolvedChatId!, myUid: FirebaseAuth.instance.currentUser?.uid ?? '')),
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_border, color: Colors.white70, size: 48),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _StarredList extends StatelessWidget {
  final String chatId;
  final String myUid;
  const _StarredList({Key? key, required this.chatId, required this.myUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseCol = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    if (myUid.isEmpty) {
      return const Center(
        child: Text('Silakan login ulang untuk melihat pesan berbintang', style: TextStyle(color: Colors.white70)),
      );
    }
    final stream = baseCol.where('starredBy', arrayContains: myUid).snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final docs = snapshot.data?.docs ?? [];
        final sorted = [...docs];
        sorted.sort((a, b) {
          final am = a.data();
          final bm = b.data();
          final at = am['starredAt'] ?? am['createdAt'] ?? am['ts'];
          final bt = bm['starredAt'] ?? bm['createdAt'] ?? bm['ts'];
          DateTime ad, bd;
          if (at is Timestamp) ad = at.toDate(); else if (at is DateTime) ad = at; else ad = DateTime.fromMillisecondsSinceEpoch(0);
          if (bt is Timestamp) bd = bt.toDate(); else if (bt is DateTime) bd = bt; else bd = DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });
        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star_border, color: Colors.white70, size: 48),
                SizedBox(height: 8),
                Text('Belum ada pesan berbintang', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final m = sorted[index].data();
            final text = (m['text'] ?? m['message'] ?? '').toString();
            final type = (m['type']
                  ?? (m['imageUrl'] != null || m['photoUrl'] != null ? 'image'
                      : (m['fileUrl'] != null || m['url'] != null ? 'file' : 'text')))
                .toString();
            DateTime? t;
            final rawTs = m['ts'] ?? m['createdAt'];
            if (rawTs is Timestamp) t = rawTs.toDate();
            else if (rawTs is DateTime) t = rawTs;
            final timeStr = _fmt(t);

            final List deletedFor = (m['deletedFor'] ?? []) as List;
            final isDeleted = (m['isDeleted'] ?? false) == true;
            if (isDeleted || (myUid.isNotEmpty && deletedFor.contains(myUid))) {
              return const SizedBox.shrink();
            }

            return _glassCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: Icon(
                  type == 'image'
                      ? Icons.photo
                      : type == 'file'
                          ? Icons.insert_drive_file
                          : Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
                title: Text(
                  type == 'text' ? (text.isEmpty ? '[teks kosong]' : text) : '[${type.toUpperCase()}]',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: timeStr == null
                    ? null
                    : Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  onPressed: () async {
                    // Toggle off bintang
                    try {
                      await sorted[index].reference.set({
                        'starredBy': FieldValue.arrayRemove([myUid]),
                        // opsional bersihkan timestamp bintang jika kosong nanti
                      }, SetOptions(merge: true));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menghapus bintang: $e')),
                      );
                    }
                  },
                ),
                onTap: () {
                  // TODO: bisa navigasi ke pesan di ChatPage
                },
              ),
            );
          },
        );
      },
    );
  }

  static String? _fmt(DateTime? dt) {
    if (dt == null) return null;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $hh:$mm';
  }
}

Widget _glassCard({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
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
