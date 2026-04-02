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

  // (MainScreen)เปลี่ยนแท็บหน้า MainScreen
  int selectedMainIndex = 0;
  void setMainIndex(int index) {
    selectedMainIndex = index;
    notifyListeners();
  }

  // (HomeTab)ตัวกรองวิชาใน HomeTab
  String selectedFilterLesson = 'All';
  void setFilterLesson(String lesson) {
    selectedFilterLesson = lesson;
    notifyListeners();
  }
  // (AddEditHomework) ฟอร์ม
  String formDate = 'Pick a Date!';
  String? formLesson;
  // set เวลา
  void setFormDate(String date) {
    formDate = date;
    notifyListeners();
  }
  // set รายวิชา
  void setFormLesson(String? lesson) {
    formLesson = lesson;
    notifyListeners();
  }
  // reset ค่าก่อนเปิดหน้าฟอร์มใหม่
  void initFormState(Homework? hw) {
    // ในกรณีที่เป็นการแก้ไขฟอร์ม
    if (hw != null) {
      formDate = hw.dueDate ?? 'Pick a Date!';
      formLesson = hw.hwLesson;
    }
    // ในกรณีที่เป็นการเพิ่มฟอร์ม
    else {
      formDate = 'Pick a Date!';
      formLesson = lessons.isNotEmpty ? lessons.first : null;
    }
    notifyListeners();
  }


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

// Date picker dialog
class DatePickerDialog extends StatelessWidget {
  final String currentDate;
  final Function(String) onDateSelected;

  const DatePickerDialog({Key? key, required this.currentDate, required this.onDateSelected}) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026),
      lastDate: DateTime(2126)
    );

    if (picked != null) {
      String date = DateFormat('dd mm yyyy').format(picked);
      onDateSelected(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: Colors.blueGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.calendar_today_rounded, color: Colors.blueGrey, fontWeight: FontWeight.bold,),
            SizedBox(width: 8.0,),
            Text('$currentDate', style: TextStyle(fontWeight: FontWeight.bold),)
          ],
        ),
      ),
    );
  }
}

void main() {
  // เพื่อให้สามารถใช้งาน database บน PC ได้
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => hwProvider(),
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Homework Tracker',
      theme: ThemeData(
        fontFamily: 'Noto Sans Thai',
        textTheme: TextTheme(
          // แสดงชื่อแอปบน banner
          displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w800,),
          // ชื่อการบ้าน
          headlineMedium: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500,),
          // ชื่อวิชา
          titleMedium: TextStyle(fontSize: 18.0),
          // รายละเอียดอื่น ๆ บทแอป
          bodyMedium: TextStyle(fontSize: 16.0)
        ),
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.lightBlue,
            background: Colors.white,
            primary: Colors.lightBlue,
            secondary: Colors.yellowAccent,
        ),
      ),
      home: MainScreen(),
    );
  }
}


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<hwProvider>(context, listen: false).fetchHomework();
  }

  void _onItemTapped(int index) {
    // ถ้า index = 1 จะไปยังหน้าเพิ่มการบ้าน
    if (index == 1) {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEditHomework())
      );
    } else {
      Provider.of<hwProvider>(context, listen: false).setMainIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<hwProvider>(
      builder: (context, provider, child) {
        // List ของหน้าเมนูต่าง ๆ
        final List<Widget> pages = [
          const HomeTab(isCompleted: false),
          const SizedBox(),
          const HomeTab(isCompleted: true)
        ];

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: pages[provider.selectedMainIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            currentIndex: provider.selectedMainIndex == 2 ? 2 : 0,
            onTap: _onItemTapped,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home, size: 32, ), label: 'Home', activeIcon: Icon(Icons.pets, size: 32, color: Theme.of(context).colorScheme.inversePrimary,)),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 48, ), label: 'Add',),
              BottomNavigationBarItem(icon: Icon(Icons.library_add_check, size: 32, ), label: 'Completed', activeIcon: Icon(Icons.pets, size: 32, color: Theme.of(context).colorScheme.inversePrimary,))
            ],
          ),
        );
      }
    );
  }
}

// หน้า  Home และ หน้า completed
class HomeTab extends StatefulWidget {
  final bool isCompleted;
  const HomeTab({Key? key, required this.isCompleted}) : super(key : key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<hwProvider>(
      builder: (context, provider, child) {
        // กรองสถานะงาน
        var displayList = provider.homeworks.where((hw) => (hw.status ?? false) == widget.isCompleted).toList();

        // กรองตามวิชา
        if (provider.selectedFilterLesson != "All") {
          displayList = displayList.where((hw) => hw.hwLesson == provider.selectedFilterLesson).toList();
        }
        // วันที่วันนี้
        String today = DateFormat("dd MMMM yyyy").format(DateTime.now());
        // รายการรายวิชาในเครื่องมือกรอง
        List<String> filterLessons = ["All", ...provider.lessons];

        // Banner
        return SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          widget.isCompleted ? 'Completed Homework' : 'Homework Tracker',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        SizedBox(height: 16,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(widget.isCompleted ? Icons.check_box_rounded : Icons.calendar_today_rounded ),
                            SizedBox(width: 8,),
                            Text(
                              widget.isCompleted ? 'You completed ${displayList.length} tasks!' : 'Today - ${today}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Lesson", style: Theme.of(context).textTheme.bodyMedium,),
                    SizedBox(width: 8,),
                    // ตัวกรอง
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(24.0)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.selectedFilterLesson,
                          items: filterLessons.map((String lesson) {
                            return DropdownMenuItem<String>(
                              value: lesson,
                              child: Text(lesson, style: Theme.of(context).textTheme.bodyMedium,),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              provider.setFilterLesson(newValue);
                            }
                          },
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class AddEditHomework extends StatefulWidget {
  final Homework? homework;

  const AddEditHomework({Key? key, this.homework}) : super(key: key);

  @override
  _AddEditHomeworkState createState() => _AddEditHomeworkState();
}

class _AddEditHomeworkState extends State<AddEditHomework> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}














