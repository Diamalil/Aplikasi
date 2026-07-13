import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final _backupService = BackupService();
  final _formatTanggal = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  bool _isBackingUp = false;
  bool _isRestoring = false;
  List<FileSystemEntity> _daftarBackup = [];
  bool _isLoadingDaftar = true;

  @override
  void initState() {
    super.initState();
    _loadDaftarBackup();
  }

  Future<void> _loadDaftarBackup() async {
    setState(() => _isLoadingDaftar = true);
    final daftar = await _backupService.getDaftarBackup();
    setState(() {
      _daftarBackup = daftar;
      _isLoadingDaftar = false;
    });
  }

  Future<void> _backup() async {
    setState(() => _isBackingUp = true);
    try {
      final path = await _backupService.backup();
      if (!mounted) return;
      _showSnackBar('Backup berhasil!\n$path', berhasil: true);
      _loadDaftarBackup();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Backup gagal: $e', berhasil: false);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restore(String pathFile) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 40,
        ),
        title: const Text('Restore Database?'),
        content: const Text(
          'Semua data yang ada sekarang akan diganti '
          'dengan data dari file backup ini.\n\n'
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _isRestoring = true);
    try {
      await _backupService.restore(pathFile);
      if (!mounted) return;
      _showSnackBar(
        'Restore berhasil! Restart aplikasi untuk melihat data.',
        berhasil: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Restore gagal: $e', berhasil: false);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _hapusBackup(String path) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus File Backup?'),
        content: const Text('File backup ini akan dihapus permanen.'),
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
    await _backupService.hapusBackup(path);
    _loadDaftarBackup();
  }

  void _showSnackBar(String pesan, {required bool berhasil}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: berhasil ? Colors.green : Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Data & Backup'),
          const SizedBox(height: 12),

          // Kartu Backup
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.upload_outlined,
                          color: Colors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Backup Data',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simpan salinan database ke penyimpanan perangkat.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isBackingUp ? null : _backup,
                      icon: _isBackingUp
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
                        _isBackingUp ? 'Menyimpan...' : 'Backup Sekarang',
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Daftar File Backup
          _buildSectionHeader('File Backup Tersedia'),
          const SizedBox(height: 12),

          _isLoadingDaftar
              ? const Center(child: CircularProgressIndicator())
              : _daftarBackup.isEmpty
                  ? Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 40,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada file backup',
                                style: TextStyle(color: colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: _daftarBackup.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          final namaFile = file.path.split('/').last;

                          String labelTanggal = namaFile;
                          try {
                            final bagian = namaFile
                                .replaceAll('buku_kas_', '')
                                .replaceAll('.db', '')
                                .split('_');
                            if (bagian.length == 2) {
                              final tgl = bagian[0];
                              final jam = bagian[1].replaceAll('-', ':');
                              final dt = DateTime.parse('${tgl}T$jam');
                              labelTanggal = _formatTanggal.format(dt);
                            }
                          } catch (_) {}

                          return Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.storage_outlined,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  labelTanggal,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  namaFile,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: _isRestoring
                                          ? null
                                          : () => _restore(file.path),
                                      icon: const Icon(
                                        Icons.restore_outlined,
                                        color: Colors.orange,
                                      ),
                                      tooltip: 'Restore',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _hapusBackup(file.path),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Hapus',
                                    ),
                                  ],
                                ),
                              ),
                              if (index < _daftarBackup.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 56,
                                  color: colorScheme.outlineVariant,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

          const SizedBox(height: 24),

          _buildSectionHeader('Informasi'),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                _buildBarisInfo(
                  icon: Icons.info_outline,
                  label: 'Versi Aplikasi',
                  nilai: '1.0.0',
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outlineVariant,
                ),
                _buildBarisInfo(
                  icon: Icons.storage_outlined,
                  label: 'Database',
                  nilai: 'SQLite',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String judul) {
    return Text(
      judul,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBarisInfo({
    required IconData icon,
    required String label,
    required String nilai,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        nilai,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}