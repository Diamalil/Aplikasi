import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaksi.dart';
import '../services/transaksi_service.dart';
import 'tambah_transaksi_page.dart';
import 'edit_transaksi_page.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final _service = TransaksiService();

  List<Transaksi> _transaksi = [];
  bool _isLoading = true;

  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _tanggal = DateFormat('d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _service.getSemuaTransaksi();
    setState(() {
      _transaksi = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TambahTransaksiPage(),
            ),
          );
          if (result == true) _loadData();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _transaksi.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 250),
                        Center(child: Text('Belum ada transaksi')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _transaksi.length,
                      itemBuilder: (context, index) {
                        final t = _transaksi[index];
                        final masuk = t.jenis == 'Masuk';
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditTransaksiPage(transaksi: t),
                                ),
                              );
                              if (result == true || result == 'deleted') {
                                _loadData();
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: masuk
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              child: Icon(
                                masuk
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color:
                                    masuk ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(t.keterangan),
                            subtitle: Text(
                              _tanggal.format(DateTime.parse(t.tanggal)),
                            ),
                            trailing: Text(
                              '${masuk ? '+' : '-'}${_rupiah.format(t.nominal)}',
                              style: TextStyle(
                                color: masuk ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}