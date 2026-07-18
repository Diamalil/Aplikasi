import '../database/database_helper.dart';
import '../models/transaksi.dart';

class KeuntunganService {
  final dbHelper = DatabaseHelper.instance;

  // CREATE
  Future<int> tambah(Transaksi transaksi) async {
    final db = await dbHelper.database;
    return await db.insert('keuntungan', transaksi.toMap());
  }

  // READ — semua data
  Future<List<Transaksi>> getSemuaKeuntungan() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'keuntungan',
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => Transaksi.fromMap(e)).toList();
  }

  // READ — ringkasan untuk kartu saldo
  Future<Map<String, double>> getRingkasan() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN jenis = 'Masuk'  THEN nominal ELSE 0 END), 0) AS totalMasuk,
        COALESCE(SUM(CASE WHEN jenis = 'Keluar' THEN nominal ELSE 0 END), 0) AS totalKeluar
      FROM keuntungan
    ''');

    final row = result.first;
    final totalMasuk  = (row['totalMasuk']  as num).toDouble();
    final totalKeluar = (row['totalKeluar'] as num).toDouble();

    return {
      'totalMasuk'  : totalMasuk,
      'totalKeluar' : totalKeluar,
      'saldo'       : totalMasuk - totalKeluar,
    };
  }

  // UPDATE
  Future<int> update(Transaksi transaksi) async {
    final db = await dbHelper.database;
    return await db.update(
      'keuntungan',
      transaksi.toMap(),
      where: 'id = ?',
      whereArgs: [transaksi.id],
    );
  }

  // DELETE
  Future<int> hapus(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'keuntungan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}