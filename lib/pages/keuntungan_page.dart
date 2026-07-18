import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';
import '../services/keuntungan_service.dart';
import 'tambah_transaksi_page.dart';
import 'edit_transaksi_page.dart';

class KeuntunganPage extends StatefulWidget {
  const KeuntunganPage({super.key});

  @override
  State<KeuntunganPage> createState() => _KeuntunganPageState();
}

class _KeuntunganPageState extends State<KeuntunganPage> {
  final _service = KeuntunganService();

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final ringkasan = await _service.getRingkasan();
    final transaksi = await _service.getSemuaKeuntungan();

    setState(() {
      _saldo = ringkasan['saldo']!;
      _totalMasuk = ringkasan['totalMasuk']!;
      _totalKeluar = ringkasan['totalKeluar']!;
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
          'Keuntungan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahKeuntunganPage(
                service: _service,
              ),
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
        color: Colors.teal.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Keuntungan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah.format(_saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
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
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditKeuntunganPage(
                    transaksi: t,
                    service: _service,
                  ),
                ),
              );
              if (result == true || result == 'deleted') _loadData();
            },
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

// ─────────────────────────────────────────────────────────────────
// Form Tambah — khusus untuk tabel keuntungan
// Reuse UI dari TambahTransaksiPage tapi service-nya KeuntunganService
// ─────────────────────────────────────────────────────────────────
class TambahKeuntunganPage extends StatefulWidget {
  final KeuntunganService service;

  const TambahKeuntunganPage({super.key, required this.service});

  @override
  State<TambahKeuntunganPage> createState() => _TambahKeuntunganPageState();
}

class _TambahKeuntunganPageState extends State<TambahKeuntunganPage> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _nominalController = TextEditingController();

  DateTime _tanggalDipilih = DateTime.now();
  String _jenisDipilih = 'Masuk';
  bool _isLoading = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalDipilih,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _tanggalDipilih = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final transaksi = Transaksi(
        tanggal: DateFormat('yyyy-MM-dd').format(_tanggalDipilih),
        keterangan: _keteranganController.text.trim(),
        jenis: _jenisDipilih,
        nominal: double.parse(
          _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
        ),
      );

      await widget.service.tambah(transaksi);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Keuntungan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLabel('Tanggal'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                          .format(_tanggalDipilih),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Jenis Transaksi'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Masuk',
                  label: Text('Masuk'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: 'Keluar',
                  label: Text('Keluar'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
              ],
              selected: {_jenisDipilih},
              onSelectionChanged: (val) {
                setState(() => _jenisDipilih = val.first);
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Keterangan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _keteranganController,
              decoration: _inputDecoration('Contoh: Penjualan Hari Ini'),
              textCapitalization: TextCapitalization.sentences,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Keterangan tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Nominal'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nominalController,
              decoration: _inputDecoration('Contoh: 500000').copyWith(
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nominal tidak boleh kosong';
                }
                final angka = double.tryParse(
                  val.replaceAll('.', '').replaceAll(',', ''),
                );
                if (angka == null || angka <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _simpan,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isLoading ? 'Menyimpan...' : 'Simpan',
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Form Edit — khusus untuk tabel keuntungan
// ─────────────────────────────────────────────────────────────────
class EditKeuntunganPage extends StatefulWidget {
  final Transaksi transaksi;
  final KeuntunganService service;

  const EditKeuntunganPage({
    super.key,
    required this.transaksi,
    required this.service,
  });

  @override
  State<EditKeuntunganPage> createState() => _EditKeuntunganPageState();
}

class _EditKeuntunganPageState extends State<EditKeuntunganPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keteranganController;
  late TextEditingController _nominalController;

  late DateTime _tanggalDipilih;
  late String _jenisDipilih;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaksi;
    _keteranganController = TextEditingController(text: t.keterangan);
    _nominalController =
        TextEditingController(text: t.nominal.toStringAsFixed(0));
    _tanggalDipilih = DateTime.parse(t.tanggal);
    _jenisDipilih = t.jenis;
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalDipilih,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _tanggalDipilih = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updated = widget.transaksi.copyWith(
        tanggal: DateFormat('yyyy-MM-dd').format(_tanggalDipilih),
        keterangan: _keteranganController.text.trim(),
        jenis: _jenisDipilih,
        nominal: double.parse(
          _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
        ),
      );

      await widget.service.update(updated);

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _hapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Data ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _isLoading = true);
    try {
      await widget.service.hapus(widget.transaksi.id!);
      if (!mounted) return;
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Keuntungan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _hapus,
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLabel('Tanggal'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                          .format(_tanggalDipilih),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Jenis Transaksi'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Masuk',
                  label: Text('Masuk'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: 'Keluar',
                  label: Text('Keluar'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
              ],
              selected: {_jenisDipilih},
              onSelectionChanged: (val) {
                setState(() => _jenisDipilih = val.first);
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Keterangan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _keteranganController,
              decoration: _inputDecoration('Contoh: Penjualan Hari Ini'),
              textCapitalization: TextCapitalization.sentences,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Keterangan tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Nominal'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nominalController,
              decoration: _inputDecoration('Contoh: 500000').copyWith(
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nominal tidak boleh kosong';
                }
                final angka = double.tryParse(
                  val.replaceAll('.', '').replaceAll(',', ''),
                );
                if (angka == null || angka <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _simpan,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}