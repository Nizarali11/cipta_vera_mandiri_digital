import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cipta_vera_mandiri_digital/app/modules/home/controllers/home_controller.dart';
 // sesuaikan path model Event



class UpcomingEventsSection extends StatelessWidget {
  final void Function(int) onMenuSelected;
  const UpcomingEventsSection({
    super.key,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Acara Mendatang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextButton(
              onPressed: () {
                onMenuSelected(2);
              },
              child: const Text('Lihat Kalender'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final data = controller.upcomingEvents;
          print("Upcoming events count: ${data.length}");
          if (data.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'Tidak ada acara mendatang',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          } else {
            return _buildEventsList(data);
          }
        }),
      ],
    );
  }

  Widget _buildEventsList(List<Event> data) {
    return Column(
      children: data.map((event) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.lightBlue[50],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${event.date.day}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    Text(
                      _bulan(event.date.month),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.time}\n${event.location}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
String _bulan(int bulan) {
  const bulanStr = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  if (bulan >= 1 && bulan <= 12) {
    return bulanStr[bulan];
  }
  return '';
}