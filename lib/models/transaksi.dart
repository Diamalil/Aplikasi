
class Transaksi {
  final int? id;           
  final String tanggal;   
  final String keterangan;
  final String jenis;
  final double nominal;

  Transaksi({
    this.id,
    required this.tanggal,
    required this.keterangan,
    required this.jenis,
    required this.nominal,
  });


  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': tanggal,
      'keterangan': keterangan,
      'jenis': jenis,
      'nominal': nominal,
    };
  }


  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'] as int?,
      tanggal: map['tanggal'] as String,
      keterangan: map['keterangan'] as String,
      jenis: map['jenis'] as String,
      nominal: (map['nominal'] as num).toDouble(),
    );
  }


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

 
  @override
  String toString() {
    return 'Transaksi(id: $id, tanggal: $tanggal, keterangan: $keterangan, '
        'jenis: $jenis, nominal: $nominal)';
  }
}
