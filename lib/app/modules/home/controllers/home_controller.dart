import 'package:get/get.dart';

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
  }

  void addEvent(DateTime date, String title, String time, String location) {
    final normalized = DateTime(date.year, date.month, date.day);
    events.add(Event(
      date: normalized,
      title: title,
      time: time,
      location: location,
    ));
    print('Added event: $title on $normalized at $time, location: $location');
    print('Total events: ${events.length}');
  }

  List<Event> get upcomingEvents {
    final now = DateTime.now();
    final filteredEvents = events
        .where((event) => !event.date.isBefore(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    print('Upcoming events count: ${filteredEvents.length}');
    return filteredEvents;
  }

  void removeEvent(DateTime date, String title) {
    final normalized = DateTime(date.year, date.month, date.day);
    final removedEvents = events.where((event) =>
        event.date == normalized && event.title == title).toList();
    events.removeWhere((event) =>
        event.date == normalized && event.title == title);
    for (var event in removedEvents) {
      print('Removed event: ${event.title} on ${event.date} at ${event.time}, location: ${event.location}');
    }
    print('Total events: ${events.length}');
  }
}