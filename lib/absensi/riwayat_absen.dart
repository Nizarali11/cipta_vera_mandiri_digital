// lib/absensi/riwayat_absen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceRecord {
  final DateTime date;          // tanggal dibuat / hari absen
  final DateTime? checkInAt;    // waktu check-in
  final DateTime? checkOutAt;   // waktu check-out
  final double? lat;            // lokasi (opsional)
  final double? lon;
  final String? project;        // nama lokasi/proyek (opsional)
  final String? note;           // catatan (opsional)

  AttendanceRecord({
    required this.date,
    this.checkInAt,
    this.checkOutAt,
    this.lat,
    this.lon,
    this.project,
    this.note,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        checkInAt: j['checkInAt'] != null ? DateTime.tryParse(j['checkInAt']) : null,
        checkOutAt: j['checkOutAt'] != null ? DateTime.tryParse(j['checkOutAt']) : null,
        lat: (j['lat'] is num) ? (j['lat'] as num).toDouble() : null,
        lon: (j['lon'] is num) ? (j['lon'] as num).toDouble() : null,
        project: j['project'],
        note: j['note'],
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'checkInAt': checkInAt?.toIso8601String(),
        'checkOutAt': checkOutAt?.toIso8601String(),
        'lat': lat,
        'lon': lon,
        'project': project,
        'note': note,
      };
}

class AttendanceHistory {
  static const _key = 'attendance_history';
  static const Duration _retention = Duration(days: 30);

  /// Ambil semua riwayat (paling baru di atas)
  static Future<List<AttendanceRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final List list = jsonDecode(raw) as List;
    var items = list
        .map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Purge data yang lebih lama dari 30 hari (berdasarkan field `date`)
    final now = DateTime.now();
    final filtered = items.where((r) {
      final diff = now.difference(DateTime(r.date.year, r.date.month, r.date.day)).inDays;
      return diff <= _retention.inDays;
    }).toList();

    // Jika ada yang terhapus, simpan kembali hasil filter
    if (filtered.length != items.length) {
      await saveAll(filtered);
    }

    filtered.sort((a, b) => (b.checkInAt ?? b.date).compareTo(a.checkInAt ?? a.date));
    return filtered;
  }

  /// Simpan list riwayat (overwrite)
  static Future<void> saveAll(List<AttendanceRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// Tambah atau **merge** record berdasarkan tanggal (yyyy-MM-dd)
  /// - Jika sudah ada record di tanggal yang sama → update in/out/project/posisi (merge)
  /// - Jika belum ada → tambahkan baru
  static Future<void> saveRecord({
    required DateTime date,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    double? lat,
    double? lon,
    String? project,
    String? note,
  }) async {
    final items = await load();
    final keyDay = _dayKey(date);
    final idx = items.indexWhere((r) => _dayKey(r.date) == keyDay);

    if (idx >= 0) {
      final old = items[idx];
      items[idx] = AttendanceRecord(
        date: old.date,
        checkInAt: checkInAt ?? old.checkInAt,
        checkOutAt: checkOutAt ?? old.checkOutAt,
        lat: lat ?? old.lat,
        lon: lon ?? old.lon,
        project: project ?? old.project,
        note: note ?? old.note,
      );
    } else {
      items.add(AttendanceRecord(
        date: date,
        checkInAt: checkInAt,
        checkOutAt: checkOutAt,
        lat: lat,
        lon: lon,
        project: project,
        note: note,
      ));
    }
    await saveAll(items);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// =================== UI PAGE ===================

class _Section {
  final String title;
  final List<AttendanceRecord> items;
  const _Section(this.title, this.items);
}

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});
  static const routeName = '/attendance-history';

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  late Future<List<AttendanceRecord>> _future;

  int _weekOfMonth(DateTime d) {
    // 1..7 => 1, 8..14 => 2, 15..21 => 3, 22..end => 4
    final day = d.day;
    final w = ((day - 1) ~/ 7) + 1;
    return w > 4 ? 4 : w;
  }

  List<_Section> _buildSections(List<AttendanceRecord> items) {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    final today = <AttendanceRecord>[];
    final w1 = <AttendanceRecord>[];
    final w2 = <AttendanceRecord>[];
    final w3 = <AttendanceRecord>[];
    final w4 = <AttendanceRecord>[];

    for (final r in items) {
      final d0 = DateTime(r.date.year, r.date.month, r.date.day);
      if (d0 == todayKey) {
        today.add(r);
        continue; // jangan doble masuk minggu
      }
      if (r.date.month == now.month && r.date.year == now.year) {
        switch (_weekOfMonth(r.date)) {
          case 1:
            w1.add(r);
            break;
          case 2:
            w2.add(r);
            break;
          case 3:
            w3.add(r);
            break;
          default:
            w4.add(r);
        }
      }
    }

    List<_Section> secs = [];
    if (today.isNotEmpty) secs.add(_Section('Hari Ini', today));
    if (w1.isNotEmpty) secs.add(_Section('Minggu Pertama', w1));
    if (w2.isNotEmpty) secs.add(_Section('Minggu Kedua', w2));
    if (w3.isNotEmpty) secs.add(_Section('Minggu Ketiga', w3));
    if (w4.isNotEmpty) secs.add(_Section('Minggu Keempat', w4));
    return secs;
  }

  @override
  void initState() {
    super.initState();
    _future = AttendanceHistory.load();
  }

  void _refresh() {
    setState(() {
      _future = AttendanceHistory.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Riwayat Absen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
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
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Muat ulang',
          ),
          // (Opsional) hapus semua
          // IconButton(
          //   onPressed: () async {
          //     await AttendanceHistory.clearAll();
          //     _refresh();
          //   },
          //   icon: const Icon(Icons.delete_forever, color: Colors.white),
          //   tooltip: 'Hapus semua',
          // ),
        ],
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
          child: FutureBuilder<List<AttendanceRecord>>(
            future: _future,
            builder: (context, snap) {
              final items = snap.data ?? [];
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                            ),
                            child: const Text(
                              'Belum ada riwayat absen',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _PoweredBy(),
                    ],
                  ),
                );
              }
              final sections = _buildSections(items);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        for (final s in sections) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Text(
                              s.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          for (int i = 0; i < s.items.length; i++) ...[
                            _HistoryCard(rec: s.items[i]),
                            if (i != s.items.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _PoweredBy(),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
            ),
            child: const Text(
              'Belum ada riwayat absen',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _PoweredBy extends StatelessWidget {
  const _PoweredBy();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Powered by', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
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
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.rec});
  final AttendanceRecord rec;

  String _fmtDate(DateTime d) {
    // yyyy-MM-dd → DD/MM/YYYY singkat
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtTime(DateTime? d) {
    if (d == null) return '-';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final ci = rec.checkInAt;
    final co = rec.checkOutAt;
    final loc = (rec.lat != null && rec.lon != null) ? '${rec.lat!.toStringAsFixed(5)}, ${rec.lon!.toStringAsFixed(5)}' : '-';
    final proj = rec.project ?? '-';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _fmtDate(rec.date),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (ci != null && co != null) ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Text(
                    (ci != null && co != null) ? 'LENGKAP' : 'BELUM PULANG',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.login, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('Masuk: ${_fmtTime(ci)}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.logout, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('Pulang: ${_fmtTime(co)}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text('Lokasi: $loc')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text('Proyek: $proj')),
                      ],
                    ),
                    if ((rec.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(rec.note!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}