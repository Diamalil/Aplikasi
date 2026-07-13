import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton: hanya boleh ada 1 instance DatabaseHelper di seluruh aplikasi
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  // Private constructor — mencegah pembuatan instance dari luar class
  DatabaseHelper._init();

  // Getter dengan lazy initialization
  // Artinya: database baru dibuka saat pertama kali dibutuhkan, bukan saat app launch
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('buku_kas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // getDatabasesPath() → lokasi default penyimpanan DB di Android/iOS
    final dbPath = await getDatabasesPath();

    // join() dari package:path → menggabungkan path dengan aman lintas OS
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // ← siap untuk migrasi schema di masa depan
    );
  }

  // Dipanggil sekali saat database pertama kali dibuat
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transaksi (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal     TEXT    NOT NULL,
        keterangan  TEXT    NOT NULL,
        jenis       TEXT    NOT NULL,
        nominal     REAL    NOT NULL
      )
    ''');

     await db.execute('''
       CREATE TABLE keuntungan (
         id          INTEGER PRIMARY KEY AUTOINCREMENT,
         tanggal     TEXT    NOT NULL,
         keterangan  TEXT    NOT NULL,
         jenis       TEXT    NOT NULL,
         nominal     REAL    NOT NULL
       )
     ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE keuntungan (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          tanggal     TEXT    NOT NULL,
          keterangan  TEXT    NOT NULL,
          jenis       TEXT    NOT NULL,
          nominal     REAL    NOT NULL
        )
      ''');
    }
  }

  Future close() async {
  if (_database != null) {
    await _database!.close();
    _database = null; // ← wajib! agar database bisa dibuka ulang
    }
  }
}