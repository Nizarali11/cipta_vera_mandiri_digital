import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

class MediaDocsPage extends StatefulWidget {
  final String chatId;

  const MediaDocsPage({Key? key, required this.chatId}) : super(key: key);

  @override
  _MediaDocsPageState createState() => _MediaDocsPageState();
}

class _MediaDocsPageState extends State<MediaDocsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final LinearGradient _backgroundGradient = const LinearGradient(
    colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _mediaStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('type', isEqualTo: 'image')
        .orderBy('ts', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _docsStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('type', isEqualTo: 'file')
        .orderBy('ts', descending: true)
        .snapshots();
  }

  Widget _buildGlassAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.16),
                  Colors.white.withOpacity(0.10),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Media & Dokumen',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    controller: _tabController,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3.0, color: Colors.white),
                      insets: EdgeInsets.symmetric(horizontal: 24.0),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Media'),
                      Tab(text: 'Dokumen'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: null, // handled in flexibleSpace
      bottom: null, // handled in flexibleSpace
    );
  }

  Widget _buildMediaGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _mediaStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading media'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No media found'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final imageUrl = (data['imageUrl'] ?? data['photoUrl'] ?? data['url'] ?? '').toString();
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _docsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading documents'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No documents found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final fileName = (data['fileName'] ?? 'Dokumen').toString();
            final fileUrl = (data['fileUrl'] ?? data['url'] ?? '').toString();
            return ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: Text(fileName),
              onTap: () {
                if (fileUrl.isNotEmpty) {
                  // TODO: buka viewer/download fileUrl
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPoweredBy() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Text(
              'Powered by',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('lib/app/assets/images/cvm.png', height: 18),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 56),
        child: _buildGlassAppBar(),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: _backgroundGradient,
        ),
        child: Stack(
          children: [
            // Main content with padding at bottom for the glass card
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMediaGrid(),
                        _buildDocsList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64), // Padding for glass card at bottom
                ],
              ),
            ),
            // Glass card pinned at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: _buildPoweredBy(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
