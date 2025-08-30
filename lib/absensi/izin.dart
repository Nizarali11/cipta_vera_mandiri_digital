// ================= Izin Page =================
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});
  static const routeName = '/permission';

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final _formKey = GlobalKey<FormState>();
  final reasonCtrl = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool _saving = false;

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _submitIzin() async {
    if (!_formKey.currentState!.validate() || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data izin terlebih dahulu')),
      );
      return;
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
        'status': 'izin',                 // dibaca indikator
        'type': 'izin',                   // kompatibel parser lain
        'date': Timestamp.fromDate(now),  // dibaca indikator (bulan berjalan)
        'createdAt': Timestamp.fromDate(now),
        'time': now.millisecondsSinceEpoch,
        'reason': reasonCtrl.text.trim(),
        'startTimeText': startTime!.format(context),
        'endTimeText': endTime!.format(context),
        'startMinutes': _toMinutes(startTime!),
        'endMinutes': _toMinutes(endTime!),
      };

      // Simpan di subkoleksi agar collectionGroup('attendance') menangkapnya
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .add(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin berhasil diajukan')),
      );
      // opsional: kembali atau reset
      // Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan izin: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
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
    return ClipRRect(
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
        title: const Text('Form Izin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                  const Text('Lengkapi Data Izin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _glassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: ListTile(
                                  leading: const Icon(Icons.access_time, color: Colors.white),
                                  title: Text(
                                    startTime == null ? 'Jam mulai' : 'Mulai: ${startTime!.format(context)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () => _pickTime(isStart: true),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _glassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: ListTile(
                                  leading: const Icon(Icons.timer_off, color: Colors.white),
                                  title: Text(
                                    endTime == null ? 'Jam selesai' : 'Selesai: ${endTime!.format(context)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () => _pickTime(isStart: false),
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
                              const Text('Alasan Izin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: reasonCtrl,
                                maxLines: 4,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Tuliskan alasan izin Anda',
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
                    onPressed: _saving ? null : _submitIzin,
                    label: _saving ? 'Mengirim…' : 'Ajukan Izin',
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
