import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class NewsService {
  static Future<List<Map<String, String>>> fetchBeritaTerbaru() async {
    final List<Map<String, String>> allNews = [];

    // Define RSS sources
    final sources = [
      {
        'url': 'https://www.antaranews.com/rss/terkini.xml',
        'source': 'Antara'
      },
      {
        'url': 'https://kompas.com/rss/terpopuler.xml',
        'source': 'Kompas'
      },
    ];

    for (final source in sources) {
      try {
        final response = await http.get(Uri.parse(source['url']!));
        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final items = document.findAllElements('item');
          for (final item in items) {
            final title = item.getElement('title')?.text ?? '';
            final link = item.getElement('link')?.text ?? '';
            // Try to get image from <enclosure> or <media:content>
            String image = '';
            final enclosure = item.getElement('enclosure');
            if (enclosure != null && enclosure.getAttribute('url') != null) {
              image = enclosure.getAttribute('url')!;
            } else {
              // Try media:content
              final mediaContent = item.findElements('media:content').isNotEmpty
                  ? item.findElements('media:content').first
                  : null;
              if (mediaContent != null && mediaContent.getAttribute('url') != null) {
                image = mediaContent.getAttribute('url')!;
              }
            }
            allNews.add({
              'title': title,
              'link': link,
              'image': image,
              'source': source['source']!,
            });
          }
        }
      } catch (e) {
        // Ignore errors for now, could log or handle accordingly
        continue;
      }
    }
    return allNews;
  }
}