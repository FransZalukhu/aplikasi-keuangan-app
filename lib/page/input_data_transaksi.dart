import 'package:flutter/material.dart';

class InputDataTransaksiPage extends StatefulWidget {
  const InputDataTransaksiPage({super.key});

  @override
  State<InputDataTransaksiPage> createState() => _InputDataTransaksiPageState();
}

class _InputDataTransaksiPageState extends State<InputDataTransaksiPage> {
  final nilaiController = TextEditingController();
  final keteranganController = TextEditingController();
  String jenis = 'pm';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data Transaksi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nilaiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nilai Transaksi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keteranganController,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: jenis,
              decoration: const InputDecoration(
                labelText: 'Jenis Transaksi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pm', child: Text('Pemasukan')),
                DropdownMenuItem(value: 'pg', child: Text('Pengeluaran')),
              ],
              onChanged: (val) => setState(() => jenis = val!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
