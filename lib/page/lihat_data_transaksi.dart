import 'package:flutter/material.dart';

class LihatDataTransaksiPage extends StatelessWidget {
  const LihatDataTransaksiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat Data Transaksi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10, // dummy data
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.teal),
              title: Text('Transaksi #${index + 1}'),
              subtitle: const Text('Rp 1.000.000 - Pemasukan'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
