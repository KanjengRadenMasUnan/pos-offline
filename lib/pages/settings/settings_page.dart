import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../controllers/server_status_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _AppBar(),
      body: const _Body(),
    );
  }
}

// --- APP BAR ---

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Pengaturan"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.5,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- MAIN CONTENT ---

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),

        // Section: Koneksi
        const _SectionHeader(title: "KONEKSI & PERANGKAT"),
        _MenuTile(
          icon: Icons.cloud_queue,
          title: "Alamat IP Server",
          subtitle: "Atur alamat API backend",
          color: Colors.blue,
          onTap: () => _showUrlSettingDialog(context),
        ),
        _MenuTile(
          icon: Icons.print,
          title: "Printer Thermal",
          subtitle: "Cek koneksi bluetooth printer",
          color: Colors.orange,
          onTap: () => _showPrinterComingSoon(context),
        ),

        const Divider(height: 40),

        // Section: Akun
        const _SectionHeader(title: "AKUN & APLIKASI"),
        _MenuTile(
          icon: Icons.logout,
          title: "Keluar Aplikasi",
          subtitle: "Tutup sesi dan keluar",
          color: Colors.red,
          onTap: () => _showLogoutConfirm(context),
        ),
      ],
    );
  }
}

// --- REUSABLE COMPONENTS ---

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// --- DIALOGS & LOGIC HELPERS ---

void _showUrlSettingDialog(BuildContext context) {
  final apiService = ApiService();
  final textController = TextEditingController(text: apiService.currentBaseUrl);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Konfigurasi Server"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Masukkan alamat IP server API lengkap.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Base URL",
              hintText: "http://192.168.1.XX:8000/api",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cloud_queue),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () async {
            final url = textController.text.trim();
            if (url.isEmpty) return;

            await apiService.updateBaseUrl(url);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ URL Berhasil diperbarui: $url"),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<ServerStatusController>().checkStatus();
            }
          },
          child: const Text("SIMPAN"),
        ),
      ],
    ),
  );
}

void _showPrinterComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Fitur Printer Thermal akan segera hadir."),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showLogoutConfirm(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Konfirmasi"),
      content: const Text("Yakin ingin keluar dari aplikasi?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            if (Theme.of(context).platform == TargetPlatform.android) {
              SystemNavigator.pop();
            } else {
              Navigator.pop(context);
            }
          },
          child: const Text("KELUAR", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
