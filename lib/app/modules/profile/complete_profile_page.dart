import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cipta_vera_mandiri_digital/app/services/chat_pin_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:ui' show ImageFilter;

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({Key? key}) : super(key: key);

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  File? _imageFile;
  bool _loading = false;
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadExistingLocalPhoto();
    _loadPin();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLocalPhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final prefs = await SharedPreferences.getInstance();
      final key = 'profile_photo_${user.uid}';
      final path = prefs.getString(key);
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        setState(() {
          _localPhotoPath = path;
          _imageFile = File(path);
        });
      }
    } catch (e) {
      debugPrint('Gagal load foto lokal: $e');
    }
  }

  Future<void> _loadPin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Cek PIN yang sudah ada
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String? pin = doc.data()?['chatPin'] as String?;

      // Jika belum ada, generate & klaim unik
      if (pin == null || pin.isEmpty) {
        pin = await ChatPinService.generateUniquePin(user.uid);
      }

      if (!mounted) return;
      setState(() {
        _pinController.text = pin!;
      });
    } catch (e) {
      debugPrint('Gagal memuat/ generate PIN: $e');
    }
  }

  Future<void> _pickFrom(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      // Crop image setelah dipilih
      CroppedFile? cropped;
      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Foto',
              toolbarColor: Color(0xFF007BC1),
              toolbarWidgetColor: Colors.white,
              hideBottomControls: false,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Foto',
              aspectRatioLockEnabled: false,
            ),
          ],
        );
      } catch (e) {
        debugPrint('Crop gagal: $e');
      }

      if (!mounted) return;
      setState(() {
        _imageFile = File((cropped?.path) ?? picked.path);
      });
    }
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFrom(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _saveLocalPhoto(File source, String uid) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final destPath = '${dir.path}/profile_$uid.jpg';
      final destFile = File(destPath);
      await source.copy(destFile.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_$uid', destFile.path);

      return destFile.path;
    } catch (e) {
      debugPrint('Gagal simpan foto lokal: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final role = _roleController.text.trim();
      if (role.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role wajib diisi')),
          );
        }
        setState(() { _loading = false; });
        return;
      }

      String? savedLocal;
      if (_imageFile != null) {
        savedLocal = await _saveLocalPhoto(_imageFile!, user.uid);
        if (savedLocal != null) {
          setState(() { _localPhotoPath = savedLocal; });
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'role': role,
        // Tidak mengupload ke Firebase Storage; simpan lokal di perangkat saja
        if (_localPhotoPath != null) 'photoLocalPath': _localPhotoPath,
        'hasLocalPhoto': _localPhotoPath != null,
        'email': user.email,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint('Error simpan profil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _glassField(
    String hint,
    IconData icon,
    TextEditingController ctrl, {
    String? Function(String?)? validator,
    bool obscure = false,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: hint.toLowerCase() == 'email' ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      readOnly: readOnly,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
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
          'Lengkapi Data Diri Anda',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: Colors.white.withOpacity(0.15),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 32,
              right: 32,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 90),

                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.person, size: 56, color: Colors.white)
                            : null,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _loading ? null : _pickImage,
                          icon: const Icon(Icons.edit, color: Colors.black87),
                          tooltip: 'Ganti foto',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 0),
                  // Tombol kamera & galeri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Kamera (glass button)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 140,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.32),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.2,
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: _loading ? null : () => _pickFrom(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera, color: Colors.white),
                              label: const Text(
                                'Kamera',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                       const SizedBox(height: 100),
                      // Galeri (glass button)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 140,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.32),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.2,
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: _loading ? null : () => _pickFrom(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, color: Colors.white),
                              label: const Text(
                                'Galeri',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 0),

                  // Heading di atas form
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Masukan data diri :',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nama Lengkap
                  _glassField(
                    'Nama Lengkap',
                    Icons.person,
                    _nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),

                  const SizedBox(height: 10),
                  // Role
                  _glassField(
                    'Role (Pemberkasan/Karyawan/IT/Keuangan)',
                    Icons.badge_outlined,
                    _roleController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Role wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  // PIN (read-only, auto-generated)
                  _glassField(
                    'PIN (otomatis)',
                    Icons.vpn_key,
                    _pinController,
                    readOnly: true,
                    enabled: false,
                  ),

                  const SizedBox(height: 50),
                  // Tombol Simpan (match Sign Up style)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 220,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.32),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.2,
                          ),
                        ),
                        child: TextButton(
                          onPressed: _loading ? null : _saveProfile,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 70),
                      Text(
                        'Powered by',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('lib/app/assets/images/cvm.png', height: 20),
                          const SizedBox(width: 6),
                          const Text(
                            'Cipta Vera Mandiri Digital',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                    ],
                  ),
                  const SizedBox(height: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
