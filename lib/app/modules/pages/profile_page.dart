import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String pin = ""; // diisi dari data saat lengkap data diri / signup
  String role = ""; // disinkron dari Lengkapi Data Diri
  String chatName = ""; // Nama tampilan untuk chat (editable)
  File? fotoProfil;
  bool _changed = false;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tentangController = TextEditingController();
  final TextEditingController _chatNameController = TextEditingController();

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
    final savedChatName = prefs.getString('chatName');
    String? savedPin =
        prefs.getString('userPin') ??
        prefs.getString('generatedPin') ??
        prefs.getString('cvPin') ??
        prefs.getString('cv_pin') ??
        prefs.getString('cvNumber') ??
        prefs.getString('cv_number') ??
        prefs.getString('cvID') ??
        prefs.getString('cv_id') ??
        prefs.getString('pin') ??
        prefs.getString('user_pin');
    if (savedPin != null) {
      savedPin = savedPin.trim().toUpperCase();
    }
    if (kDebugMode) {
      debugPrint('[Profile] loadPin: $savedPin');
    }

    final savedRole =
        prefs.getString('role') ??
        prefs.getString('userRole') ??
        prefs.getString('user_role') ??
        prefs.getString('jabatan') ??
        prefs.getString('position');

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
      pin = savedPin ?? pin;
      role = savedRole ?? role;
      chatName = savedChatName ?? chatName;
    });

    // Jika PIN/role/nama belum ada di prefs, coba backfill dari Firestore sekali
    if ((pin.isEmpty) || (role.isEmpty) || (nama.isEmpty || nama == 'Nizar Ali')) {
      // tidak await agar UI tidak tersendat; method akan setState sendiri saat selesai
      // tetapi jika ingin sinkron blocking, bisa jadikan await
      // ignore: discarded_futures
      _loadProfileFromFirestore();
    }
  }

  Future<void> _loadProfileFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      final String fsName = (data['name'] ?? data['nama'] ?? '').toString();
      final String fsAbout = (data['about'] ?? data['tentang'] ?? '').toString();
      final String fsRole = (data['role'] ?? '').toString();
      final String fsPin  = (data['chatPin'] ?? data['pin'] ?? data['cv_pin'] ?? '').toString();
      final String fsChatName = (data['chatName'] ?? '').toString();
      // NOTE: fotoProfil biasanya URL di Firestore; kita tidak menimpa path lokal jika sudah ada.

      final prefs = await SharedPreferences.getInstance();
      if (fsName.isNotEmpty) {
        await prefs.setString('nama', fsName);
        _namaController.text = fsName;
      }
      if (fsAbout.isNotEmpty) {
        await prefs.setString('tentang', fsAbout);
        _tentangController.text = fsAbout;
      }
      if (fsRole.isNotEmpty) await prefs.setString('role', fsRole);
      if (fsPin.isNotEmpty) await prefs.setString('userPin', fsPin);
      if (fsChatName.isNotEmpty) await prefs.setString('chatName', fsChatName);

      if (!mounted) return;
      setState(() {
        if (fsName.isNotEmpty) {
          nama = fsName;
          _namaController.text = fsName;
        }
        if (fsAbout.isNotEmpty) {
          tentang = fsAbout;
          _tentangController.text = fsAbout;
        }
        if (fsRole.isNotEmpty) role = fsRole;
        if (fsPin.isNotEmpty) pin = fsPin.toUpperCase();
        if (fsChatName.isNotEmpty) {
          chatName = fsChatName;
          _chatNameController.text = fsChatName;
        }
      });

      if (kDebugMode) {
        debugPrint('[Profile] Firestore sync: name=$fsName role=$fsRole pin=$fsPin');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Profile] Firestore load error: $e');
    }
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
    final controller =
        field == "Nama Chat" ? _chatNameController : (field == "Nama" ? _namaController : _tentangController);
    if (field == "Nama Chat") {
      controller.text = chatName;
    } else if (field == "Nama") {
      controller.text = nama;
    } else {
      controller.text = tentang;
    }

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
      final prefs = await SharedPreferences.getInstance();
      if (field == "Nama Chat") {
        setState(() {
          chatName = result;
          _chatNameController.text = result;
        });
        await prefs.setString('chatName', result);
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'chatName': result,
            }, SetOptions(merge: true));
          }
        } catch (_) {}
      } else if (field == "Nama") {
        // (Opsional) jika ingin mengizinkan ubah real name lokal, tetap simpan ke prefs lokal
        setState(() { nama = result; _namaController.text = result; });
        await _saveProfile();
      } else {
        setState(() { tentang = result; _tentangController.text = result; });
        await _saveProfile();
      }
      _changed = true;
      profileChanged.value++;
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
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseAuth.instance.currentUser == null
              ? null
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final nameFs = (data?['name'] ?? data?['nama'] ?? '').toString();
            final aboutFs = (data?['about'] ?? data?['tentang'] ?? '').toString();
            final roleFs = (data?['role'] ?? '').toString();
            final pinFs  = (data?['chatPin'] ?? data?['pin'] ?? data?['cv_pin'] ?? '').toString();
            final fotoUrl = (data?['fotoProfil'] ?? '').toString();
            final chatNameFs = (data?['chatName'] ?? '').toString();

            // Decide displayed values (Firestore realtime > local prefs fallback)
            final displayName = nameFs.isNotEmpty ? nameFs : nama;
            final displayAbout = aboutFs.isNotEmpty ? aboutFs : tentang;
            final displayRole = roleFs.isNotEmpty ? roleFs : role;
            final displayPin = (pinFs.isNotEmpty ? pinFs : pin).toUpperCase();
            final displayChatName = chatNameFs.isNotEmpty ? chatNameFs : chatName;
            final displayRealName = displayName;

            return SingleChildScrollView(
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
                            final img = fotoProfil; // local file takes priority
                            if (img != null) {
                              return ClipOval(
                                child: Image.file(
                                  img,
                                  key: ValueKey(profileChanged.value),
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            if (fotoUrl.isNotEmpty) {
                              return CircleAvatar(
                                radius: 48,
                                backgroundImage: NetworkImage(fotoUrl),
                                backgroundColor: Colors.grey[300],
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
                        // Nama (Real)
                        const Text(
                          'Nama (Real)',
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
                              displayRealName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 51, 51, 51),
                              ),
                            ),
                            trailing: const Icon(Icons.verified_user, size: 18, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            dense: true,
                            onTap: null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Nama untuk Chat
                        const Text(
                          'Nama untuk Chat',
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
                              (displayChatName.isNotEmpty ? displayChatName : displayRealName),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 51, 51, 51),
                              ),
                            ),
                            trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            dense: true,
                            onTap: () => _editField('Nama Chat'),
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
                              displayAbout,
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
                          child: ListTile(
                            title: Text(
                              displayPin.isNotEmpty ? displayPin : '- Belum ada PIN -',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 51, 51, 51),
                              ),
                            ),
                            trailing: const Icon(Icons.lock, size: 18, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            dense: true,
                            onTap: null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Role
                        const Text(
                          'Role',
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
                              displayRole.isNotEmpty ? displayRole : '- Belum ada role -',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 51, 51, 51),
                              ),
                            ),
                            trailing: const Icon(Icons.work, size: 18, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            dense: true,
                            onTap: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  @override
  void dispose() {
    profileChanged.removeListener(_onProfileChanged);
    _namaController.dispose();
    _tentangController.dispose();
    _chatNameController.dispose();
    super.dispose();
  }
}