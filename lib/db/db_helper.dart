import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('klinik_booking.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pelanggan TEXT NOT NULL,
        nama_kucing TEXT NOT NULL,
        tanggal_masuk TEXT NOT NULL,
        treatment TEXT NOT NULL,
        total_biaya INTEGER NOT NULL
      )
    ''');
  }

  Future<int> addBooking(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('bookings', data);
  }

  Future<List<Map<String, dynamic>>> getBookings() async {
    final db = await instance.database;
    return await db.query('bookings', orderBy: 'id ASC');
  }

  Future<int> updateBooking(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db
        .update('bookings', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<int> deleteBooking(int id) async {
    final db = await instance.database;
    return await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete('bookings');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
