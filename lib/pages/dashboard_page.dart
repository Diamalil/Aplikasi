import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';
import '../services/transaksi_service.dart';
import 'tambah_transaksi_page.dart';
import 'transaksi_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _service = TransaksiService();

  // State data dari SQLite
  double _saldo = 0;
  double _totalMasuk = 0;
  double _totalKeluar = 0;
  List<Transaksi> _transaksiTerbaru = [];
  bool _isLoading = true;

  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // initState dipanggil sekali saat widget pertama kali dibuat
    _loadData();
  }

  // Ambil semua data dari SQLite
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final ringkasan = await _service.getRingkasan();
    final transaksi = await _service.getSemuaTransaksi();

    setState(() {
      _saldo = ringkasan['saldo']!;
      _totalMasuk = ringkasan['totalMasuk']!;
      _totalKeluar = ringkasan['totalKeluar']!;
      // Tampilkan 5 transaksi terbaru saja di Dashboard
      _transaksiTerbaru = transaksi.take(5).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buku Kas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Tunggu hasil dari TambahTransaksiPage
          // Kalau hasil = true, berarti ada transaksi baru → reload data
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TambahTransaksiPage(),
            ),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildKartuSaldo(colorScheme),
                  const SizedBox(height: 16),
                  _buildKartuRingkasan(colorScheme),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi Terbaru',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransaksiPage(),
                            ),
                          );
                        },
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildListTransaksi(colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildKartuSaldo(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Saat Ini',
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah.format(_saldo),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuRingkasan(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildKartuStat(
            label: 'Total Masuk',
            nominal: _totalMasuk,
            icon: Icons.arrow_downward_rounded,
            warna: Colors.green.shade700,
            warnaBackground: Colors.green.shade50,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKartuStat(
            label: 'Total Keluar',
            nominal: _totalKeluar,
            icon: Icons.arrow_upward_rounded,
            warna: Colors.red.shade700,
            warnaBackground: Colors.red.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildKartuStat({
    required String label,
    required double nominal,
    required IconData icon,
    required Color warna,
    required Color warnaBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warnaBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: warna, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: warna,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah.format(nominal),
            style: TextStyle(
              color: warna,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTransaksi(ColorScheme colorScheme) {
    if (_transaksiTerbaru.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'Belum ada transaksi',
                style: TextStyle(color: colorScheme.outline),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap tombol Tambah untuk mulai',
                style: TextStyle(
                    fontSize: 12, color: colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _transaksiTerbaru.map((t) {
        final isMasuk = t.jenis == 'Masuk';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isMasuk ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isMasuk
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isMasuk
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                size: 20,
              ),
            ),
            title: Text(
              t.keterangan,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              t.tanggal,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              '${isMasuk ? '+' : '-'}${_formatRupiah.format(t.nominal)}',
              style: TextStyle(
                color: isMasuk
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}