import 'package:aplikasi_keuangan/page/lihat_data_transaksi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_password_page.dart';
import 'input_data_transaksi.dart';
import 'login_page.dart';

class KaryawanDashboardPage extends StatefulWidget {
  const KaryawanDashboardPage({super.key});

  @override
  State<KaryawanDashboardPage> createState() => _KaryawanDashboardPageState();
}

class _KaryawanDashboardPageState extends State<KaryawanDashboardPage> {
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> menuItems = [
      _MenuItem(
        Icons.lock_reset,
        'Update Password',
        const UpdatePasswordPage(),
      ),
      _MenuItem(
        Icons.add_circle_outline,
        'Input Data Transaksi',
        const InputDataTransaksiPage(),
      ),
      _MenuItem(
        Icons.add_circle_outline,
        'Lihat Data Transaksi',
        const LihatDataTransaksiPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Dashboard Karyawan'),
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
                if (item.page != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.page!),
                  );
                } else {}
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
                      colors: [Colors.teal.shade300, Colors.teal.shade700],
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
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Widget? page;

  _MenuItem(this.icon, this.title, this.page);
}
