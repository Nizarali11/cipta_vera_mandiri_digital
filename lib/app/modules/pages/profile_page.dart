import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

// Notifier global supaya halaman lain (mis. Settings) tahu ada perubahan profil secara real-time
ValueNotifier<int> profileChanged = ValueNotifier<int>(0);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String nama = "Nizar Ali";
  String tentang = "Sibuk";
  File? fotoProfil;
  bool _changed = false;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tentangController = TextEditingController();

  void _onProfileChanged() async {
    await _loadProfile();
    try {
      // Evict cached image for the fixed profile file so UI reloads fresh bytes
      final dir = await getApplicationDocumentsDirectory();
      final fixed = File('${dir.path}/profile.jpg');
      await FileImage(fixed).evict();
      if (fotoProfil != null) {
        await FileImage(fotoProfil!).evict();
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('nama');
    final savedAbout = prefs.getString('tentang');
    final savedPath = prefs.getString('fotoProfil');

    final dir = await getApplicationDocumentsDirectory();
    final fixedPath = '${dir.path}/profile.jpg';
    final fixedFile = File(fixedPath);

    if (kDebugMode) {
      debugPrint('[Profile] load: nama=$savedName tentang=$savedAbout path=$savedPath fixed=$fixedPath');
    }

    File? resolved;
    if (savedPath != null && File(savedPath).existsSync()) {
      resolved = File(savedPath);
    } else if (fixedFile.existsSync()) {
      // Fallback ke file tetap jika prefs kosong/invalid
      resolved = fixedFile;
      await prefs.setString('fotoProfil', fixedPath); // self-heal
      if (kDebugMode) debugPrint('[Profile] load: self-healed fotoProfil to fixed path');
    } else {
      // Tidak ada foto tersimpan
      if (savedPath != null) {
        await prefs.remove('fotoProfil');
        if (kDebugMode) debugPrint('[Profile] load: removed stale fotoProfil path from SharedPreferences');
      }
    }

    setState(() {
      nama = savedName ?? nama;
      tentang = savedAbout ?? tentang;
      fotoProfil = resolved;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', nama);
    await prefs.setString('tentang', tentang);
    if (fotoProfil != null) {
      await prefs.setString('fotoProfil', fotoProfil!.path);
    } else {
      await prefs.remove('fotoProfil');
    }
    _changed = true;
    profileChanged.value++;
    if (kDebugMode) {
      debugPrint('[Profile] saved: nama=$nama tentang=$tentang path=${fotoProfil?.path}');
    }
  }

  Future<File> _persistImage(File src) async {
    final dir = await getApplicationDocumentsDirectory();
    final String newPath = '${dir.path}/profile.jpg';
    final File dst = File(newPath);
    if (dst.existsSync()) {
      try { await dst.delete(); } catch (_) {}
    }
    return src.copy(newPath);
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    profileChanged.addListener(_onProfileChanged);
  }

  Future<void> _editField(String field) async {
    final controller = field == "Nama" ? _namaController : _tentangController;
    controller.text = field == "Nama" ? nama : tentang;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(foregroundColor: const Color.fromARGB(255, 13, 114, 198)),
                              child: const Text("Batal"),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  field,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, controller.text),
                             style: TextButton.styleFrom(foregroundColor: const Color.fromARGB(255, 13, 114, 198)),
                              child: const Text("Simpan"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: "Masukkan $field",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Silahkan masukkan $field Anda dengan benar.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (field == "Nama") {
          nama = result;
        } else {
          tentang = result;
        }
      });
      _saveProfile();
      _changed = true;
    }
  }


  void _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fixed = File('${dir.path}/profile.jpg');
      if (fixed.existsSync()) { await fixed.delete(); }
      if (fotoProfil != null && fotoProfil!.existsSync()) { await fotoProfil!.delete(); }
      try {
        await FileImage(fixed).evict();
        if (fotoProfil != null) {
          await FileImage(fotoProfil!).evict();
        }
      } catch (_) {}
    } catch (_) {}

    setState(() {
      fotoProfil = null;
    });
    await prefs.remove('fotoProfil');
    await _saveProfile();
    _changed = true;
  }

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.3,
              minChildSize: 0.2,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Edit foto profil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text("Pilih foto"),
                                trailing: const Icon(Icons.photo),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(source: ImageSource.gallery);

                                  if (picked != null) {
                                    final cropped = await ImageCropper().cropImage(
                                      sourcePath: picked.path,
                                      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                                      uiSettings: [
                                        AndroidUiSettings(
                                          toolbarTitle: 'Atur Foto Profil',
                                          toolbarColor: Colors.black,
                                          toolbarWidgetColor: Colors.white,
                                          initAspectRatio: CropAspectRatioPreset.square,
                                          lockAspectRatio: true,
                                        ),
                                        IOSUiSettings(
                                          title: 'Atur Foto Profil',
                                          aspectRatioLockEnabled: true,
                                        ),
                                      ],
                                    );

                                    if (cropped != null) {
                                      final File tempFile = File(cropped.path);
                                      final File persisted = await _persistImage(tempFile); // always profile.jpg

                                      try {
                                        if (fotoProfil != null) {
                                          // Evict old image from cache
                                          await FileImage(fotoProfil!).evict();
                                        }
                                        // Also evict the new fixed path to force reload of fresh bytes
                                        await FileImage(persisted).evict();
                                      } catch (_) {}

                                      setState(() => fotoProfil = persisted);
                                      await _saveProfile(); // will store fixed path
                                    }
                                  }
                                },
                              ),
                              if (fotoProfil != null) ...[
                                ListTile(
                                  title: const Text(
                                    "Hapus foto",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  trailing: const Icon(Icons.delete, color: Colors.red),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _removeImage();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
         
          title: const Text(
            'Profil',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 51, 51, 51),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              const SizedBox(height: 0),
              // Profile picture and edit
              Center(
                child: Column(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: profileChanged,
                      builder: (_, __, ___) {
                        final img = fotoProfil;
                        if (img != null) {
                          return ClipOval(
                            child: Image.file(
                              img,
                              key: ValueKey(profileChanged.value), // bust cache on change
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 56,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _showPhotoOptions,
                         style: TextButton.styleFrom(foregroundColor: const Color.fromARGB(255, 13, 114, 198)),
                          label: const Text("Edit"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Info section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama
                    const Text(
                      'Nama',
                      style: TextStyle(
                        color: Color.fromARGB(255, 51, 51, 51),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 51, 51, 51),
                          ),
                        ),
                        trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        dense: true,
                        onTap: () => _editField("Nama"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tentang
                    const Text(
                      'Tentang',
                      style: TextStyle(
                        color: Color.fromARGB(255, 51, 51, 51),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          tentang,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 51, 51, 51),
                          ),
                        ),
                        trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        dense: true,
                        onTap: () => _editField("Tentang"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // PIN
                    const Text(
                      'PIN',
                      style: TextStyle(
                        color: Color.fromARGB(255, 51, 51, 51),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const ListTile(
                        title: Text(
                          '243893743N',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 51, 51, 51),
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        dense: true,
                      ),
                    ),
                  
                      
                    
                  ],
                ),
              ),
              // Removed Spacer
              // Bottom navigation bar
             
            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    profileChanged.removeListener(_onProfileChanged);
    _namaController.dispose();
    _tentangController.dispose();
    super.dispose();
  }
}