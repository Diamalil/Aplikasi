import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';
import '../services/transaksi_service.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _service = TransaksiService();

  // Default: laporan bulan ini
  DateTime _dareTanggal = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _sampaiTanggal = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0, // hari terakhir bulan ini
  );

  List<Transaksi> _transaksi = [];
  bool _isLoading = true;

  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _formatTanggal = DateFormat('d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final data = await _service.getTransaksiByRentangTanggal(
      dari: DateFormat('yyyy-MM-dd').format(_dareTanggal),
      sampai: DateFormat('yyyy-MM-dd').format(_sampaiTanggal),
    );

    setState(() {
      _transaksi = data;
      _isLoading = false;
    });
  }

  Future<void> _pilihTanggal({required bool isDari}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDari ? _dareTanggal : _sampaiTanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isDari) {
          _dareTanggal = picked;
          // Pastikan tanggal awal tidak melebihi tanggal akhir
          if (_dareTanggal.isAfter(_sampaiTanggal)) {
            _sampaiTanggal = picked;
          }
        } else {
          _sampaiTanggal = picked;
          if (_sampaiTanggal.isBefore(_dareTanggal)) {
            _dareTanggal = picked;
          }
        }
      });
      _loadData();
    }
  }

  // Hitung total dari list transaksi yang sudah difilter
  double get _totalMasuk => _transaksi
      .where((t) => t.jenis == 'Masuk')
      .fold(0, (sum, t) => sum + t.nominal);

  double get _totalKeluar => _transaksi
      .where((t) => t.jenis == 'Keluar')
      .fold(0, (sum, t) => sum + t.nominal);

  double get _saldo => _totalMasuk - _totalKeluar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ── FILTER TANGGAL ────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: _buildTombolTanggal(
                    label: 'Dari',
                    tanggal: _dareTanggal,
                    onTap: () => _pilihTanggal(isDari: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—'),
                ),
                Expanded(
                  child: _buildTombolTanggal(
                    label: 'Sampai',
                    tanggal: _sampaiTanggal,
                    onTap: () => _pilihTanggal(isDari: false),
                  ),
                ),
              ],
            ),
          ),

          // ── KONTEN ───────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Kartu Rekap
                      _buildKartuRekap(colorScheme),
                      const SizedBox(height: 24),

                      // Header list transaksi
                      Text(
                        'Detail Transaksi (${_transaksi.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // List transaksi dalam periode
                      if (_transaksi.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.search_off_outlined,
                                    size: 48, color: colorScheme.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada transaksi\npada periode ini',
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(color: colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._transaksi.map((t) {
                          final isMasuk = t.jenis == 'Masuk';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: colorScheme.outlineVariant),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isMasuk
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                _formatTanggal.format(
                                    DateTime.parse(t.tanggal)),
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Kartu rekap total masuk, keluar, saldo
  Widget _buildKartuRekap(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildBarisStat('Total Masuk', _totalMasuk, Colors.green.shade700),
          const Divider(height: 16),
          _buildBarisStat('Total Keluar', _totalKeluar, Colors.red.shade700),
          const Divider(height: 16),
          _buildBarisStat(
            'Saldo Periode',
            _saldo,
            _saldo >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBarisStat(String label, double nominal, Color warna,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 14,
          ),
        ),
        Text(
          _formatRupiah.format(nominal),
          style: TextStyle(
            color: warna,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 15 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTombolTanggal({
    required String label,
    required DateTime tanggal,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTanggal.format(tanggal),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}