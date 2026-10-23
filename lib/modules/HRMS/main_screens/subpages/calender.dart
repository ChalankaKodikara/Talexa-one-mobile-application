// ignore_for_file: avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime today = DateTime.now();
  Map<DateTime, List<dynamic>> events = {}; // Map to store events

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });

    // You can navigate to the AnnualLeavesPage or perform other actions when a date is tapped
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => AnnualLeavesPage(selectedDay: day)),
    // );
  }

  // Function to show a dialog for adding events
  Future<void> _addEvent(BuildContext context, DateTime day) async {
    String eventText = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextField(
            onChanged: (value) {
              eventText = value;
            },
            decoration: const InputDecoration(hintText: 'Event details'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Add the event to the events map
                  events.update(
                    day,
                    (value) => [...value, eventText],
                    ifAbsent: () => [eventText],
                  );
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildEventList() {
    return events[today]
            ?.map((event) => ListTile(title: Text(event)))
            .toList() ??
        [
          const Text(
            'No events',
            style: TextStyle(
              color: Colors.white,
            ),
          )
        ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: HexColor('557BB4'),
          title: Text(
            "Calendar",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: HexColor('DFEBFB'),
              fontSize: 25,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [HexColor('557BB4'), HexColor('90B2E0')],
            ),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Material(
                      color: HexColor('5581C2'),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        child: TableCalendar(
                          rowHeight: 43,
                          locale: "en_US",
                          headerStyle: const HeaderStyle(
                            titleTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            ),
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          availableGestures: AvailableGestures.all,
                          selectedDayPredicate: (day) => isSameDay(day, today),
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: today,
                          onDaySelected: _onDaySelected,
                          eventLoader: (day) {
                            return events[day] ?? [];
                          },
                          calendarStyle: const CalendarStyle(
                              defaultTextStyle: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              outsideTextStyle: TextStyle(color: Colors.black),
                              holidayTextStyle: TextStyle(color: Colors.black)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _addEvent(context, today),
                      child: const Text('Add Event'),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildEventList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
