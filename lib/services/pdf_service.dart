import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaksi.dart';

class PdfService {
  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _formatTanggal = DateFormat('d MMM yyyy', 'id_ID');

  Future<void> exportLaporan({
    required List<Transaksi> transaksi,
    required DateTime dari,
    required DateTime sampai,
    required String judul,
  }) async {
    final pdf = pw.Document();

  
    final totalMasuk = transaksi
        .where((t) => t.jenis == 'Masuk')
        .fold(0.0, (sum, t) => sum + t.nominal);
    final totalKeluar = transaksi
        .where((t) => t.jenis == 'Keluar')
        .fold(0.0, (sum, t) => sum + t.nominal);
    final saldo = totalMasuk - totalKeluar;

    final periodeText =
        '${_formatTanggal.format(dari)} - ${_formatTanggal.format(sampai)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
        
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  judul,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Periode: $periodeText',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'Dicetak: ${_formatTanggal.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

        
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _buildBarisStat('Total Masuk', totalMasuk, PdfColors.green700),
                pw.Divider(color: PdfColors.grey300),
                _buildBarisStat('Total Keluar', totalKeluar, PdfColors.red700),
                pw.Divider(color: PdfColors.grey300),
                _buildBarisStat(
                  'Saldo',
                  saldo,
                  saldo >= 0 ? PdfColors.green700 : PdfColors.red700,
                  isBold: true,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

       
          pw.Text(
            'Detail Transaksi (${transaksi.length})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          transaksi.isEmpty
              ? pw.Center(
                  child: pw.Text(
                    'Tidak ada transaksi pada periode ini',
                    style: const pw.TextStyle(color: PdfColors.grey),
                  ),
                )
              : pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(2.5),
                  },
                  children: [
            
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildCellHeader('Tanggal'),
                        _buildCellHeader('Keterangan'),
                        _buildCellHeader('Jenis'),
                        _buildCellHeader('Nominal'),
                      ],
                    ),
          
                    ...transaksi.map((t) {
                      final isMasuk = t.jenis == 'Masuk';
                      return pw.TableRow(
                        children: [
                          _buildCell(
                            _formatTanggal.format(DateTime.parse(t.tanggal)),
                          ),
                          _buildCell(t.keterangan),
                          _buildCell(
                            t.jenis,
                            color: isMasuk
                                ? PdfColors.green700
                                : PdfColors.red700,
                          ),
                          _buildCell(
                            '${isMasuk ? '+' : '-'}${_formatRupiah.format(t.nominal)}',
                            color: isMasuk
                                ? PdfColors.green700
                                : PdfColors.red700,
                            align: pw.TextAlign.right,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
        ],
      ),
    );

  
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '$judul - $periodeText.pdf',
    );
  }

  pw.Widget _buildBarisStat(
    String label,
    double nominal,
    PdfColor warna, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          _formatRupiah.format(nominal),
          style: pw.TextStyle(
            color: warna,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  pw.Widget _buildCell(
    String text, {
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          color: color,
        ),
      ),
    );
  }
}
