import 'dart:ui';
import 'dart:convert';

import 'package:cipta_vera_mandiri_digital/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final HomeController homeController = Get.find<HomeController>();
  Map<DateTime, List<Map<String, String>>> _events = {};
  Map<DateTime, List<String>> _holidays = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime _selectedDay = DateTime.now();

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    // Suppress Flutter's gesture arena debug output
    debugPrintGestureArenaDiagnostics = false;
    fetchHolidays();
    loadEvents();
  }

  Future<void> saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = _events.map((key, value) {
      return MapEntry(key.toIso8601String(), value);
    });
    await prefs.setString('events', jsonEncode(eventsJson));
  }

  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsString = prefs.getString('events');
    if (eventsString != null) {
      final Map<String, dynamic> decoded = jsonDecode(eventsString);
      final loadedEvents = decoded.map((key, value) {
        final date = DateTime.parse(key);
        final List<Map<String, String>> eventsList = List<Map<String, String>>.from(
          (value as List).map((item) => Map<String, String>.from(item)),
        );
        return MapEntry(date, eventsList);
      });
      setState(() {
        _events = loadedEvents;
      });
    }
  }

  Future<void> fetchHolidays() async {
    final response = await http.get(Uri.parse('https://api-harilibur.vercel.app/api'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      Map<DateTime, List<String>> holidays = {};
      for (var item in data) {
        final dateString = item['holiday_date'];
        final name = item['holiday_name'];
        if (dateString == null || dateString.isEmpty || name == null || name.isEmpty) {
          continue;
        }
        final dateParts = dateString.split('-');
        if (dateParts.length != 3) {
          continue;
        }
        final year = int.tryParse(dateParts[0]);
        final month = int.tryParse(dateParts[1]);
        final day = int.tryParse(dateParts[2]);
        if (year == null || month == null || day == null) {
          continue;
        }
        final date = _normalizeDate(DateTime(year, month, day));
        holidays[date] = [name];
      }
      setState(() {
        _holidays = holidays;
      });
      debugPrint('Loaded holidays: $_holidays');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Calendar',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final TextEditingController eventController = TextEditingController();
              final TextEditingController roomController = TextEditingController();
              final TextEditingController timeController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.0),
                      child: AlertDialog(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tambah Acara',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: eventController,
                                      decoration: InputDecoration(
                                        hintText: 'Tambahkan Acara',
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.4),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: timeController,
                                      decoration: InputDecoration(
                                        hintText: 'Waktu Acara',
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.4),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: roomController,
                                      decoration: InputDecoration(
                                        hintText: 'Ruangan di Pakai',
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.4),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (eventController.text.isNotEmpty && timeController.text.isNotEmpty) {
                                setState(() {
                                  final newEvent = {
                                    "title": eventController.text,
                                    "time": timeController.text,
                                    "room": roomController.text,
                                  };
                                  if (_events[_selectedDay] != null) {
                                    _events[_selectedDay]!.add(newEvent);
                                  } else {
                                    _events[_selectedDay] = [newEvent];
                                  }
                                  homeController.addEvent(_selectedDay, eventController.text, timeController.text, roomController.text);
                                });
                                saveEvents();
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text(
                              'Tambah',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient blurred abstract background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
                stops: [0.5, 2.0],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _selectedDay,
                          calendarFormat: _calendarFormat,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.twoWeeks: '2 Weeks',
                            CalendarFormat.week: 'Week',
                          },
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = _normalizeDate(selectedDay);
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _selectedDay = _normalizeDate(focusedDay);
                            });
                          },
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                            formatButtonVisible: true,
                            formatButtonShowsNext: true,
                            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: const TextStyle(color: Colors.black),
                            weekendStyle: const TextStyle(color: Colors.red),
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.purpleAccent.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: const TextStyle(color: Colors.black),
                            selectedTextStyle: const TextStyle(color: Colors.black),
                            holidayTextStyle: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            holidayDecoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          holidayPredicate: (date) => _holidays.containsKey(_normalizeDate(date)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Upcoming Holidays Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Acara Mendatang',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...(() {
                        final upcomingHolidays = _holidays.entries
                            .where((entry) => entry.key.isAfter(_selectedDay))
                            .toList();
                        upcomingHolidays.sort((a, b) => a.key.compareTo(b.key));
                        return upcomingHolidays
                            .take(5)
                            .map((entry) {
                              final date = entry.key;
                              final names = entry.value;
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              final daysRemaining = date.difference(today).inDays;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.13),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            date.day.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            _monthName(date.month),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            names.first,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$daysRemaining hari lagi',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList();
                      })(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_holidays[_normalizeDate(_selectedDay)] != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedDay.day.toString(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _monthName(_selectedDay.month),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _holidays[_normalizeDate(_selectedDay)]!.map((holiday) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      holiday,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ..._events[_selectedDay]?.map((event) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedDay.day.toString(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _monthName(_selectedDay.month),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event["title"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event["time"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      event["room"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _events[_selectedDay]?.remove(event);
                                    if (_events[_selectedDay]?.isEmpty ?? false) {
                                      _events.remove(_selectedDay);
                                    }
                                    homeController.removeEvent(_selectedDay, event["title"] ?? "");
                                  });
                                  saveEvents();
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList() ?? [],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
