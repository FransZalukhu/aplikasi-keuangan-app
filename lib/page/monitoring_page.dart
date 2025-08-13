import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  bool _isLoading = true;
  double pemasukan = 0;
  double pengeluaran = 0;
  double saldo = 0;

  Future<void> fetchDashboardData() async {
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
      debugPrint('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring / Grafik'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Grafik Pemasukan & Pengeluaran Bulan Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: pemasukan,
                            title:
                                'Pemasukan\nRp${pemasukan.toStringAsFixed(0)}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: pengeluaran,
                            title:
                                'Pengeluaran\nRp${pengeluaran.toStringAsFixed(0)}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.teal.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.teal,
                      ),
                      title: const Text('Saldo Bulan Ini'),
                      subtitle: Text('Rp${saldo.toStringAsFixed(0)}'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
