import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';
import '../services/transaksi_service.dart';

class EditTransaksiPage extends StatefulWidget {
  final Transaksi transaksi;

  const EditTransaksiPage({super.key, required this.transaksi});

  @override
  State<EditTransaksiPage> createState() => _EditTransaksiPageState();
}

class _EditTransaksiPageState extends State<EditTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = TransaksiService();
  late TextEditingController _keteranganController;
  late TextEditingController _nominalController;

  late DateTime _tanggalDipilih;
  late String _jenisDipilih;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form dengan data transaksi yang ada
    final t = widget.transaksi;
    _keteranganController = TextEditingController(text: t.keterangan);
    _nominalController = TextEditingController(
      text: t.nominal.toStringAsFixed(0),
    );
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

  // ─────────────────────────────────────────────────────────────────
  // PERBAIKAN: _isLoading tidak pernah di-reset ke false saat sukses.
  //
  // Sebelumnya, setState(() => _isLoading = false) HANYA ada di blok
  // catch (error). Jika update berhasil, _isLoading tetap true sampai
  // Navigator.pop dipanggil. Ini tidak crash, tapi tidak rapi dan bisa
  // menyebabkan bug jika pop tidak terpanggil karena !mounted.
  //
  // SOLUSI: Tambahkan setState(_isLoading = false) sebelum Navigator.pop
  // di blok sukses, dan pastikan selalu ada di catch juga.
  // ─────────────────────────────────────────────────────────────────
  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Buat objek baru dengan data yang sudah diedit
      // copyWith() mempertahankan field yang tidak diubah (terutama id)
      final updated = widget.transaksi.copyWith(
        tanggal: DateFormat('yyyy-MM-dd').format(_tanggalDipilih),
        keterangan: _keteranganController.text.trim(),
        jenis: _jenisDipilih,
        nominal: double.parse(
          _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
        ),
      );

      await _service.updateTransaksi(updated);

      if (!mounted) return;

      // Reset loading sebelum pop (best practice: state selalu bersih)
      setState(() => _isLoading = false);

      // Kirim true sebagai sinyal bahwa data berhasil diupdate
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      // Reset loading agar user bisa mencoba lagi
      setState(() => _isLoading = false);

      // Tampilkan pesan error ke user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan perubahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Fungsi hapus transaksi — dipanggil dari dialog konfirmasi
  // ─────────────────────────────────────────────────────────────────
  Future<void> _hapus() async {
    // Tampilkan dialog konfirmasi sebelum menghapus
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Transaksi ini akan dihapus permanen dan tidak bisa dikembalikan.',
        ),
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
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _service.hapusTransaksi(widget.transaksi.id!);

      if (!mounted) return;
      // Kirim 'deleted' sebagai sinyal khusus penghapusan
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
          'Edit Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Tombol hapus di AppBar
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _hapus,
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            tooltip: 'Hapus Transaksi',
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
              decoration: _inputDecoration('Contoh: Gaji Bulanan'),
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