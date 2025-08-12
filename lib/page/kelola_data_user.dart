import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tambah_user_page.dart';

class KelolaDataUserPage extends StatefulWidget {
  const KelolaDataUserPage({super.key});

  @override
  State<KelolaDataUserPage> createState() => _KelolaDataUserPageState();
}

class _KelolaDataUserPageState extends State<KelolaDataUserPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? errorMessage;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchUsers();
  }

  Future<void> _loadTokenAndFetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      setState(() {
        errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
        isLoading = false;
      });
      return;
    }
    await fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse(
      'https://c42716d6d506.ngrok-free.app/BackendApliksiKeuangan/api/users.php',
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
            users = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Data user kosong';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage =
              'Token tidak valid atau kadaluarsa. Silakan login ulang.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal mengambil data user. (${response.statusCode})';
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

  Future<void> deleteUser(int id) async {
    final url = Uri.parse(
      'https://c42716d6d506.ngrok-free.app/BackendApliksiKeuangan/api/users.php/delete/$id',
    );

    try {
      print('Attempting to delete user with ID: $id'); // Debug log
      print('URL: $url'); // Debug log

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server tidak memberikan response')),
        );
        return;
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User berhasil dihapus')));
        await fetchUsers();
      } else {
        String errorMessage = 'Gagal menghapus user';

        if (response.statusCode == 403) {
          errorMessage =
              'Akses ditolak. Anda tidak memiliki izin untuk menghapus user ini.';
        } else if (response.statusCode == 404) {
          errorMessage = 'User tidak ditemukan atau endpoint salah.';
        } else if (response.statusCode == 500) {
          errorMessage = data['message'] ?? 'Terjadi kesalahan di server.';
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      print('Error during delete: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data User'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchUsers),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: Text(user['nama_user']),
                    subtitle: Text(
                      'Level: ${user['level']}\nUsername: ${user['username']}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: Text(
                                  'Yakin ingin menghapus user "${user['nama_user']}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // Pastikan parsing ID aman
                                      try {
                                        final userId = user['id_user'];
                                        int id;

                                        if (userId is String) {
                                          id = int.parse(userId);
                                        } else if (userId is int) {
                                          id = userId;
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Format ID user tidak valid',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        deleteUser(id);
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error parsing user ID: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahUserPage()),
          );
          if (result == true) {
            fetchUsers();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
