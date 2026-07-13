import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupService {
  static const String _namaDB = 'buku_kas.db';

  // Folder tempat backup disimpan dan dicari saat restore
  // Contoh: /storage/emulated/0/Android/data/com.example.buku_kas/files/
  Future<Directory> _getFolderBackup() async {
    final eksternalDir = await getExternalStorageDirectory();
    if (eksternalDir == null) {
      throw Exception('Tidak bisa akses penyimpanan eksternal');
    }
    // Buat subfolder BukuKas agar lebih rapi
    final folder = Directory(join(eksternalDir.path, 'BukuKasBackup'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  // ─────────────────────────────────────────
  // BACKUP
  // ─────────────────────────────────────────
  Future<String> backup() async {
    try {
      await DatabaseHelper.instance.close();

      final dbPath = await getDatabasesPath();
      final sourceFile = File(join(dbPath, _namaDB));

      if (!await sourceFile.exists()) {
        throw Exception('File database tidak ditemukan');
      }

      final folderBackup = await _getFolderBackup();

      // Nama file dengan timestamp
      final sekarang = DateTime.now();
      final namaBackup = 'buku_kas_'
          '${sekarang.year}-'
          '${sekarang.month.toString().padLeft(2, '0')}-'
          '${sekarang.day.toString().padLeft(2, '0')}_'
          '${sekarang.hour.toString().padLeft(2, '0')}-'
          '${sekarang.minute.toString().padLeft(2, '0')}'
          '.db';

      final destinasi = File(join(folderBackup.path, namaBackup));
      await sourceFile.copy(destinasi.path);

      await DatabaseHelper.instance.database;

      return destinasi.path;
    } catch (e) {
      await DatabaseHelper.instance.database;
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // AMBIL DAFTAR FILE BACKUP
  // Ditampilkan ke user agar bisa memilih mana yang mau di-restore
  // ─────────────────────────────────────────
  Future<List<FileSystemEntity>> getDaftarBackup() async {
  final folder = await _getFolderBackup();
  
  // Debug: lihat path yang dicari
  print('Path folder backup: ${folder.path}');
  
  if (!await folder.exists()) {
    print('Folder tidak ada!');
    return [];
  }

  final files = await folder
      .list()
      .where((f) => f.path.endsWith('.db'))
      .toList();

  print('Jumlah file ditemukan: ${files.length}');
  
  files.sort((a, b) => b.path.compareTo(a.path));
  return files;
}

  // ─────────────────────────────────────────
  // RESTORE
  // User memilih file dari daftar backup yang tersedia
  // ─────────────────────────────────────────
  Future<void> restore(String pathFileBackup) async {
    final fileRestore = File(pathFileBackup);

    if (!await fileRestore.exists()) {
      throw Exception('File backup tidak ditemukan');
    }

    try {
      await DatabaseHelper.instance.close();

      final dbPath = await getDatabasesPath();
      final dbAktif = File(join(dbPath, _namaDB));

      await fileRestore.copy(dbAktif.path);

      await DatabaseHelper.instance.database;
    } catch (e) {
      await DatabaseHelper.instance.database;
      rethrow;
    }
  }

  // Hapus file backup tertentu
  Future<void> hapusBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}