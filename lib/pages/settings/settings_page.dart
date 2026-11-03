import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/local_db_service.dart';
import '../../controllers/server_status_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
import '../../config/app_theme.dart';
import '../../config/app_config.dart';
import 'receipt_customizer_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _AppBar(),
      body: _Body(),
    );
  }
}

// --- APP BAR ---
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.cardBorderColor, height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Text(
            "Pengaturan Sistem",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Text(
              "SYS-CONFIG",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

// --- MAIN CONTENT ---
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final tabletCtrl = context.watch<TabletModeController>();
    final isTablet = tabletCtrl.isTabletLayout(context);

    // Section 1: Display & Tablet Mode
    final displaySection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(prefix: "// 01", title: "TAMPILAN & MODE TABLET"),
        _SettingsGroupCard(
          children: [
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: const Icon(
                  Icons.tablet_mac_rounded,
                  size: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              title: Text(
                "Mode Tablet Horizontal",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                "Kunci orientasi horizontal & optimalkan dashboard lebar",
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
              ),
              trailing: Switch.adaptive(
                value: tabletCtrl.isTabletLandscape,
                activeTrackColor: AppTheme.primaryDark,
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  HapticFeedback.mediumImpact();
                  tabletCtrl.setTabletLandscape(val);
                },
              ),
            ),
          ],
        ),
      ],
    );

    // Section 2: Hardware & Koneksi
    final hardwareSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(prefix: "// 02", title: "KONEKSI & HARDWARE POS"),
        _SettingsGroupCard(
          children: [
            _SettingsTile(
              code: "NET-IP",
              icon: Icons.dns_outlined,
              title: "Alamat IP Server",
              subtitle: "Atur alamat API backend server offline",
              onTap: () {
                HapticFeedback.lightImpact();
                _showUrlSettingDialog(context);
              },
            ),
            const Divider(height: 1, color: AppTheme.cardBorderColor),
            _SettingsTile(
              code: "THERMAL",
              icon: Icons.print_outlined,
              title: "Printer Thermal Bluetooth",
              subtitle: "Cek pairing dan sambungkan printer kasir",
              onTap: () {
                HapticFeedback.lightImpact();
                _showPrinterInfo(context);
              },
            ),
            const Divider(height: 1, color: AppTheme.cardBorderColor),
            _SettingsTile(
              code: "CUSTOM-58",
              icon: Icons.receipt_long_rounded,
              title: "Kustomisasi Struk Toko (58mm)",
              subtitle: "Atur logo di posisi manapun, layout 58mm & identitas toko",
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiptCustomizerPage()),
                );
              },
            ),
          ],
        ),
      ],
    );

    // Section 3: Data & Cadangan
    final dataSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(prefix: "// 03", title: "DATA & CADANGAN DATABASE"),
        _SettingsGroupCard(
          children: [
            _SettingsTile(
              code: "BACKUP",
              icon: Icons.backup_outlined,
              title: "Cadangkan Database (Backup)",
              subtitle: "Ekspor dan bagikan file .db lokal",
              onTap: () {
                HapticFeedback.lightImpact();
                _handleBackup(context);
              },
            ),
            const Divider(height: 1, color: AppTheme.cardBorderColor),
            _SettingsTile(
              code: "RESTORE",
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
      ],
    );

    // Section 4: Sistem
    final systemSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(prefix: "// 04", title: "INFORMASI SISTEM"),
        _SettingsGroupCard(
          children: [
            _SettingsTile(
              code: "VERSION",
              icon: Icons.info_outline_rounded,
              title: "Versi Aplikasi POS",
              subtitle: "${Config.appName} v${Config.appVersion}",
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "STABLE // OFFLINE",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
              onTap: () {},
            ),
            const Divider(height: 1, color: AppTheme.cardBorderColor),
            _SettingsTile(
              code: "EXIT",
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

    if (isTablet) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  displaySection,
                  const SizedBox(height: 16),
                  hardwareSection,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dataSection,
                  const SizedBox(height: 16),
                  systemSection,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        displaySection,
        const SizedBox(height: 16),
        hardwareSection,
        const SizedBox(height: 16),
        dataSection,
        const SizedBox(height: 16),
        systemSection,
      ],
    );
  }
}

// --- REUSABLE GROUP COMPONENTS ---
class _SectionHeader extends StatelessWidget {
  final String prefix;
  final String title;
  const _SectionHeader({required this.prefix, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            prefix,
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(8),
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
  final String? code;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsTile({
    this.code,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.stampRed.withValues(alpha: 0.08)
              : AppTheme.surfaceRecessed,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDestructive ? AppTheme.stampRed.withValues(alpha: 0.3) : AppTheme.cardBorderColor,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: isDestructive ? AppTheme.stampRed : AppTheme.textPrimary,
        ),
      ),
      title: Row(
        children: [
          if (code != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isDestructive ? AppTheme.stampRed.withValues(alpha: 0.08) : AppTheme.surfaceRecessed,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isDestructive ? AppTheme.stampRed.withValues(alpha: 0.3) : AppTheme.cardBorderColor,
                ),
              ),
              child: Text(
                code!,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isDestructive ? AppTheme.stampRed : AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDestructive ? AppTheme.stampRed : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppTheme.textMuted,
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
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.cardBorderColor),
      ),
      title: Text(
        "Konfigurasi Server API",
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Masukkan alamat IP server backend lokal (offline):",
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.jetBrainsMono(fontSize: 13),
              decoration: InputDecoration(
                hintText: "http://192.168.1.XX:8000/api",
                hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.cloud_outlined, size: 16, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: Text(
            "Batal",
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () async {
            final url = textController.text.trim();
            if (url.isEmpty) return;

            await apiService.updateBaseUrl(url);
            if (dialogCtx.mounted) {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("URL diperbarui: $url", style: GoogleFonts.plusJakartaSans()),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              );
              context.read<ServerStatusController>().checkStatus();
            }
          },
          child: Text(
            "SIMPAN",
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

void _showPrinterInfo(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "Hubungkan printer melalui bar status di halaman Kasir",
        style: GoogleFonts.plusJakartaSans(),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.cardBorderColor),
      ),
      title: Text(
        "Pulihkan Database?",
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      content: Text(
        "Semua data transaksi dan produk saat ini akan ditimpa dengan data dari file cadangan .db yang Anda pilih. Lanjutkan?",
        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            "Batal",
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            "PULIHKAN",
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final success = await LocalDbService.instance.importDatabase();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Database berhasil dipulihkan!", style: GoogleFonts.plusJakartaSans()),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.cardBorderColor),
      ),
      title: Text(
        "Konfirmasi Keluar",
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      content: Text(
        "Apakah Anda yakin ingin menutup sesi operasional POS?",
        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            "Batal",
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.stampRed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () {
            if (Theme.of(context).platform == TargetPlatform.android) {
              SystemNavigator.pop();
            } else {
              Navigator.pop(ctx);
            }
          },
          child: Text(
            "KELUAR",
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}
