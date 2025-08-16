import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String nama = "Nizar Ali";
  String tentang = "Sibuk";
  File? fotoProfil;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tentangController = TextEditingController();

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
    }
  }


  void _removeImage() {
    setState(() {
      fotoProfil = null;
    });
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
                                      setState(() => fotoProfil = File(cropped.path));
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
    return Scaffold(
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
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: fotoProfil != null ? FileImage(fotoProfil!) : null,
                    child: fotoProfil == null
                        ? const Icon(
                            Icons.person,
                            size: 56,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _showPhotoOptions,
                       
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
    );
  }
}