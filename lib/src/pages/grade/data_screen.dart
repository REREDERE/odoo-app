import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:odoo/src/helpers/theme_colors.dart';

import '../../database/globals.dart';
import '../calendar/calendar_page.dart';

class DataScreen extends StatefulWidget {
  final String ci;
  const DataScreen({Key? key, required this.ci}) : super(key: key);

  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  Future<List<dynamic>>? _data;

  @override
  void initState() {
    super.initState();
    _data = fetchData(widget.ci);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notas'),
        backgroundColor: ThemeColors.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today), // Icono de calendario
            tooltip: 'Ir al calendario',
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => CalendarPage(UserRole.viewer, ci: widget.ci),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: FutureBuilder<List<dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No hay datos disponibles'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data?.length ?? 0,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  final name = item['student_name'];
                  final grade = item['grade'];
                  final subjectName = item['subject_name'];
                  final cycleName = item['cycle_name'];

                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text('$name - $subjectName'),
                      subtitle: Text('Nota: $grade - Ciclo: $cycleName'),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

Future<List<dynamic>> fetchData(String ci) async {
  final response = await http.get(Uri.parse('${Globals.baseUrl}/datas?ci=$ci'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Error al cargar los datos');
  }
}
