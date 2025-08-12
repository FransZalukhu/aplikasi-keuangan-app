import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InputDataTransaksiPage extends StatefulWidget {
  const InputDataTransaksiPage({super.key});

  @override
  State<InputDataTransaksiPage> createState() => _InputDataTransaksiPageState();
}

class _InputDataTransaksiPageState extends State<InputDataTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final nilaiController = TextEditingController();
  final keteranganController = TextEditingController();
  String jenis = 'pm';
  DateTime selectedDate = DateTime.now();
  String? token;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _simpanTransaksi() async {
    if (!_formKey.currentState!.validate()) return;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan, silakan login ulang'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
      'https://c42716d6d506.ngrok-free.app/BackendApliksiKeuangan/api/transactions.php',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "nilai_transaksi": double.tryParse(nilaiController.text) ?? 0,
          "ket_transaksi": keteranganController.text.trim(),
          "status": jenis,
          "tgl_transaksi": selectedDate.toIso8601String().split('T')[0],
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
        );
        Navigator.pop(context, true); // kembali dengan status sukses
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal menambahkan transaksi'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data Transaksi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Transaksi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(text: formattedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nilaiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nilai Transaksi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Masukkan nilai transaksi'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Masukkan keterangan'
                    : null,
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
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _simpanTransaksi,
                      child: const Text('Simpan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
