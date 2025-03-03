
import 'package:odoo/src/quiz_logic/question.dart';

class Quiz {
  String name;
  List<Question> questions;
  int right = 0;

  Quiz({required this.name, required this.questions});

  double get percent => (right / questions.length) * 100;
}