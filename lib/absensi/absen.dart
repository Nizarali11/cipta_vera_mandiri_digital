// ================= Absen Kehadiran Page =================
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  static const routeName = '/attendance';

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime? checkInAt;
  DateTime? checkOutAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absen Kehadiran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Check-in'),
                subtitle: Text(checkInAt != null
                    ? checkInAt!.toLocal().toString()
                    : 'Belum check-in'),
                trailing: ElevatedButton(
                  onPressed: () {
                    setState(() => checkInAt = DateTime.now());
                  },
                  child: const Text('Masuk'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Check-out'),
                subtitle: Text(checkOutAt != null
                    ? checkOutAt!.toLocal().toString()
                    : 'Belum check-out'),
                trailing: ElevatedButton(
                  onPressed: () {
                    setState(() => checkOutAt = DateTime.now());
                  },
                  child: const Text('Pulang'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ringkasan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Status: ' +
                (checkInAt == null
                    ? 'Belum absen'
                    : (checkOutAt == null ? 'Sudah check-in' : 'Selesai'))),
          ],
        ),
      ),
    );
  }
}
