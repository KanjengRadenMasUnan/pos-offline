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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _permissionRequested = false;

  // --- LIFECYCLE ---

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

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // --- HEADER WIDGETS ---

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo Admin,",
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

  // --- CONTENT WIDGETS ---

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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 15),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: const [
                _MenuCard(
                  title: "KASIR",
                  icon: Icons.point_of_sale,
                  color: Colors.blue,
                  page: CashierPage(), // Pastikan import CashierPage ada
                ),
                // ... MenuCard lainnya tetap sama ...
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

  // --- DRAWER WIDGETS ---

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSettingsMenuItem(context),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenuItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings, size: 28, color: Colors.grey),
      title: const Text(
        "Pengaturan",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        "IP Server, Printer & Akun",
        style: TextStyle(fontSize: 12),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
      },
    );
  }
}

// --- SUB-WIDGETS (PRIVAT) ---

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
      shadowColor: Colors.grey.withOpacity(0.1),
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
