import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'kelola_data_user.dart';
import 'update_password_page.dart';
import 'lihat_data_transaksi.dart';
import 'input_data_transaksi.dart';
import 'monitoring_page.dart';
import 'cetak_laporan_page.dart';
import 'login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  double pemasukan = 0;
  double pengeluaran = 0;
  double saldo = 0;
  bool _isLoading = true;

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> fetchSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse(
        'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/transactions.php/dashboard',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            pemasukan = (data['data']['pemasukan_bulan_ini'] ?? 0).toDouble();
            pengeluaran = (data['data']['pengeluaran_bulan_ini'] ?? 0)
                .toDouble();
            saldo = (data['data']['saldo_bulan_ini'] ?? 0).toDouble();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> menuItems = [
      _MenuItem(Icons.people, 'Kelola Data User', const KelolaDataUserPage()),
      _MenuItem(
        Icons.lock_reset,
        'Update Password',
        const UpdatePasswordPage(),
      ),
      _MenuItem(
        Icons.list_alt,
        'Lihat Data Transaksi',
        const LihatDataTransaksiPage(),
      ),
      _MenuItem(
        Icons.add_circle_outline,
        'Input Data Transaksi',
        const InputDataTransaksiPage(),
      ),
      _MenuItem(Icons.bar_chart, 'Monitoring / Grafik', const MonitoringPage()),
      _MenuItem(Icons.print, 'Cetak Laporan', const CetakLaporanPage()),
    ];

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Dashboard Admin'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard(
                        title: 'Pemasukan',
                        value: pemasukan,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                      _buildSummaryCard(
                        title: 'Pengeluaran',
                        value: pengeluaran,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                      _buildSummaryCard(
                        title: 'Saldo',
                        value: saldo,
                        color: Colors.teal,
                        icon: Icons.account_balance_wallet,
                      ),
                    ],
                  ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.builder(
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => item.page),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade300,
                              Colors.teal.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 48, color: Colors.white),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${value.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Widget page;
  _MenuItem(this.icon, this.title, this.page);
}
