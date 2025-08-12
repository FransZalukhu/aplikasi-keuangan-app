import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LihatDataTransaksiPage extends StatefulWidget {
  const LihatDataTransaksiPage({super.key});

  @override
  State<LihatDataTransaksiPage> createState() => _LihatDataTransaksiPageState();
}

class _LihatDataTransaksiPageState extends State<LihatDataTransaksiPage> {
  List<dynamic> transaksi = [];
  bool isLoading = true;
  String? errorMessage;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      setState(() {
        errorMessage = 'Token tidak ditemukan, silakan login ulang.';
        isLoading = false;
      });
      return;
    }
    await fetchTransaksi();
  }

  Future<void> fetchTransaksi() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse(
      'https://c42716d6d506.ngrok-free.app/BackendApliksiKeuangan/api/transactions.php',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            transaksi = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Data transaksi kosong';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Gagal mengambil data (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  void _showDetailPopup(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Detail Transaksi',
            style: TextStyle(color: Colors.teal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('No. Transaksi', item['no_transaksi'].toString()),
              _buildDetailRow('Tanggal', item['tgl_transaksi']),
              _buildDetailRow('Nilai', 'Rp ${item['nilai_transaksi']}'),
              _buildDetailRow('Keterangan', item['ket_transaksi']),
              _buildDetailRow('Status', _formatStatus(item['status'])),
              _buildDetailRow('Dibuat oleh', item['nama_user']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    return status == 'pm' ? 'Pemasukan' : 'Pengeluaran';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat Data Transaksi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTransaksi,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transaksi.length,
              itemBuilder: (context, index) {
                final item = transaksi[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.teal),
                    title: Text(
                      'Rp ${item['nilai_transaksi']} - ${_formatStatus(item['status'])}',
                    ),
                    subtitle: Text(
                      '${item['tgl_transaksi']} - ${item['ket_transaksi']}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showDetailPopup(item),
                  ),
                );
              },
            ),
    );
  }
}
