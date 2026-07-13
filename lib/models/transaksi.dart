// Model Transaksi: representasi data satu baris di tabel SQLite
//
// PERBAIKAN: Hapus field 'kategori' karena:
// 1. Kolom 'kategori' tidak ada di tabel SQLite (CREATE TABLE tidak memilikinya)
// 2. toMap() mengirim 'kategori' ke db.insert() → potensi error di SQLite strict mode
// 3. Fitur kategori belum direncanakan, jadi jangan buat field yang tidak dipakai
//
// Prinsip: Model harus MENCERMINKAN schema database, bukan lebih.
// Jika nanti ingin tambah kategori, lakukan migration dulu di DatabaseHelper._upgradeDB()

class Transaksi {
  final int? id;           // null saat baru dibuat, diisi SQLite via AUTOINCREMENT
  final String tanggal;   // format: 'yyyy-MM-dd', contoh: '2026-06-30'
  final String keterangan;
  final String jenis;     // nilai: 'Masuk' atau 'Keluar'
  final double nominal;

  Transaksi({
    this.id,
    required this.tanggal,
    required this.keterangan,
    required this.jenis,
    required this.nominal,
  });

  // Konversi object ke Map untuk disimpan ke SQLite
  // Catatan: 'id' tidak dimasukkan jika null, agar AUTOINCREMENT bekerja
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,   // hanya kirim id saat UPDATE, bukan INSERT
      'tanggal': tanggal,
      'keterangan': keterangan,
      'jenis': jenis,
      'nominal': nominal,
    };
  }

  // Factory constructor: buat Transaksi dari hasil query SQLite
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'] as int?,
      tanggal: map['tanggal'] as String,
      keterangan: map['keterangan'] as String,
      jenis: map['jenis'] as String,
      nominal: (map['nominal'] as num).toDouble(),
    );
  }

  // Buat salinan object dengan beberapa field yang diubah
  // Digunakan di EditTransaksiPage untuk update data
  Transaksi copyWith({
    int? id,
    String? tanggal,
    String? keterangan,
    String? jenis,
    double? nominal,
  }) {
    return Transaksi(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      keterangan: keterangan ?? this.keterangan,
      jenis: jenis ?? this.jenis,
      nominal: nominal ?? this.nominal,
    );
  }

  // Berguna untuk debugging di console
  @override
  String toString() {
    return 'Transaksi(id: $id, tanggal: $tanggal, keterangan: $keterangan, '
        'jenis: $jenis, nominal: $nominal)';
  }
}