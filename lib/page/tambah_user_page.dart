import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TambahUserPage extends StatefulWidget {
  const TambahUserPage({super.key});

  @override
  State<TambahUserPage> createState() => _TambahUserPageState();
}

class _TambahUserPageState extends State<TambahUserPage> {
  final _formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedLevel;
  bool _isLoading = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();

    if (selectedLevel != 'Admin' && selectedLevel != 'Karyawan') {
      selectedLevel = null;
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Future<void> _tambahUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan, silakan login ulang'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse(
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/users.php',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nama_user': namaController.text.trim(),
          'username': usernameController.text.trim(),
          'password': passwordController.text.trim(),
          'level': selectedLevel,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User berhasil ditambahkan')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal menambah user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah User'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Masukkan nama lengkap' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Masukkan username' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) =>
                    value!.length < 6 ? 'Password minimal 6 karakter' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Level',
                  prefixIcon: Icon(Icons.security),
                ),
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Karyawan', child: Text('Karyawan')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                  });
                },
                validator: (value) => value == null ? 'Pilih level user' : null,
              ),

              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan User'),
                      onPressed: _tambahUser,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
