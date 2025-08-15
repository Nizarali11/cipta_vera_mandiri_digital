import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Event {
  DateTime date;
  String title;
  String time;
  String location;

  Event({
    required this.date,
    required this.title,
    required this.time,
    required this.location,
  });
}

class HomeController extends GetxController {
  var currentIndex = 0.obs;
  var events = <Event>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadEventsFromPrefs();
  }

  Future<void> saveEventsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsMap = events.map((e) => {
          'date': e.date.toIso8601String(),
          'title': e.title,
          'time': e.time,
          'location': e.location,
        }).toList();
    await prefs.setString('events', jsonEncode(eventsMap));
  }

  Future<void> loadEventsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsString = prefs.getString('events');
    if (eventsString != null) {
      final decoded = jsonDecode(eventsString);
      if (decoded is List) {
        events.value = decoded.map((e) => Event(
              date: DateTime.parse(e['date']),
              title: e['title'],
              time: e['time'],
              location: e['location'],
            )).toList();
        print('Loaded events: ${events.length}');
      } else {
        // Jika format data salah (bukan List), hapus dan kosongkan events
        print('Invalid events data format. Clearing stored events.');
        await prefs.remove('events');
        events.clear();
      }
    }
  }

  void addEvent(DateTime date, String title, String time, String location) async {
    final normalized = DateTime(date.year, date.month, date.day);
    events.add(Event(
      date: normalized,
      title: title,
      time: time,
      location: location,
    ));
    print('Added event: $title on $normalized at $time, location: $location');
    print('Total events: ${events.length}');
    await saveEventsToPrefs();
  }

  List<Event> get upcomingEvents {
    final now = DateTime.now();
    final filteredEvents = events
        .where((event) => !event.date.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    print('Upcoming events count: ${filteredEvents.length}');
    return filteredEvents;
  }

  Future<void> removeEvent(DateTime date, String title) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final removedEvents = events.where((event) =>
        event.date == normalized && event.title == title).toList();
    events.removeWhere((event) =>
        event.date == normalized && event.title == title);
    for (var event in removedEvents) {
      print('Removed event: ${event.title} on ${event.date} at ${event.time}, location: ${event.location}');
    }
    print('Total events: ${events.length}');
    await saveEventsToPrefs();
    update(); // Tambahkan ini untuk memicu pembaruan UI
  }
}