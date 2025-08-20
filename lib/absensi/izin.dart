
// ================= Izin Page =================
import 'package:flutter/material.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});
  static const routeName = '/permission';

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final _formKey = GlobalKey<FormState>();
  final reasonCtrl = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Izin')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(startTime == null
                    ? 'Jam mulai'
                    : 'Mulai: ${startTime!.format(context)}'),
                onTap: () => _pickTime(isStart: true),
              ),
              ListTile(
                leading: const Icon(Icons.timer_off),
                title: Text(endTime == null
                    ? 'Jam selesai'
                    : 'Selesai: ${endTime!.format(context)}'),
                onTap: () => _pickTime(isStart: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan izin',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      startTime != null && endTime != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Izin berhasil diajukan')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lengkapi data izin terlebih dahulu')),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Ajukan Izin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
