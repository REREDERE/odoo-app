import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../database/globals.dart';
import '../../helpers/theme_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum UserRole { admin, viewer }

class CalendarPage extends StatefulWidget {
  final UserRole userRole;
  final String ci;  // Se recibe el CI del usuario

  const CalendarPage(this.userRole, {Key? key, required this.ci}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadActivities();  // Llamar a la función para cargar actividades desde la API
  }

  // Cargar las actividades desde la API
  Future<void> _loadActivities() async {
    try {
      final response = await http.get(Uri.parse('${Globals.baseUrl}/activities?ci=${widget.ci}'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        Map<DateTime, List<String>> eventsByDate = {};

        for (var item in data) {
          DateTime startDate = DateTime.parse(item['start_time']).toLocal();

          // Solo guardamos la fecha sin la parte de hora (sin la hora, minuto, etc.)
          DateTime dateKey = DateTime(startDate.year, startDate.month, startDate.day);

          String eventName = item['activity_name'];

          if (eventsByDate[dateKey] == null) {
            eventsByDate[dateKey] = [];
          }
          eventsByDate[dateKey]!.add(eventName);
        }

        setState(() {
          _events = eventsByDate;
        });


      } else {
        throw Exception('Error al cargar las actividades');
      }
    } catch (e) {
      print(e);
    }
  }

  // Obtener las actividades para el día seleccionado
  List<String> _getEventsForDay(DateTime day) {
    // Asegúrate de que las fechas sean exactamente iguales al compararlas (sin horas, minutos, etc.)
    DateTime dateKey = DateTime(day.year, day.month, day.day);
    print('Fetching events for: $dateKey'); // Verificamos la fecha seleccionada

    return _events[dateKey] ?? [];
  }

  // Mostrar el diálogo para agregar un evento
  void _showAddEventDialog() {
    String eventName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Evento'),
        content: TextField(
          onChanged: (value) {
            eventName = value;
          },
          decoration: InputDecoration(hintText: 'Nombre del evento'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (eventName.isNotEmpty) {
                setState(() {
                  _addEvent(_selectedDay!, eventName);
                });
              }
              Navigator.of(context).pop();
            },
            child: Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Agregar evento a SharedPreferences
  Future<void> _addEvent(DateTime date, String event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? existingEvents = prefs.getStringList(date.toString());

    if (existingEvents != null) {
      existingEvents.add(event);
      await prefs.setStringList(date.toString(), existingEvents);
    } else {
      await prefs.setStringList(date.toString(), [event]);
    }

    setState(() {
      _events[date] = prefs.getStringList(date.toString())!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario de Eventos'),
        backgroundColor: ThemeColors.primaryColor,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: ThemeColors.primaryColor,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: Colors.white),
              selectedDecoration: BoxDecoration(
                color: ThemeColors.primaryColor,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.white),
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(color: Colors.white70), // Color de los números del calendario
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                String event = _getEventsForDay(_selectedDay!)[index];
                return ListTile(
                  title: Text(
                    event,
                    style: TextStyle(color: Colors.white), // Color del texto de los eventos
                  ),
                  trailing: widget.userRole == UserRole.admin
                      ? IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // Lógica para editar eventos si eres administrador
                    },
                  )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole == UserRole.admin
          ? FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: Icon(Icons.add),
      )
          : null,
    );
  }
}
