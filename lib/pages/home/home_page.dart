import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smartcampus/utils/permission_helper.dart';
import '../../config/app_theme.dart';
import '../../config/app_config.dart';
import '../../controllers/server_status_controller.dart';
import '../product/add_product_page.dart';
import '../product/product_list_page.dart';
import '../cashier/cashier_page.dart';
import '../printing/bulk_print_page.dart';
import '../history/history_page.dart';
import '../settings/settings_page.dart';
import '../report/report_page.dart'; // Halaman laporan

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  void _requestPermissions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _permissionRequested) return;
      _permissionRequested = true;
      PermissionHelper.requestAppPermissions(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _buildDrawer(context), // Drawer cantik baru
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // --- HEADER (tetap seperti versi sebelumnya) ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, Admin!",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  "Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const _ServerStatusBadge(),
        ],
      ),
    );
  }

  // --- KONTEN UTAMA (grid menu) ---
  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ServerStatusController>().checkStatus();
        HapticFeedback.lightImpact();
      },
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "MENU UTAMA",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: const [
                _MenuCard(
                  title: "KASIR",
                  icon: Icons.point_of_sale,
                  color: Colors.blue,
                  page: CashierPage(),
                ),
                _MenuCard(
                  title: "PRODUK",
                  icon: Icons.inventory_2,
                  color: Colors.orange,
                  page: ProductListPage(),
                ),
                _MenuCard(
                  title: "INPUT BARU",
                  icon: Icons.add_box,
                  color: Colors.green,
                  page: AddProductPage(),
                ),
                _MenuCard(
                  title: "RIWAYAT",
                  icon: Icons.history,
                  color: Colors.purple,
                  page: HistoryPage(),
                ),
                _MenuCard(
                  title: "LABEL QR",
                  icon: Icons.qr_code_2,
                  color: Colors.teal,
                  page: BulkPrintPage(),
                ),
                _MenuCard(
                  title: "LAPORAN",
                  icon: Icons.assessment,
                  color: Colors.red,
                  page: ReportPage(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                "${Config.appName} ${Config.appVersion}",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DRAWER BARU YANG CANTIK ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Drawer dengan latar gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withBlue(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: const Icon(
                        Icons.store_mall_directory,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Nanda Cell",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Config.appName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu Utama (hanya Pengaturan, bisa ditambah nanti)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    _DrawerMenuItem(
                      icon: Icons.settings,
                      color: Colors.grey[700]!,
                      title: "Pengaturan",
                      subtitle: "IP Server, Printer & Akun",
                      onTap: () {
                        Navigator.pop(context); // Tutup drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                    // Bisa tambahkan menu lain di sini
                  ],
                ),
              ),

              const Spacer(),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Text(
                  "© ${DateTime.now().year} Nanda Cell",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET DRAWER ITEM (DESAIN BARU) ---
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// --- BADGE STATUS SERVER (TETAP) ---
class _ServerStatusBadge extends StatelessWidget {
  const _ServerStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Selector<ServerStatusController, ServerStatus>(
      selector: (_, ctrl) => ctrl.status,
      builder: (_, status, _) {
        final text = switch (status) {
          ServerStatus.online => "ONLINE",
          ServerStatus.checking => "CHECKING",
          ServerStatus.sleeping => "OFFLINE",
        };

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

// --- KARTU MENU (TETAP) ---
class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
