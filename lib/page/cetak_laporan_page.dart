import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CetakLaporanPage extends StatefulWidget {
  const CetakLaporanPage({super.key});

  @override
  _CetakLaporanPageState createState() => _CetakLaporanPageState();
}

class _CetakLaporanPageState extends State<CetakLaporanPage> {
  List<dynamic> transactions = [];
  bool isLoading = false;
  bool isPrinting = false;
  DateTimeRange? dateRange;
  final String apiUrl =
      'https://fa27f666e9d0.ngrok-free.app/BackendApliksiKeuangan/api/transactions.php/report';

  @override
  void initState() {
    super.initState();
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    setState(() {
      isLoading = true;
    });

    String startDate = dateRange?.start != null
        ? DateFormat('yyyy-MM-dd').format(dateRange!.start)
        : DateFormat('yyyy-MM-01').format(DateTime.now());
    String endDate = dateRange?.end != null
        ? DateFormat('yyyy-MM-dd').format(dateRange!.end)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$apiUrl?start=$startDate&end=$endDate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Untuk ngrok
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            transactions = data['data'] ?? [];
            isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load report: ${data['message'] ?? 'Unknown error'}',
              ),
            ),
          );
          setState(() {
            isLoading = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load report: HTTP ${response.statusCode}'),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange:
          dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );

    if (picked != null && picked != dateRange) {
      setState(() {
        dateRange = picked;
      });
      fetchReportData();
    }
  }

  void _cetakLaporan() async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk dicetak')),
      );
      return;
    }

    setState(() {
      isPrinting = true;
    });

    try {
      final pdf = pw.Document();

      double totalPemasukan = 0;
      double totalPengeluaran = 0;
      for (var tx in transactions) {
        if (tx['status'] == 'pm') {
          totalPemasukan += (tx['nilai_transaksi'] ?? 0).toDouble();
        } else {
          totalPengeluaran += (tx['nilai_transaksi'] ?? 0).toDouble();
        }
      }
      double saldo = totalPemasukan - totalPengeluaran;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Center(
              child: pw.Text(
                'LAPORAN TRANSAKSI KEUANGAN',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Periode: ${dateRange != null ? '${DateFormat('dd MMM yyyy').format(dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(dateRange!.end)}' : 'Semua Data'}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RINGKASAN',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Pemasukan:'),
                      pw.Text(
                        'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '').format(totalPemasukan)}',
                        style: const pw.TextStyle(color: PdfColors.green),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Pengeluaran:'),
                      pw.Text(
                        'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '').format(totalPengeluaran)}',
                        style: const pw.TextStyle(color: PdfColors.red),
                      ),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Saldo:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '').format(saldo)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: saldo >= 0 ? PdfColors.green : PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'DETAIL TRANSAKSI',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: [
                'No',
                'Tanggal',
                'Keterangan',
                'Nominal (Rp)',
                'Status',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 25,
              data: transactions.asMap().entries.map((entry) {
                int index = entry.key;
                var tx = entry.value;
                final tanggal = DateFormat('dd/MM/yyyy').format(
                  DateTime.parse(
                    tx['tgl_transaksi'] ?? DateTime.now().toString(),
                  ),
                );
                final keterangan = (tx['ket_transaksi'] ?? '').toString();
                final nominal = NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: '',
                  decimalDigits: 0,
                ).format(tx['nilai_transaksi'] ?? 0);
                final status = tx['status'] == 'pm'
                    ? 'Pemasukan'
                    : 'Pengeluaran';

                return [
                  (index + 1).toString(),
                  tanggal,
                  keterangan.length > 25
                      ? '${keterangan.substring(0, 25)}...'
                      : keterangan,
                  nominal,
                  status,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Transaksi: ${transactions.length}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Dicetak pada: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final filename =
          'Laporan_Transaksi_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan siap dilihat atau disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat laporan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Laporan Transaksi'),
        elevation: 0,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.print),
            tooltip: 'Cetak Laporan',
            onPressed: isPrinting ? null : _cetakLaporan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () => _selectDateRange(context),
              icon: const Icon(Icons.date_range),
              label: Text(
                dateRange == null
                    ? 'Pilih Rentang Tanggal'
                    : '${DateFormat('dd MMM yyyy').format(dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(dateRange!.end)}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (transactions.isNotEmpty && !isLoading) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Transaksi:'),
                          Text('${transactions.length}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pemasukan:'),
                          Text(
                            'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '').format(transactions.where((tx) => tx['status'] == 'pm').fold(0.0, (sum, tx) => sum + (tx['nilai_transaksi'] ?? 0)))}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pengeluaran:'),
                          Text(
                            'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '').format(transactions.where((tx) => tx['status'] == 'pg').fold(0.0, (sum, tx) => sum + (tx['nilai_transaksi'] ?? 0)))}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: transactions.isEmpty
                        ? const Center(
                            child: Text('Tidak ada transaksi ditemukan.'),
                          )
                        : ListView.builder(
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    transaction['ket_transaksi'] ??
                                        'Tidak ada keterangan',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Tanggal: ${DateFormat('dd MMM yyyy').format(DateTime.parse(transaction['tgl_transaksi'] ?? DateTime.now().toString()))}\n'
                                    'Nominal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '').format(transaction['nilai_transaksi'] ?? 0)}',
                                  ),
                                  trailing: Text(
                                    transaction['status'] == 'pm'
                                        ? 'Pemasukan'
                                        : 'Pengeluaran',
                                    style: TextStyle(
                                      color: transaction['status'] == 'pm'
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
