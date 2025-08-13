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
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/users.php',
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

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final TextEditingController namaController = TextEditingController(
      text: user['nama_user'],
    );
    final TextEditingController usernameController = TextEditingController(
      text: user['username'],
    );
    final List<String> levels = ['Admin', 'Karyawan'];
    String? selectedLevel = user['level'];
    if (selectedLevel == null || !levels.contains(selectedLevel)) {
      selectedLevel = 'Karyawan';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.teal.shade50],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),

                  // Form fields
                  _buildTextField(
                    controller: namaController,
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                    autofocus: true,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email,
                  ),

                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: InputDecoration(
                        labelText: 'Level Pengguna',
                        labelStyle: TextStyle(color: Colors.teal.shade700),
                        prefixIcon: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Colors.teal,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: levels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Icon(
                                level == 'Admin'
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                size: 18,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(level),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedLevel = value;
                      },
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () async {
                              final String nama = namaController.text.trim();
                              final String username = usernameController.text
                                  .trim();

                              if (nama.isEmpty ||
                                  username.isEmpty ||
                                  selectedLevel == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Semua field harus diisi'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context);

                              await updateUser(
                                id: user['id_user'],
                                nama: nama,
                                username: username,
                                level: selectedLevel!,
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.save, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Simpan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.teal.shade700),
          prefixIcon: Icon(icon, color: Colors.teal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Future<void> updateUser({
    required int id,
    required String nama,
    required String username,
    required String level,
  }) async {
    final url = Uri.parse(
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/users.php/update/$id',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama_user': nama,
          'username': username,
          'level': level,
        }),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal: Tidak ada respons dari server.'),
          ),
        );
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User berhasil diperbarui!')),
        );
        await fetchUsers();
      } else {
        String message = data['message'] ?? 'Gagal memperbarui user.';
        if (response.statusCode == 403) {
          message = 'Akses ditolak. Hanya Admin yang bisa edit user.';
        } else if (response.statusCode == 404) {
          message = 'User tidak ditemukan.';
        } else if (response.statusCode == 409) {
          message = 'Username sudah digunakan.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $message')));
      }
    } catch (e) {
      print('Error update user: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kesalahan jaringan: $e')));
    }
  }

  Future<void> deleteUser(int id) async {
    final url = Uri.parse(
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/users.php/delete/$id',
    );

    try {
      print('Attempting to delete user with ID: $id');
      print('URL: $url');

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
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditUserDialog(user);
                          },
                        ),
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
        foregroundColor: Colors.white,
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
