// import ต่าง ๆ
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' hide context;
import 'dart:io' show Platform;
import 'dart:io' as io;

// เกี่ยวกับฐานข้อมูล
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ข้อมูล
// Class การบ้าน
class Homework {
  // Attribute
  int? hwID;
  String? hwName;
  String? hwLesson;
  String? note;
  String? dueDate;
  bool? status;

  // Default Constructor
  Homework ({
    this.hwID,
    required this.hwName,
    required this.hwLesson,
    required this.dueDate,
    required this.status,
    this.note
  });

  // Constructor
  Homework.fromMap(Map<dynamic, dynamic> data) :
      hwID = data['hwID'],
        hwName = data['hwName'],
        hwLesson = data['hwLesson'],
        note = data['note'],
        dueDate = data['dueDate'],
        status = data['status'] == 1; // true = 1

  // Method
  Map<String, dynamic> toMap() {
    return {
      'hwID': hwID,
      'hwName': hwName,
      'hwLesson': hwLesson,
      'note': note,
      'dueDate': dueDate,
      'status': status == true ? 1:0,
    };
  }
}

// Class ฐานข้อมูล
class DBHelper {
  static Database? _database;

  // Function เรียกใช้งาน db
  Future<Database?> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  // Function สร้าง db
  initDatabase() async {
    io.Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'HomeworkTracker.db');

    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  // สร้าง Table
  _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE homework(hwID INTEGER PRIMARY KEY AUTOINCREMENT, hwName TEXT, hwLesson TEXT, note TEXT, dueDate DATE, status BIT'
    );
  }

  // เพิ่มการบ้านลงใน Table
  Future<Homework> insert(Homework hw) async {
    var db = await database;

    int id = await db!.insert('HomeworkTracker', hw.toMap());
    hw.hwID = id;
    return hw;
  }

  // ดึงรายการการบ้านใน Table
  Future<List<Homework>> getHomeworkList() async {
    var db = await database;

    final List<Map<String, Object?>> queryResult = await db!.query('HomeworkTracker');
    return queryResult.map((result) => Homework.fromMap(result)).toList();
  }

  // แก้ไขการบ้าน
  Future<int> updateHomework(Homework hw) async {
    var db = await database;

    return await db!.update('HomeworkTracker', hw.toMap(), where: "hwID = ?", whereArgs: [hw.hwID]);
  }

  // ลบการบ้าน
  Future<int> deleteHomework(int hwID) async {
    var db = await database;

    return await db!.delete('homework', where: "hwID = ?", whereArgs: [hwID]);
  }
}

// Provider
class hwProvider extends ChangeNotifier {
  DBHelper dbHelper = DBHelper();

  // List การบ้าน
  List<Homework> homeworks = [];
  // List รายวิชา
  List<String> lessons = ['English'];

  // Fuction ดึงรายการการบ้านใหม่
  Future<void> fetchHomework() async {
    homeworks = await dbHelper.getHomeworkList();

    for (var hw in homeworks) {
      if (hw.hwLesson != null && !lessons.contains(hw.hwLesson)) {
        lessons.add(hw.hwLesson!);
      }
    }

    notifyListeners();
  }

  // Function เพิ่มการบ้าน
  Future<void> addHomework(Homework hw) async {
    await dbHelper.insert(hw);
    await fetchHomework();
  }

  // Function แก้ไขการบ้าน
  Future<void> updateHomework(Homework hw) async {
    await dbHelper.updateHomework(hw);
    await fetchHomework();
  }

  // Function ลบการบ้าน
  Future<void> deleteHomework(int id) async {
    await dbHelper.deleteHomework(id);
    await fetchHomework();
  }

  // Function เปลี่ยนสถานะการบ้าน
  Future<void> changeStatus(Homework hw) async {
    hw.status = !(hw.status ?? false);
    await fetchHomework();
  }
}