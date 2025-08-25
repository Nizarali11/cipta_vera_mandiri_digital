// ================= Absen Check-out Page (Terpisah) =================
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cipta_vera_mandiri_digital/absensi/riwayat_absen.dart';

enum _OutStep { selfie, location, backPhoto, confirm }

class AttendanceCheckoutPage extends StatefulWidget {
  const AttendanceCheckoutPage({super.key});

  @override
  State<AttendanceCheckoutPage> createState() => _AttendanceCheckoutPageState();
}

class _AttendanceCheckoutPageState extends State<AttendanceCheckoutPage> {
  DateTime? checkOutAt;

  // Syarat check-out
  File? _outSelfie;
  File? _outBackPhoto;
  Position? _outPos;

  final ImagePicker _picker = ImagePicker();
  _OutStep _step = _OutStep.selfie;

  bool get _canCheckOut => _outSelfie != null && _outPos != null && _outBackPhoto != null;

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _captureSelfie() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (x == null) return;
    setState(() => _outSelfie = File(x.path));
  }

  Future<void> _captureBackPhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (x == null) return;
    setState(() => _outBackPhoto = File(x.path));
  }

  Future<void> _captureLocation() async {
    final ok = await _ensureLocationPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktifkan lokasi & beri izin aplikasi.')),
      );
      return;
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _outPos = pos);
  }

  void _nextStep() {
    setState(() {
      switch (_step) {
        case _OutStep.selfie:
          _step = _OutStep.location;
          break;
        case _OutStep.location:
          _step = _OutStep.backPhoto;
          break;
        case _OutStep.backPhoto:
          _step = _OutStep.confirm;
          break;
        case _OutStep.confirm:
          break;
      }
    });
  }

  // -------------------- STEP UI --------------------

  Widget _selfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        ClipRRect(
          borderRadius: BorderRadius.circular(110),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
                image: _outSelfie != null
                    ? DecorationImage(image: FileImage(_outSelfie!), fit: BoxFit.cover)
                    : null,
              ),
              child: _outSelfie == null
                  ? const Icon(Icons.face_retouching_natural, size: 120, color: Colors.white)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Selfie (kamera depan)', style: TextStyle(color: Colors.white)),
        if (_outSelfie != null) ...[
          const SizedBox(height: 8),
          const Text('Selfie sudah diambil ✅', style: TextStyle(color: Colors.white)),
        ],
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _glassButtonIcon(
                onPressed: _captureSelfie,
                icon: Icons.photo_camera_front,
                label: 'Ambil Selfie',
                expand: true,
              ),
              const SizedBox(width: 12),
              _glassButton(
                onPressed: _outSelfie != null ? _nextStep : null,
                label: 'Lanjut',
                expand: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationStep() {
    final lat = _outPos?.latitude.toStringAsFixed(5);
    final lon = _outPos?.longitude.toStringAsFixed(5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.my_location, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _outPos == null ? 'Belum ada lokasi' : 'Lat: $lat, Lon: $lon',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text('Pastikan titik lokasi sudah tepat', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _glassButtonIcon(
                onPressed: _captureLocation,
                icon: Icons.gps_fixed,
                label: 'Ambil Lokasi',
                expand: true,
              ),
              const SizedBox(width: 12),
              _glassButton(
                onPressed: _outPos != null ? _nextStep : null,
                label: 'Lanjut',
                expand: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              alignment: Alignment.center,
              child: _outBackPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _outBackPhoto!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.photo_camera_back_outlined, size: 64, color: Colors.white),
                        SizedBox(height: 8),
                        Text('Ambil foto lokasi (kamera belakang)', style: TextStyle(color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_outBackPhoto != null)
          const Text(
            'Foto lokasi sudah diambil ✅',
            style: TextStyle(color: Colors.white),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _glassButtonIcon(
                onPressed: _captureBackPhoto,
                icon: Icons.photo_camera_back,
                label: 'Ambil Foto',
                expand: true,
              ),
              const SizedBox(width: 12),
              _glassButton(
                onPressed: _outBackPhoto != null ? _nextStep : null,
                label: 'Lanjut',
                expand: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _confirmStep() {
    final lat = _outPos?.latitude.toStringAsFixed(5);
    final lon = _outPos?.longitude.toStringAsFixed(5);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Konfirmasi Check-out',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 12),
        _confirmRow(ok: _outSelfie != null, text: 'Selfie OK'),
        const SizedBox(height: 6),
        _confirmRow(ok: _outPos != null, text: _outPos != null ? 'Lokasi: $lat, $lon' : 'Lokasi kosong'),
        const SizedBox(height: 6),
        _confirmRow(ok: _outBackPhoto != null, text: 'Foto lokasi OK'),
        const SizedBox(height: 16),

        // Tombol full width with spacing from bottom
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: SizedBox(
            width: double.infinity,
            child: _glassButton(
              onPressed: _canCheckOut && checkOutAt == null
                  ? () async {
                      final now = DateTime.now();
                      setState(() {
                        checkOutAt = now;
                      });

                      // Save to Firestore
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('attendance').add({
                          'uid': user.uid,
                          'type': 'checkout',
                          'timestamp': now,
                          'latitude': _outPos?.latitude,
                          'longitude': _outPos?.longitude,
                          'selfiePath': _outSelfie?.path,
                          'backPhotoPath': _outBackPhoto?.path,
                        });
                      }

                      // Save to local Riwayat
                      await AttendanceHistory.saveRecord(
                        date: now,
                        checkOutAt: now,
                        lat: _outPos?.latitude,
                        lon: _outPos?.longitude,
                        project: null,
                        note: 'Check-out dari aplikasi',
                      );
                    }
                  : null,
              label: checkOutAt == null ? 'Pulang (Check-out)' : 'Anda sudah absen pulang',
              expand: false,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------- Helpers UI --------------------

  Widget _confirmRow({required bool ok, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(ok ? Icons.check : Icons.close, color: ok ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _glassButton({required VoidCallback? onPressed, required String label, bool expand = true}) {
    final btn = ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
    if (expand) {
      return Expanded(child: btn);
    }
    return btn;
  }

  Widget _glassButtonIcon({required VoidCallback? onPressed, required IconData icon, required String label, bool expand = false}) {
    final btn = ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            label: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
    if (expand) {
      return Expanded(child: btn);
    }
    return btn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(
          'Absen Kepulangan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: const Border(
                  bottom: BorderSide(color: Colors.white24, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF2196F3), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Row(
                children: const [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Pulang',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 0),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: () {
                  switch (_step) {
                    case _OutStep.selfie:
                      return _selfieStep();
                    case _OutStep.location:
                      return _locationStep();
                    case _OutStep.backPhoto:
                      return _backPhotoStep();
                    case _OutStep.confirm:
                      return _confirmStep();
                  }
                }(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}