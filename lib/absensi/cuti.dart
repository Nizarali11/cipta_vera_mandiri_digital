import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});
  static const routeName = '/leave';

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? startDate;
  DateTime? endDate;
  final reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassButton({required VoidCallback? onPressed, required String label, IconData? icon}) {
    final btn = ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.28),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return btn;
  }

  int _daySpan(DateTime a, DateTime b) {
    final aa = DateTime(a.year, a.month, a.day);
    final bb = DateTime(b.year, b.month, b.day);
    return bb.difference(aa).inDays.abs() + 1; // inclusive
  }

  Future<void> _submitCuti() async {
    if (!_formKey.currentState!.validate() || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data cuti terlebih dahulu')),
      );
      return;
    }

    // validasi urutan tanggal
    DateTime s = startDate!;
    DateTime e = endDate!;
    if (e.isBefore(s)) {
      // tukar jika user memilih terbalik
      final tmp = s; s = e; e = tmp;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harus login terlebih dahulu')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final data = {
        'uid': user.uid,
        'status': 'cuti',                 // dibaca indikator
        'type': 'cuti',                   // kompat parser lain
        'date': Timestamp.fromDate(s),    // dipakai filter bulan berjalan (ambil tanggal mulai)
        'createdAt': Timestamp.fromDate(now),
        'time': now.millisecondsSinceEpoch,
        'reason': reasonCtrl.text.trim(),
        'startDateText': s.toIso8601String().split('T').first,
        'endDateText': e.toIso8601String().split('T').first,
        'startEpoch': DateTime(s.year, s.month, s.day).millisecondsSinceEpoch,
        'endEpoch': DateTime(e.year, e.month, e.day).millisecondsSinceEpoch,
        'days': _daySpan(s, e),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .add(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuti berhasil diajukan')),
      );
      // Opsional: reset form
      setState(() {
        startDate = null;
        endDate = null;
        reasonCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan cuti: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Pengajuan Cuti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('Lengkapi Data Cuti', style: titleStyle.copyWith(fontSize: 18)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tanggal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _glassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: ListTile(
                                  leading: const Icon(Icons.date_range, color: Colors.white),
                                  title: Text(
                                    startDate == null
                                        ? 'Tanggal mulai'
                                        : 'Mulai: ${startDate!.toLocal().toString().split(' ').first}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () => _pickDate(isStart: true),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _glassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: ListTile(
                                  leading: const Icon(Icons.event, color: Colors.white),
                                  title: Text(
                                    endDate == null
                                        ? 'Tanggal selesai'
                                        : 'Selesai: ${endDate!.toLocal().toString().split(' ').first}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () => _pickDate(isStart: false),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alasan Cuti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: reasonCtrl,
                                maxLines: 4,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Tuliskan alasan cuti Anda',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  _glassButton(
                    onPressed: _saving ? null : _submitCuti,
                    label: _saving ? 'Mengirim…' : 'Ajukan Cuti',
                    icon: Icons.send,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
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
                    ),
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
