import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/local_db_service.dart';
import '../../controllers/server_status_controller.dart';
import '../../config/app_theme.dart';
import '../../config/app_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
      title: const Text(
        "Pengaturan Sistem",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Section: Koneksi & Perangkat
        const _SectionHeader(title: "KONEKSI & HARDWARE"),
        _SettingsGroupCard(
          children: [
            _SettingsTile(
              icon: Icons.dns_outlined,
              title: "Alamat IP Server",
              subtitle: "Atur alamat API backend server offline",
              onTap: () {
                HapticFeedback.lightImpact();
                _showUrlSettingDialog(context);
              },
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.print_outlined,
              title: "Printer Thermal Bluetooth",
              subtitle: "Cek pairing dan sambungkan printer kasir",
              onTap: () {
                HapticFeedback.lightImpact();
                _showPrinterInfo(context);
              },
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.receipt_long_outlined,
              title: "Kustomisasi Struk Toko",
              subtitle: "Nama toko, alamat, footer & ukuran kertas",
              onTap: () {
                HapticFeedback.lightImpact();
                _showReceiptSettingDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Data & Cadangan
        const _SectionHeader(title: "DATA & CADANGAN"),
        _SettingsGroupCard(
          children: [
            _SettingsTile(
              icon: Icons.backup_outlined,
              title: "Cadangkan Database (Backup)",
              subtitle: "Ekspor dan bagikan file .db lokal",
              onTap: () {
                HapticFeedback.lightImpact();
                _handleBackup(context);
              },
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.settings_backup_restore_rounded,
              title: "Pulihkan Database (Restore)",
              subtitle: "Ganti database saat ini dengan cadangan .db",
              onTap: () {
                HapticFeedback.lightImpact();
                _handleRestore(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Akun & Aplikasi
        const _SectionHeader(title: "INFORMASI SISTEM"),
        _SettingsGroupCard(
          children: [
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: "Versi Aplikasi",
              subtitle: "${Config.appName} v${Config.appVersion}",
              trailing: const Text(
                "Up to date",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
                ),
              ),
              onTap: () {},
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.power_settings_new_rounded,
              title: "Keluar dari Aplikasi",
              subtitle: "Tutup sesi operasional kasir",
              isDestructive: true,
              onTap: () {
                HapticFeedback.mediumImpact();
                _showLogoutConfirm(context);
              },
            ),
          ],
        ),
      ],
    );
  }
}

// --- REUSABLE GROUP COMPONENTS ---
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorColor.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppTheme.textMuted,
          ),
    );
  }
}

// --- DIALOGS & LOGIC HELPERS ---

void _showReceiptSettingDialog(BuildContext context) async {
  final settings = await LocalDbService.instance.getReceiptSettings();

  final nameController = TextEditingController(text: settings['store_name']);
  final addressController = TextEditingController(text: settings['store_address']);
  final contactController = TextEditingController(text: settings['store_contact']);
  final footerController = TextEditingController(text: settings['footer_message']);
  int paperSize = settings['paper_size'] ?? 58;

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Pengaturan Struk Toko",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogInput("Nama Toko", "Contoh: Nanda Cell", nameController),
                  const SizedBox(height: 10),
                  _dialogInput("Alamat Toko", "Contoh: Jl. Merdeka No. 10", addressController),
                  const SizedBox(height: 10),
                  _dialogInput("Kontak / WhatsApp", "Contoh: 0812-XXXX-XXXX", contactController),
                  const SizedBox(height: 10),
                  _dialogInput("Pesan Footer Struk", "Contoh: Terima Kasih!", footerController),
                  const SizedBox(height: 14),
                  const Text(
                    "Ukuran Kertas Printer",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _PaperSizeChoice(
                          label: "58 mm (Standar)",
                          size: 58,
                          selectedSize: paperSize,
                          onSelected: (val) => setState(() => paperSize = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PaperSizeChoice(
                          label: "80 mm (Besar)",
                          size: 80,
                          selectedSize: paperSize,
                          onSelected: (val) => setState(() => paperSize = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Batal", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                await LocalDbService.instance.updateReceiptSettings(
                  nameController.text.trim(),
                  addressController.text.trim(),
                  contactController.text.trim(),
                  footerController.text.trim(),
                  paperSize,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengaturan struk berhasil disimpan"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("SIMPAN", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        );
      },
    ),
  );
}

Widget _dialogInput(String label, String hint, TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.cardBorderColor),
        ),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ),
    ],
  );
}

class _PaperSizeChoice extends StatelessWidget {
  final String label;
  final int size;
  final int selectedSize;
  final ValueChanged<int> onSelected;

  const _PaperSizeChoice({
    required this.label,
    required this.size,
    required this.selectedSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = size == selectedSize;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSelected(size),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

void _showUrlSettingDialog(BuildContext context) {
  final apiService = ApiService();
  final textController = TextEditingController(text: apiService.currentBaseUrl);

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Konfigurasi Server API",
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Masukkan alamat IP server backend lokal (offline):",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: "http://192.168.1.XX:8000/api",
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                prefixIcon: Icon(Icons.cloud_outlined, size: 18, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text("Batal", style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () async {
            final url = textController.text.trim();
            if (url.isEmpty) return;

            await apiService.updateBaseUrl(url);
            if (dialogCtx.mounted) {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("URL diperbarui: $url"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<ServerStatusController>().checkStatus();
            }
          },
          child: const Text("SIMPAN", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    ),
  );
}

void _showPrinterInfo(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Hubungkan printer melalui bar status di halaman Kasir"),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _handleBackup(BuildContext context) async {
  try {
    await LocalDbService.instance.shareDatabase();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal backup: $e")));
    }
  }
}

Future<void> _handleRestore(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Pulihkan Database?",
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: const Text(
        "Semua data transaksi dan produk saat ini akan ditimpa dengan data dari file cadangan .db yang Anda pilih. Lanjutkan?",
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Batal", style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Ya, Pulihkan", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final success = await LocalDbService.instance.importDatabase();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Database berhasil dipulihkan!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal restore: $e")));
    }
  }
}

void _showLogoutConfirm(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Konfirmasi Keluar",
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: const Text(
        "Apakah Anda yakin ingin menutup aplikasi POS Nanda Cell?",
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Batal", style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            if (Theme.of(context).platform == TargetPlatform.android) {
              SystemNavigator.pop();
            } else {
              Navigator.pop(ctx);
            }
          },
          child: const Text("KELUAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    ),
  );
}
