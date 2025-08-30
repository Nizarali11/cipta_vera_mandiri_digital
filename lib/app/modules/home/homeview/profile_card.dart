import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCard extends StatefulWidget {
  const ProfileCard({super.key});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  File? _fotoProfil;
  DateTime? _lastPhotoRefresh;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DateTime get _now => DateTime.now();
  DateTime get _monthStart => DateTime(_now.year, _now.month, 1);
  DateTime get _monthEnd => DateTime(_now.year, _now.month + 1, 1).subtract(const Duration(milliseconds: 1));
  int get _daysInThisMonth => DateTime(_now.year, _now.month + 1, 0).day;

  Stream<QuerySnapshot<Map<String, dynamic>>> _attendanceStream() {
    final uid = _uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    // Only filter by uid; month filtering will be done client-side to avoid index requirement
    return FirebaseFirestore.instance
        .collectionGroup('attendance')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _absenStream() {
    final uid = _uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collectionGroup('absen')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _userAttendanceDirectStream() {
    final uid = _uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    final uid = _uid;

    // Per-UID fixed filename (konsisten dengan Profile/Settings)
    final fixedPath = '${dir.path}/profile_${uid ?? 'local'}.jpg';

    // Prefer key per-UID yang kita pakai di tempat lain
    String? savedPath;
    if (uid != null) {
      savedPath = prefs.getString('fotoProfil_$uid');
    }

    // Backward compatibility: key lama & nama file lama
    savedPath ??= prefs.getString('fotoProfil');

    File? resolved;
    if (savedPath != null && File(savedPath).existsSync()) {
      resolved = File(savedPath);
    } else if (File(fixedPath).existsSync()) {
      // Legacy fixed path fallback
      resolved = File(fixedPath);
    }

    if (!mounted) return;
    setState(() {
      _fotoProfil = resolved;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // sedikit dikurangi supaya warna asli lebih terlihat
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[700]!.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for profile info and photo
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_uid)
                              .snapshots(),
                          builder: (context, snap) {
                            final data = snap.data?.data() ?? {};
                            final pin = (data['chatPin'] ?? '').toString();
                            final name = (data['name'] ?? '').toString();
                            final role = (data['role'] ?? '').toString();

                            // Trigger refresh of local photo path whenever user doc updates (realtime UI)
                            final nowTick = DateTime.now();
                            if (mounted && (_lastPhotoRefresh == null || nowTick.difference(_lastPhotoRefresh!) > const Duration(milliseconds: 600))) {
                              _lastPhotoRefresh = nowTick;
                              // Re-read SharedPreferences & local file path (per-UID) without blocking UI
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _loadProfilePhoto();
                              });
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // PIN
                                Text(
                                  pin.isNotEmpty ? pin : '-',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                // Nama (uppercase jika ada)
                                Text(
                                  name.isNotEmpty ? name.toUpperCase() : 'USER',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Role/Tim
                                Text(
                                  role.isNotEmpty ? 'Tim: $role' : 'Tim: -',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 80),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_uid)
                        .snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data() ?? {};
                      final fotoUrl = (data['fotoProfil'] ?? '').toString();

                      Widget child;
                      if (_fotoProfil != null) {
                        child = Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: FileImage(_fotoProfil!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } else if (fotoUrl.isNotEmpty) {
                        child = Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(fotoUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } else {
                        child = Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: const Icon(Icons.person, color: Colors.white54, size: 28),
                        );
                      }
                      return child;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _attendanceStream(),
                builder: (context, snapA) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _absenStream(),
                    builder: (context, snapB) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _userAttendanceDirectStream(),
                        builder: (context, snapC) {
                          int hadir = 0;
                          int izin = 0;
                          int cuti = 0;

                          Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docsA = snapA.data?.docs ?? const [];
                          Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docsB = snapB.data?.docs ?? const [];
                          Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docsC = snapC.data?.docs ?? const [];

                          for (final doc in [...docsA, ...docsB, ...docsC]) {
                            final data = doc.data();
                            // Ambil tanggal dan saring per-bulan (wajib ada tanggal)
                            DateTime? dt;
                            final v = data['date'] ?? data['createdAt'] ?? data['timestamp'] ?? data['time'];
                            if (v is Timestamp) dt = v.toDate();
                            if (v is int) dt = DateTime.fromMillisecondsSinceEpoch(v);
                            if (dt == null) {
                              continue; // tanpa tanggal, skip agar tidak salah hitung
                            }
                            if (dt.year != _now.year || dt.month != _now.month) {
                              continue;
                            }

                            // Normalisasi status: buang non-huruf supaya 'check-in' atau 'check_in' tetap terbaca
                            final raw = (data['status'] ?? data['type'] ?? data['kind'] ?? data['action'] ?? '').toString().toLowerCase();
                            final s = raw.replaceAll(RegExp(r'[^a-z]'), '');

                            if (s.contains('izin')) {
                              izin++;
                            } else if (s.contains('cuti')) {
                              cuti++;
                            } else if (s.contains('checkout') || s == 'out') {
                              // checkout tidak dihitung hadir
                            } else if (s.contains('checkin') || s.contains('hadir') || s == 'in' || s.contains('masuk')) {
                              hadir++;
                            }
                          }

                          final totalDays = _daysInThisMonth;
                          final progress = totalDays > 0 ? (hadir / totalDays).clamp(0.0, 1.0) : 0.0;

                          Widget _ringStat({
                            required String label,
                            required int value,
                            required int total,
                            required double progress,
                            required bool showTotal,
                          }) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircularProgressIndicator(
                                          value: 1,
                                          strokeWidth: 6,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.25)),
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 6,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                      Text(
                                        showTotal ? '$value/$total' : '$value',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            );
                          }
                          
                          final hadirProg = totalDays > 0 ? (hadir / totalDays).clamp(0.0, 1.0) : 0.0;
                          final izinProg  = totalDays > 0 ? (izin  / totalDays).clamp(0.0, 1.0) : 0.0;
                          final cutiProg  = totalDays > 0 ? (cuti  / totalDays).clamp(0.0, 1.0) : 0.0;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ringStat(label: 'IZIN', value: izin, total: totalDays, progress: izinProg, showTotal: false),
                              _ringStat(label: 'KEHADIRAN', value: hadir, total: totalDays, progress: hadirProg, showTotal: true),
                              _ringStat(label: 'CUTI', value: cuti, total: totalDays, progress: cutiProg, showTotal: false),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
                 const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  
  }
}
