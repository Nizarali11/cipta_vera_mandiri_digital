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

Map<DateTime, List<Event>> calendarEvents = {};

class HomeController extends GetxController {
  var currentIndex = 2.obs;
  var events = <Event>[].obs;
  var isLoading = true.obs;

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
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final eventsString = prefs.getString('events');
    if (eventsString != null) {
      final decoded = jsonDecode(eventsString);
      if (decoded is List) {
        events.value = decoded.map((e) => Event(
              date: DateTime.parse(e['date']).toLocal(),
              title: e['title'],
              time: e['time'],
              location: e['location'],
            )).toList();
        print('Loaded events: ${events.length}');
      } else if (decoded is Map) {
        List<Event> loadedEvents = [];
        decoded.forEach((key, value) {
          DateTime date = DateTime.parse(key).toLocal();
          if (value is List) {
            for (var item in value) {
              String location = item['location'] ?? item['room'] ?? '';
              loadedEvents.add(Event(
                date: DateTime(date.year, date.month, date.day),
                title: item['title'],
                time: item['time'],
                location: location,
              ));
            }
          }
        });
        events.value = loadedEvents;
        print('Loaded events: ${events.length}');
      } else {
        print('Invalid events data format. Keeping existing stored events.');
        // Jangan hapus data, cukup skip load agar data lama tetap ada
      }
    }
    isLoading.value = false;
  }

  void addEvent(DateTime date, String title, String time, String location) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final newEvent = Event(
      date: normalized,
      title: title,
      time: time,
      location: location,
    );
    events.add(newEvent);
    if (calendarEvents.containsKey(normalized)) {
      calendarEvents[normalized]!.add(newEvent);
    } else {
      calendarEvents[normalized] = [newEvent];
    }
    print('Added event: $title on $normalized at $time, location: $location');
    print('Total events: ${events.length}');
    await saveEventsToPrefs();
    update();
  }

  List<Event> get upcomingEvents {
    final now = DateTime.now();
    final filteredEvents = events
        .where((event) => !event.date.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
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