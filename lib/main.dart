import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' hide context;
import 'dart:io' show Platform;
import 'dart:io' as io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';

// Date picker dialog
class DatePickerFragment extends StatelessWidget {
  final String currentDate;
  final Function(String) onDateSelected;

  const DatePickerFragment({Key? key, required this.currentDate, required this.onDateSelected}) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2026),
        lastDate: DateTime(2126)
    );

    if (picked != null) {
      String date = DateFormat('dd MMMM yyyy').format(picked);
      onDateSelected(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero
      ),
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
// Time Picker dialog
class TimePickerFragment extends StatelessWidget {
  final String currentTime;
  final Function(String) onTimeSelected;

  const TimePickerFragment({Key? key, required this.currentTime, required this.onTimeSelected}) : super(key: key);

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      if (!context.mounted) return;
      // แปลง TimeOfDay ให้เป็น String แบบอ่านง่าย (เช่น 10:30 AM)
      String time = picked.format(context);
      onTimeSelected(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // ให้พื้นหลังโปร่งใสเพื่อโชว์ขอบเขต Container
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
      ),
      onPressed: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: Colors.blueGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.access_time_rounded, color: Colors.blueGrey, fontWeight: FontWeight.bold,),
            const SizedBox(width: 8.0,),
            Text(currentTime, style: const TextStyle(fontWeight: FontWeight.bold,),)
          ],
        ),
      ),
    );
  }
}

class Homework {
  int? hwId;
  String? hwName;
  String? hwLesson;
  String? note;
  String? dueDate;
  String? dueTime;
  bool? status;

  Homework ({
    this.hwId,
    required this.hwName,
    required this.hwLesson,
    required this.dueDate,
    required this.dueTime,
    required this.status,
    this.note
  });

  Homework.fromMap(Map<dynamic, dynamic> data) :
        hwId = data['hwId'],
        hwName = data['hwName'],
        hwLesson = data['hwLesson'],
        note = data['note'],
        dueDate = data['dueDate'],
        dueTime = data['dueTime'],
        status = data['status'] == 1;

  Map<String, dynamic> toMap() {
    return {
      'hwId': hwId,
      'hwName': hwName,
      'hwLesson': hwLesson,
      'note': note,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'status': status == true ? 1:0,
    };
  }
}

class DBHelper {
  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;

  }

  initDatabase() async {
    io.Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'homeworkTracker.db');

    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  _onCreate(Database db, int version) async {
    await db.execute(
        'CREATE TABLE homework(hwId INTEGER PRIMARY KEY AUTOINCREMENT, hwName TEXT, hwLesson TEXT, note TEXT, dueDate DATE, dueTime TIME, status BIT)'
    );
  }

  Future<Homework> insert(Homework homework) async {
    var dbClient = await database;
    int id = await dbClient!.insert('homework', homework.toMap());
    homework.hwId = id;
    return homework;
  }

  Future<List<Homework>> getHomeworkList() async {
    var dbClient = await database;
    final List<Map<String, Object?>> queryResult =
    await dbClient!.query('homework');
    return queryResult.map((result) => Homework.fromMap(result)).toList();
  }

  Future<int> updateHomework(Homework homework) async {
    var dbClient = await database;
    return await dbClient!.update('homework', homework.toMap(),
        where: "hwId = ?", whereArgs: [homework.hwId]
    );
  }

  Future<int> deleteHomeworkItem(int hwId) async {
    var dbClient = await database;
    return await dbClient!.delete('homework', where: "hwId = ?", whereArgs: [hwId]);
  }

}

class HomeworkProvider extends ChangeNotifier {
  DBHelper dbHelper = DBHelper();
  List<Homework> homeworks = [];

  List<String> lessons = ["English"];

  Future<void> fetchHomework() async {
    homeworks = await dbHelper.getHomeworkList();

    for (var hw in homeworks) {
      if (hw.hwLesson != null && !lessons.contains(hw.hwLesson)) {
        lessons.add(hw.hwLesson!);
      }
    }
    notifyListeners();
  }

  void addNewLesson(String newLesson) {
    if (newLesson.isNotEmpty && !lessons.contains(newLesson)) {
      lessons.add(newLesson);
      notifyListeners();
    }
  }

  Future<void> addHomework(Homework hw) async {
    await dbHelper.insert(hw);
    await fetchHomework();
  }

  Future<void> updateHomework(Homework hw) async {
    await dbHelper.updateHomework(hw);
    await fetchHomework();
  }

  Future<void> deleteHomework(int id) async {
    await dbHelper.deleteHomeworkItem(id);
    await fetchHomework();
  }

  Future<void> toggleStatus(Homework hw) async {
    hw.status = !(hw.status ?? false);
    await dbHelper.updateHomework(hw);
    await fetchHomework();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // เช็คว่าถ้ารันบน Desktop (Windows, Linux, Mac) ให้ตั้งค่า FFI
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => HomeworkProvider(),
      child: const MyApp(),
    ),
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
          fontFamily: 'Roboto',
          textTheme: TextTheme(displayLarge: TextStyle(fontSize: 32.0),)
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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลเมื่อเปิดแอป
    Provider.of<HomeworkProvider>(context, listen: false).fetchHomework();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // ถ้ากดปุ่ม + (index 1) ให้เปิดหน้า Add
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddEditHomeworkPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const HomeTab(isCompletedView: false),
      const SizedBox(),
      const HomeTab(isCompletedView: true),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue[300],
        currentIndex: _selectedIndex == 2 ? 2 : 0,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30, color: Colors.white), label: 'Home', activeIcon: Icon(Icons.pets, size: 30, color: Colors.white)),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 50, color: Colors.yellow), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes, size: 30, color: Colors.white), label: 'Completed', activeIcon: Icon(Icons.pets, size: 30, color: Colors.white)),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final bool isCompletedView;
  const HomeTab({Key? key, required this.isCompletedView}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedFilterLesson = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeworkProvider>(
      builder: (context, provider, child) {

        // กรองข้อมูลตามสถานะหน้าจอ (หน้า Home หรือ Completed)
        var displayList = provider.homeworks.where((hw) => (hw.status ?? false) == widget.isCompletedView).toList();

        // กรองข้อมูลตามวิชาที่เลือกใน Dropdown
        if (_selectedFilterLesson != 'All') {
          displayList = displayList.where((hw) => hw.hwLesson == _selectedFilterLesson).toList();
        }

        String today = DateFormat('dd MMMM yyyy').format(DateTime.now());

        // สร้างลิสต์วิชาสำหรับ Filter โดยมีคำว่า 'All' นำหน้า
        List<String> filterLessons = ['All', ...provider.lessons];

        return SafeArea(
          child: Column(
            children: [
              Container(
                color: Colors.blue[400],
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isCompletedView ? 'Completed Homework' : 'Homework Tracker',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isCompletedView ? 'You completed ${displayList.length} tasks!' : 'Today - $today',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const Icon(Icons.pets, size: 50)
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Lesson"),
                    const SizedBox(width: 8),

                    Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(20)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilterLesson,
                          items: filterLessons.map((String lesson) {
                            return DropdownMenuItem<String>(
                              value: lesson,
                              child: Text(lesson),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedFilterLesson = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1, color: Colors.black),

              Expanded(
                child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final hw = displayList[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddEditHomeworkPage(homework: hw)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey))
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            border: Border.all(),
                                            borderRadius: BorderRadius.circular(20)
                                        ),
                                        // เพิ่มการแสดงเวลาต่อจากวันที่
                                        child: Text(
                                          '📅 ${hw.dueDate} ${hw.dueTime != null && hw.dueTime!.isNotEmpty ? '⏰ ${hw.dueTime}' : ''}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(hw.hwName ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('Lesson: ${hw.hwLesson}', style: const TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => provider.toggleStatus(hw),
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                    color: (hw.status ?? false) ? Colors.lightGreen : Colors.white,
                                    border: Border.all(width: 2),
                                    borderRadius: BorderRadius.circular(4)
                                ),
                                child: (hw.status ?? false) ? const Icon(Icons.check, size: 20) : null,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddEditHomeworkPage extends StatefulWidget {
  final Homework? homework;

  const AddEditHomeworkPage({Key? key, this.homework}) : super(key: key);

  @override
  _AddEditHomeworkPageState createState() => _AddEditHomeworkPageState();
}

class _AddEditHomeworkPageState extends State<AddEditHomeworkPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedDate = 'Pick a date!';
  String _selectedTime = 'Pick a Time!';
  String? _selectedLesson;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<HomeworkProvider>(context, listen: false);

    if (provider.lessons.isNotEmpty) {
      _selectedLesson = provider.lessons.first;
    }

    if (widget.homework != null) {
      _nameController.text = widget.homework!.hwName ?? '';
      _noteController.text = widget.homework!.note ?? '';
      _selectedDate = widget.homework!.dueDate ?? 'Pick a date!';
      _selectedTime = widget.homework!.dueTime ?? 'Pick a Time!';

      if (provider.lessons.contains(widget.homework!.hwLesson)) {
        _selectedLesson = widget.homework!.hwLesson;
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  // ฟังก์ชันบันทึกข้อมูล
  Future<void> _saveData() async {
    if (_nameController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final provider = Provider.of<HomeworkProvider>(context, listen: false);

    Homework newHw = Homework(
      hwId: widget.homework?.hwId,
      hwName: _nameController.text,
      hwLesson: _selectedLesson ?? '',
      dueDate: _selectedDate == 'Pick a date!' ? DateFormat('dd MMMM yyyy').format(DateTime.now()) : _selectedDate,
      dueTime: _selectedTime == 'Pick a time' ? '': _selectedTime,
      status: widget.homework?.status ?? false,
      note: _noteController.text,
    );

    if (widget.homework == null) {
      await provider.addHomework(newHw);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("New Homework successfully!"), backgroundColor: Colors.lightGreen, showCloseIcon: true,));
    } else {
      await provider.updateHomework(newHw);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // Dialog เพิ่มวิชาใหม่
  void _showAddLessonDialog() {
    TextEditingController lessonController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add New Lesson"),
            content: TextField(
              controller: lessonController,
              decoration: const InputDecoration(hintText: "Enter lesson name"),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (lessonController.text.isNotEmpty) {
                    Provider.of<HomeworkProvider>(context, listen: false)
                        .addNewLesson(lessonController.text);

                    setState(() {
                      _selectedLesson = lessonController.text;
                    });
                  }
                  Navigator.pop(context); // ปิด Dialog
                },
                child: const Text("Add"),
              )
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.homework != null;

    final provider = Provider.of<HomeworkProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 30),
            onPressed: _saveData,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: <Widget>[
                Expanded(child:
                  // เลือกวันที่
                  DatePickerFragment(
                      currentDate: _selectedDate,
                      onDateSelected: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      }),
                ),
                const SizedBox(width: 8,),
                Expanded(child:
                  // เลือกเวลา
                  TimePickerFragment(
                      currentTime: _selectedTime,
                      onTimeSelected: (newTime) {
                        setState(() {
                          _selectedTime = newTime;
                        });
                      })
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ชื่อการบ้าน
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "What's your Homework?",
                hintStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 24),

            // Dropdown
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(20)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedLesson,
                        items: provider.lessons.map((String lesson) {
                          return DropdownMenuItem<String>(
                            value: lesson,
                            child: Text(lesson),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLesson = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showAddLessonDialog,
                  child: const Text('+ new lesson', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Note
            const Text('Note:'),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Leave some note...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),

            const Spacer(),

            // ปุ่มสร้างใหม่หรือปุ่มลบ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? Colors.white : Colors.blue[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: isEditing ? BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none
                    ),
                ),
                onPressed: () async {
                  if (isEditing) {
                    await Provider.of<HomeworkProvider>(context, listen: false).deleteHomework(widget.homework!.hwId!);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("deleted successfully!"), backgroundColor: Colors.redAccent, showCloseIcon: true,));
                    if (mounted) Navigator.pop(context);
                  } else {
                    await _saveData();
                  }
                },
                child: Text(
                  isEditing ? 'Remove' : 'New',
                  style: TextStyle(color: isEditing ? Colors.redAccent[400] : Colors.black)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

