import 'package:cipta_vera_mandiri_digital/app/services/news_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Berita & Artikel Terbaru',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse('https://www.antaranews.com/');
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  throw Exception('Tidak dapat membuka URL: $uri');
                }
              },
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, String>>>(
          future: NewsService.fetchBeritaTerbaru(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('Gagal memuat berita: ${snapshot.error}')),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('Tidak ada berita terbaru')),
              );
            }
            final berita = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  berita.length,
                  (i) {
                    final item = berita[i];
                    final imageUrl = item['image'];
                    return Container(
                      width: 250,
                      height: 150,
                      margin: EdgeInsets.only(
                        left: i == 0 ? 0 : 12,
                        right: i == berita.length - 1 ? 0 : 0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[100],
                      ),
                      child: InkWell(
                        onTap: () async {
                          final url = item['link'] ?? '';
                          if (url.isNotEmpty) {
                            final uri = Uri.parse(url);
                            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                              throw Exception('Tidak dapat membuka URL: $url');
                            }
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Background image
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                Positioned.fill(
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              // Gradient overlay with title at the bottom
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item['title'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black38,
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sumber: Antara',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}