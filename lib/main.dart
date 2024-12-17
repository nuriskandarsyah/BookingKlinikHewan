import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db/db_helper.dart';

void main() {
  runApp(BookingKlinikApp());
}

class BookingKlinikApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BookingPage(),
    );
  }
}

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final dbHelper = DatabaseHelper.instance;

  final _namaController = TextEditingController();
  final _kucingController = TextEditingController();
  final _tanggalController = TextEditingController();
  String? _selectedTreatment;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await dbHelper.getBookings();
    setState(() {
      _bookings = bookings;
    });
  }

  Future<void> _saveBooking() async {
    if (_namaController.text.isEmpty ||
        _kucingController.text.isEmpty ||
        _tanggalController.text.isEmpty ||
        _selectedTreatment == null) {
      _showSnackbar("Harap isi semua kolom!");
      return;
    }

    final biaya = _calculateTotal(_selectedTreatment!);

    final data = {
      'nama_pelanggan': _namaController.text,
      'nama_kucing': _kucingController.text,
      'tanggal_masuk': _tanggalController.text,
      'treatment': _selectedTreatment,
      'total_biaya': biaya,
    };

    if (_editId == null) {
      // Tambah data baru
      await dbHelper.addBooking(data);
      _showSnackbar("Data berhasil disimpan!");
    } else {
      // Edit data
      data['id'] = _editId;
      await dbHelper.updateBooking(data);
      _showSnackbar("Data berhasil diperbarui!");
    }

    _clearInput();
    _loadBookings();
    _showSnackbar("Data berhasil disimpan!");
  }

  int _calculateTotal(String treatment) {
    switch (treatment) {
      case 'Vaksin Komplit':
        return 150000;
      case 'Grooming':
        return 50000;
      case 'Grooming & Vaksin':
        return 200000;
      default:
        return 0;
    }
  }

  int? _editId;

  void _editBooking(Map<String, dynamic> booking) {
    setState(() {
      _editId = booking['id'];
      _namaController.text = booking['nama_pelanggan'];
      _kucingController.text = booking['nama_kucing'];
      _tanggalController.text = booking['tanggal_masuk'];
      _selectedTreatment = booking['treatment'];
    });
  }

  void _clearInput() {
    _namaController.clear();
    _kucingController.clear();
    _tanggalController.clear();
    _selectedTreatment = null;
    _editId = null;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> _deleteBooking(int id) async {
    await dbHelper.deleteBooking(id);
    _loadBookings();
    _showSnackbar("Data berhasil dihapus!");
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextField(
      controller: _tanggalController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Tanggal Masuk',
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          setState(() {
            _tanggalController.text =
                DateFormat('yyyy-MM-dd').format(pickedDate);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Klinik Hewan')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildTextField(_namaController, 'Nama Pelanggan'),
            SizedBox(height: 10),
            _buildTextField(_kucingController, 'Nama Kucing'),
            SizedBox(height: 10),
            _buildDatePicker(),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Treatment',
                border: OutlineInputBorder(),
              ),
              value: _selectedTreatment,
              items: ['Vaksin Komplit', 'Grooming', 'Grooming & Vaksin']
                  .map((treatment) => DropdownMenuItem(
                        value: treatment,
                        child: Text(treatment),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTreatment = value!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBooking,
              child: Text('Submit'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  return ListTile(
                    title: Text(booking['nama_pelanggan']),
                    subtitle: Text(
                        '${booking['treatment']} - Rp ${booking['total_biaya']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editBooking(booking),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBooking(booking['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
