// ================= Absen Kehadiran Page =================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/bindings/shared_preferences.dart';
import 'package:cipta_vera_mandiri_digital/absensi/riwayat_absen.dart';

enum _InStep { selfie, location, backPhoto, confirm }

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  static const routeName = '/attendance';

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime? checkInAt;
  DateTime? checkOutAt;

  // --- Check-in requirements ---
  File? _inSelfie;
  File? _inBackPhoto;
  Position? _inPos;

  // --- Wizard step for Check-in ---
  _InStep _inStep = _InStep.selfie;
  bool _stateLoaded = false;

  // --- Check-out requirements ---
  File? _outSelfie;
  File? _outBackPhoto;
  Position? _outPos;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _projectController = TextEditingController();

  void _loadPersistedState() {
    checkInAt = AppPreferences.checkInAt;
    checkOutAt = AppPreferences.checkOutAt;
    if (checkInAt != null && checkOutAt == null) {
      _inStep = _InStep.confirm; // tetap di konfirmasi jika sudah check-in
    } else {
      _inStep = _InStep.selfie;  // mulai ulang jika belum check-in / sudah check-out
    }
    _stateLoaded = true;
    if (mounted) setState(() {});
  }

  Future<void> _persistState() async {
    await AppPreferences.setCheckIn(checkInAt);
    await AppPreferences.setCheckOut(checkOutAt);
  }

  bool get _canCheckIn => _inSelfie != null && _inPos != null && _inBackPhoto != null;
  bool get _canCheckOut => _outSelfie != null && _outPos != null && _outBackPhoto != null;

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<void> _captureSelfie({required bool isIn}) async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, preferredCameraDevice: CameraDevice.front);
    if (x == null) return;
    setState(() {
      if (isIn) {
        _inSelfie = File(x.path);
      } else {
        _outSelfie = File(x.path);
      }
    });
  }

  Future<void> _captureBackPhoto({required bool isIn}) async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, preferredCameraDevice: CameraDevice.rear);
    if (x == null) return;
    setState(() {
      if (isIn) {
        _inBackPhoto = File(x.path);
      } else {
        _outBackPhoto = File(x.path);
      }
    });
  }

  Future<void> _captureLocation({required bool isIn}) async {
    final ok = await _ensureLocationPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktifkan lokasi & beri izin aplikasi.')),
      );
      return;
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      if (isIn) {
        _inPos = pos;
      } else {
        _outPos = pos;
      }
    });
  }

  String _fmt(DateTime dt) => dt.toLocal().toString().split('.').first;

  void _nextInStep() {
    setState(() {
      if (_inStep == _InStep.selfie) {
        _inStep = _InStep.location;
      } else if (_inStep == _InStep.location) {
        _inStep = _InStep.backPhoto;
      } else if (_inStep == _InStep.backPhoto) {
        _inStep = _InStep.confirm;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  // Glass panel helper for glassmorphism UI panels
  Widget _glassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    double radius = 16,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  // Glass toggle chip helper for location/project selection
  Widget _glassChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: (selected ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) const Icon(Icons.check, size: 16, color: Colors.white),
                if (selected) const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inSelfieView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Vertical space above the selfie circle
        const SizedBox(height: 80),
        // Lingkaran selfie di atas dengan efek glass
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
                image: _inSelfie != null
                    ? DecorationImage(
                        image: FileImage(_inSelfie!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _inSelfie == null
                  ? const Icon(Icons.face_retouching_natural, size: 120, color: Colors.white)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Pusatkan wajah Anda',
          style: TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        if (_inSelfie != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Selfie sudah diambil ✅',
            style: TextStyle(color: Colors.white),
          ),
        ],
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
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
                        onPressed: () => _captureSelfie(isIn: true),
                        icon: const Icon(Icons.photo_camera_front, color: Colors.white),
                        label: const Text('Ambil Selfie', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
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
                        onPressed: _inSelfie != null ? _nextInStep : null,
                        child: const Text('Lanjut', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inLocationView() {
    final lat = _inPos?.latitude.toStringAsFixed(5);
    final lon = _inPos?.longitude.toStringAsFixed(5);
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
                    _inPos == null ? 'Belum ada lokasi' : 'Lat: $lat, Lon: $lon',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text('Pastikan titik lokasi sudah tepat', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _glassPanel(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Lokasi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _glassChoice(
                    label: 'Kantor',
                    selected: _projectController.text == 'Kantor',
                    onTap: () {
                      setState(() {
                        _projectController.text = 'Kantor';
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _glassChoice(
                    label: 'Proyek',
                    selected: _projectController.text.isNotEmpty && _projectController.text != 'Kantor',
                    onTap: () {
                      setState(() {
                        _projectController.clear();
                      });
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          final tempController = TextEditingController(text: _projectController.text);
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Nama Proyek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                                            ),
                                            child: TextField(
                                              controller: tempController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                hintText: 'Masukkan nama proyek',
                                                hintStyle: TextStyle(color: Colors.white70),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _glassButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              label: 'Batal',
                                              expand: true,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _glassButton(
                                              onPressed: () {
                                                setState(() {
                                                  _projectController.text = tempController.text.trim();
                                                });
                                                Navigator.of(ctx).pop();
                                              },
                                              label: 'Simpan',
                                              expand: true,
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
                    },
                  ),
                ],
              ),
              if (_projectController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Lokasi: ${_projectController.text}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
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
                        onPressed: () => _captureLocation(isIn: true),
                        icon: const Icon(Icons.gps_fixed, color: Colors.white),
                        label: const Text('Ambil Lokasi', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
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
                        onPressed: _inPos != null ? _nextInStep : null,
                        child: const Text('Lanjut', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inBackPhotoView() {
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
              child: _inBackPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _inBackPhoto!,
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
        if (_inBackPhoto != null)
          const Text(
            'Foto lokasi sudah diambil ✅',
            style: TextStyle(color: Colors.white),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
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
                        onPressed: () => _captureBackPhoto(isIn: true),
                        icon: const Icon(Icons.photo_camera_back, color: Colors.white),
                        label: const Text('Ambil Foto', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
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
                        onPressed: _inBackPhoto != null ? _nextInStep : null,
                        child: const Text('Lanjut', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inConfirmView() {
    final lat = _inPos?.latitude.toStringAsFixed(5);
    final lon = _inPos?.longitude.toStringAsFixed(5);
    Widget confirmRow({required IconData icon, required String label, required bool ok}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.greenAccent : Colors.redAccent, size: 22),
          const SizedBox(width: 8),
          Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Konfirmasi Check-in',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 12),
          confirmRow(
            icon: Icons.face_retouching_natural,
            label: _inSelfie != null ? 'Selfie OK' : 'Selfie kosong',
            ok: _inSelfie != null,
          ),
          const SizedBox(height: 6),
          confirmRow(
            icon: Icons.my_location,
            label: _inPos != null ? 'Lokasi: $lat, $lon' : 'Lokasi kosong',
            ok: _inPos != null,
          ),
          const SizedBox(height: 6),
          confirmRow(
            icon: Icons.photo_camera_back,
            label: _inBackPhoto != null ? 'Foto lokasi OK' : 'Foto lokasi kosong',
            ok: _inBackPhoto != null,
          ),
          const SizedBox(height: 16),
          _glassButton(
            onPressed: _canCheckIn && checkInAt == null
                ? () async {
                    setState(() {
                      checkInAt = DateTime.now();
                      _inStep = _InStep.confirm;
                    });
                    await _persistState();

                    // Save check-in to Firestore
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('attendance').add({
                        'uid': user.uid,
                        'type': 'checkin',
                        'timestamp': checkInAt,
                        'latitude': _inPos?.latitude,
                        'longitude': _inPos?.longitude,
                        'selfiePath': _inSelfie?.path,
                        'backPhotoPath': _inBackPhoto?.path,
                        'project': _projectController.text,
                      });
                    }

                    // Save to local Riwayat Absen (SharedPreferences)
                    await AttendanceHistory.saveRecord(
                      date: DateTime.now(),
                      checkInAt: checkInAt,
                      lat: _inPos?.latitude,
                      lon: _inPos?.longitude,
                      project: _projectController.text.isNotEmpty ? _projectController.text : null, // isi nama proyek jika ada variabelnya
                      note: 'Check-in dari aplikasi',
                    );
                  }
                : null,
            label: checkInAt == null ? 'Absen (Check-in)' : 'Anda sudah terabsen',
            expand: true,
          ),
        ],
      ),
    );
  }

  // Glass button helper, similar to _confirmStep
  Widget _glassButton({required VoidCallback? onPressed, required String label, bool expand = false}) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
    if (expand) {
      return SizedBox(width: double.infinity, child: btn);
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
          'Absen Kehadiran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF2196F3), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _stateLoaded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 100),
                            Row(
                              children: const [
                                Icon(Icons.login, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Kehadiran',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 0),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: () {
                                  switch (_inStep) {
                                    case _InStep.selfie:
                                      return _inSelfieView();
                                    case _InStep.location:
                                      return _inLocationView();
                                    case _InStep.backPhoto:
                                      return _inBackPhotoView();
                                    case _InStep.confirm:
                                      return _inConfirmView();
                                  }
                                }(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // The "Buka Check-out" button has been removed as requested.
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
 