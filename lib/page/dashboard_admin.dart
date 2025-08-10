import 'package:flutter/material.dart';
import 'kelola_data_user.dart';
import 'update_password_page.dart';
import 'lihat_data_transaksi.dart';
import 'input_data_transaksi.dart';
import 'monitoring_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

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
    ];

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Dashboard Admin'),
        centerTitle: true,
        backgroundColor: Colors.teal,
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
  final Widget page;

  _MenuItem(this.icon, this.title, this.page);
}
