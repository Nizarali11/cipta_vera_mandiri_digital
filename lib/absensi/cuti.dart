
// ================= Cuti Page =================
import 'package:flutter/material.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});
  static const routeName = '/leave';

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? startDate;
  DateTime? endDate;
  final reasonCtrl = TextEditingController();

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Cuti')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(startDate == null
                    ? 'Tanggal mulai'
                    : 'Mulai: ${startDate!.toLocal().toString().split(' ').first}'),
                onTap: () => _pickDate(isStart: true),
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: Text(endDate == null
                    ? 'Tanggal selesai'
                    : 'Selesai: ${endDate!.toLocal().toString().split(' ').first}'),
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan cuti',
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
                      startDate != null && endDate != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cuti berhasil diajukan')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lengkapi data cuti terlebih dahulu')),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Ajukan Cuti'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
