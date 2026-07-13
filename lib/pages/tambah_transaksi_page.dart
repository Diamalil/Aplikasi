import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';
import '../services/transaksi_service.dart';

class TambahTransaksiPage extends StatefulWidget {
  const TambahTransaksiPage({super.key});

  @override
  State<TambahTransaksiPage> createState() => _TambahTransaksiPageState();
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _nominalController = TextEditingController();
  final _service = TransaksiService();

  DateTime _tanggalDipilih = DateTime.now();
  String _jenisDipilih = 'Masuk';
  bool _isLoading = false;

  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
    if (picked != null) {
      setState(() => _tanggalDipilih = picked);
    }
  }

  Future<void> _simpan() async {
    Future<void> _simpan() async {
  print("A");

  if (!_formKey.currentState!.validate()) return;

  print("B");

  setState(() => _isLoading = true);

  final transaksi = Transaksi(
    tanggal: DateFormat('yyyy-MM-dd').format(_tanggalDipilih),
    keterangan: _keteranganController.text.trim(),
    jenis: _jenisDipilih,
    nominal: double.parse(
      _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
    ),
  );

  print("C");

  final hasil = await _service.tambahTransaksi(transaksi);

  print("D -> $hasil");

  if (!mounted) return;

  print("E");

  Navigator.pop(context, true);
}

    final transaksi = Transaksi(
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggalDipilih),
      keterangan: _keteranganController.text.trim(),
      jenis: _jenisDipilih,
      nominal: double.parse(
        _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
      ),
    );

    await _service.tambahTransaksi(transaksi);

    setState(() => _isLoading = false);

    // mounted: cek apakah widget masih ada di layar sebelum Navigator.pop
    // Penting untuk menghindari error saat widget sudah di-dispose
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── FIELD TANGGAL ─────────────────────────
            _buildLabel('Tanggal'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
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

            // ── FIELD JENIS ───────────────────────────
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

            // ── FIELD KETERANGAN ──────────────────────
            _buildLabel('Keterangan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _keteranganController,
              decoration: _inputDecoration(
                'Contoh: Gaji Bulanan, Bayar Listrik',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Keterangan tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── FIELD NOMINAL ─────────────────────────
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

            // ── TOMBOL SIMPAN ─────────────────────────
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
                _isLoading ? 'Menyimpan...' : 'Simpan Transaksi',
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
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}