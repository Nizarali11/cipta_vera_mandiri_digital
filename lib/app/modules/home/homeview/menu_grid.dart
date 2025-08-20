import 'dart:ui';
import 'package:cipta_vera_mandiri_digital/absensi/absen.dart';
import 'package:cipta_vera_mandiri_digital/absensi/cuti.dart';
import 'package:cipta_vera_mandiri_digital/absensi/izin.dart';
import 'package:flutter/material.dart';
 // sesuaikan path ini dengan lokasi CalendarPage

class MenuGrid extends StatelessWidget {
  final void Function(int) onMenuSelected;

  const MenuGrid({super.key, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 18,
      crossAxisSpacing: 18,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Absen Kehadiran
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendancePage()),
            );
          },
          child: _MenuIcon(
            icon: Icons.fingerprint,
            label: 'Absen Kehadiran',
            color: Colors.green[400]!,
          ),
        ),
        // Cuti
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeavePage()),
            );
          },
          child: _MenuIcon(
            icon: Icons.beach_access,
            label: 'Cuti',
            color: Colors.orange[400]!,
          ),
        ),
        // Izin
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PermissionPage()),
            );
          },
          child: _MenuIcon(
            icon: Icons.assignment_turned_in,
            label: 'Izin',
            color: Colors.purple[400]!,
          ),
        ),
        // Pemberkasan
        _MenuIcon(
          icon: Icons.insert_drive_file,
          label: 'Pemberkasan',
          color: Colors.grey[400]!,
        ),
        // Kalender
        GestureDetector(
          onTap: () {
            onMenuSelected(2);
          },
          child: _MenuIcon(
            icon: Icons.calendar_today,
            label: 'Kalender',
            color: Colors.blue[300]!,
          ),
        ),
        // Permintaan Material
        _MenuIcon(
          icon: Icons.shopping_cart,
          label: 'Permintaan Material',
          color: Colors.red[300]!,
        ),
      ],
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
