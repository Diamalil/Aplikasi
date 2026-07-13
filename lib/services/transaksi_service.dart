import '../database/database_helper.dart';
import '../models/transaksi.dart';

class TransaksiService {
  final dbHelper = DatabaseHelper.instance;

  // ─────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────

  Future<int> tambahTransaksi(Transaksi transaksi) async {
    final db = await dbHelper.database;
    return await db.insert('transaksi', transaksi.toMap());
  }

  // ─────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────

  // Ambil semua transaksi, urut dari terbaru
  Future<List<Transaksi>> getSemuaTransaksi() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transaksi',
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => Transaksi.fromMap(e)).toList();
  }

  // Ambil transaksi dalam rentang tanggal tertentu (untuk Laporan)
  // Format tanggal: 'YYYY-MM-DD'
  Future<List<Transaksi>> getTransaksiByRentangTanggal({
    required String dari,
    required String sampai,
  }) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transaksi',
      where: 'tanggal BETWEEN ? AND ?',
      whereArgs: [dari, sampai],
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => Transaksi.fromMap(e)).toList();
  }

  // Hitung ringkasan untuk Dashboard
  // Mengembalikan Map berisi totalMasuk, totalKeluar, saldo
  Future<Map<String, double>> getRingkasan() async {
    final db = await dbHelper.database;

    // SQL aggregate: SUM(nominal) dikelompokkan per jenis
    // COALESCE(..., 0) → kalau belum ada transaksi, return 0 bukan null
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN jenis = 'Masuk'  THEN nominal ELSE 0 END), 0) AS totalMasuk,
        COALESCE(SUM(CASE WHEN jenis = 'Keluar' THEN nominal ELSE 0 END), 0) AS totalKeluar
      FROM transaksi
    ''');

    // result selalu punya 1 baris karena ini aggregate query
    final row = result.first;
    final totalMasuk  = (row['totalMasuk']  as num).toDouble();
    final totalKeluar = (row['totalKeluar'] as num).toDouble();

    return {
      'totalMasuk'  : totalMasuk,
      'totalKeluar' : totalKeluar,
      'saldo'       : totalMasuk - totalKeluar,
    };
  }

  // ─────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────

  Future<int> updateTransaksi(Transaksi transaksi) async {
    final db = await dbHelper.database;
    return await db.update(
      'transaksi',
      transaksi.toMap(),
      where: 'id = ?',
      whereArgs: [transaksi.id],
    );
  }

  // ─────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────

  Future<int> hapusTransaksi(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}