import 'dart:async';
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
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/transactions.php',
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

  Future<void> updateTransaction({
    required int id,
    required String noTransaksi,
    required String tanggal,
    required double nilai,
    required String keterangan,
    required String status,
  }) async {
    final url = Uri.parse(
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/transactions.php/$id',
    );

    try {
      print('UPDATE - URL: $url');
      print(
        'UPDATE - Data: {no_transaksi: $noTransaksi, tgl_transaksi: $tanggal, nilai_transaksi: $nilai, ket_transaksi: $keterangan, status: $status}',
      );

      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'no_transaksi': noTransaksi,
              'tgl_transaksi': tanggal,
              'nilai_transaksi': nilai,
              'ket_transaksi': keterangan,
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('UPDATE - Response Status: ${response.statusCode}');
      print('UPDATE - Response Body: ${response.body}');

      if (response.body.isEmpty) {
        throw 'Server tidak memberikan response';
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Transaksi berhasil diperbarui!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        await fetchTransaksi();
      } else {
        String errorMessage = 'Gagal memperbarui transaksi';

        switch (response.statusCode) {
          case 403:
            errorMessage =
                'Akses ditolak. Hanya Admin yang bisa mengedit transaksi.';
            break;
          case 404:
            errorMessage = 'Transaksi tidak ditemukan.';
            break;
          case 500:
            errorMessage = data['message'] ?? 'Terjadi kesalahan di server.';
            break;
          default:
            if (data['message'] != null) {
              errorMessage = data['message'];
            }
        }

        throw errorMessage;
      }
    } on TimeoutException catch (e) {
      print('UPDATE - Timeout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timeout. Periksa koneksi internet.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('UPDATE - Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showEditTransactionDialog(Map<String, dynamic> item) async {
    final noController = TextEditingController(
      text: item['no_transaksi'].toString(),
    );
    final tanggalController = TextEditingController(
      text: item['tgl_transaksi'],
    );
    final nilaiController = TextEditingController(
      text: item['nilai_transaksi'].toString(),
    );
    final keteranganController = TextEditingController(
      text: item['ket_transaksi'] ?? '',
    );
    String? selectedStatus = item['status'];

    if (selectedStatus == null || !['pm', 'pg'].contains(selectedStatus)) {
      selectedStatus = 'pm';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),

                        // Form Fields
                        _buildEditTextField(
                          controller: noController,
                          label: 'No. Transaksi',
                          icon: Icons.receipt_long,
                        ),
                        const SizedBox(height: 16),

                        _buildEditTextField(
                          controller: tanggalController,
                          label: 'Tanggal (YYYY-MM-DD)',
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.datetime,
                        ),
                        const SizedBox(height: 16),

                        _buildEditTextField(
                          controller: nilaiController,
                          label: 'Nilai Transaksi',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        _buildEditTextField(
                          controller: keteranganController,
                          label: 'Keterangan',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Status Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status Transaksi',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade700,
                              ),
                              prefixIcon: const Icon(
                                Icons.swap_vert,
                                color: Colors.teal,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pm',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Pemasukan'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'pg',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_down,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Pengeluaran'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value;
                              });
                            },
                            dropdownColor: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
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
                                    final no = noController.text.trim();
                                    final tanggal = tanggalController.text
                                        .trim();
                                    final nilaiText = nilaiController.text
                                        .trim();
                                    final keterangan = keteranganController.text
                                        .trim();

                                    if (no.isEmpty ||
                                        tanggal.isEmpty ||
                                        nilaiText.isEmpty ||
                                        selectedStatus == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.warning,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Semua field wajib diisi!'),
                                            ],
                                          ),
                                          backgroundColor: Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    double nilai;
                                    try {
                                      nilai = double.parse(nilaiText);
                                      if (nilai <= 0) {
                                        throw 'Nilai harus lebih dari 0';
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.error,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Nilai transaksi harus angka yang valid!',
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.pop(dialogContext);

                                    await updateTransaction(
                                      id: int.parse(
                                        item['no_transaksi'].toString(),
                                      ),
                                      noTransaksi: no,
                                      tanggal: tanggal,
                                      nilai: nilai,
                                      keterangan: keterangan,
                                      status: selectedStatus!,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.save,
                                        color: Colors.white,
                                        size: 20,
                                      ),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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

  Future<void> deleteTransaction(int id) async {
    final url = Uri.parse(
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/transactions.php/$id',
    );

    try {
      print('DELETE - URL: $url');
      print('DELETE - ID: $id');

      final response = await http
          .delete(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('DELETE - Response Status: ${response.statusCode}');
      print('DELETE - Response Body: ${response.body}');

      if (response.body.isEmpty) {
        throw 'Server tidak memberikan response';
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.delete_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Transaksi berhasil dihapus!'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        await fetchTransaksi(); // Refresh data
      } else {
        String errorMessage = 'Gagal menghapus transaksi';

        switch (response.statusCode) {
          case 403:
            errorMessage =
                'Akses ditolak. Hanya Admin yang bisa menghapus transaksi.';
            break;
          case 404:
            errorMessage = 'Transaksi tidak ditemukan.';
            break;
          case 500:
            errorMessage = data['message'] ?? 'Terjadi kesalahan di server.';
            break;
          default:
            if (data['message'] != null) {
              errorMessage = data['message'];
            }
        }

        throw errorMessage;
      }
    } on TimeoutException catch (e) {
      print('DELETE - Timeout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timeout. Periksa koneksi internet.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('DELETE - Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Konfirmasi Hapus'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yakin ingin menghapus transaksi berikut?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['ket_transaksi'] ?? 'Tidak ada keterangan'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Nilai: Rp ${item['nilai_transaksi']}'),
                  Text('Tanggal: ${item['tgl_transaksi']}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aksi ini tidak dapat dibatalkan.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteTransaction(int.parse(item['no_transaksi'].toString()));
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 18,
                          ),
                          onPressed: () {
                            _showEditTransactionDialog(item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () {
                            _confirmDelete(item);
                          },
                        ),
                      ],
                    ),
                    onTap: () => _showDetailPopup(item),
                  ),
                );
              },
            ),
    );
  }
}
