import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
             Color.fromARGB(255, 255, 255, 255),
            ],
            stops: [0.5, 2.0],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Profile picture and edit
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Color.fromARGB(255, 51, 51, 51),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: const Text(
                        'Nizar Ali',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 51, 51, 51),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
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
                      title: const Text(
                        'Sibuk',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 51, 51, 51),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
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
                      title: const Text(
                        '243893743N',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 51, 51, 51),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
                    ),
                  ),
                
                    
                  
                ],
              ),
            ),
            const Spacer(),
            // Bottom navigation bar
           
          ],
        ),
      ),
    );
  }
}