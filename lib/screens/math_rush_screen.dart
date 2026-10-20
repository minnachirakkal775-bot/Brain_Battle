import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MathRushScreen extends StatefulWidget {
const MathRushScreen({super.key});

@override
State<MathRushScreen> createState() => _MathRushScreenState();
}

class _MathRushScreenState extends State<MathRushScreen> {
final Set<int> _completedLevels = {};
final Map<int, int> _stars = {};
final Map<int, int> _bestScores = {};

bool _loading = true;

@override
void initState() {
super.initState();
_loadProgress();
}

Future<void> _loadProgress() async {
final prefs = await SharedPreferences.getInstance();

final completed =
prefs.getStringList('math_completed_levels') ?? [];

final stars = <int, int>{};
final scores = <int, int>{};

for (int level = 1; level <= 180; level++) {
final savedStars = prefs.getInt('math_stars_$level');
final savedScore =
prefs.getInt('math_best_score_$level');

if (savedStars != null) {
stars[level] = savedStars;
}

if (savedScore != null) {
scores[level] = savedScore;
}
}

if (!mounted) return;

setState(() {
_completedLevels
..clear()
..addAll(
completed
    .map((e) => int.tryParse(e) ?? 0)
    .where((e) => e > 0),
);

_stars
..clear()
..addAll(stars);

_bestScores
..clear()
..addAll(scores);

_loading = false;
});
}

bool _isUnlocked(int level) {
if (level == 1) {
return true;
}

return _completedLevels.contains(level - 1);
}

String _mode(int level) {
if (level <= 60) {
return 'Mixed Math';
}

if (level <= 120) {
return level.isEven ? 'Math Crossword' : 'Mixed Math';
}

return 'Math Crossword';
}

@override
Widget build(BuildContext context) {
if (_loading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

return Scaffold(
appBar: AppBar(
title: const Text('Math Rush'),
),
body: Column(
children: [
_buildProgressHeader(),
Expanded(
child: GridView.builder(
padding: const EdgeInsets.all(16),
itemCount: 180,
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 4,
crossAxisSpacing: 10,
mainAxisSpacing: 10,
childAspectRatio: 0.86,
),
itemBuilder: (context, index) {
final level = index + 1;
final unlocked = _isUnlocked(level);
final completed =
_completedLevels.contains(level);
final stars = _stars[level] ?? 0;

return InkWell(
onTap: unlocked
? () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
MathRushGameScreen(
level: level,
),
),
);

await _loadProgress();
}
    : null,
borderRadius: BorderRadius.circular(14),
child: Container(
decoration: BoxDecoration(
color: unlocked
? Colors.white
    : Colors.grey.shade200,
borderRadius:
BorderRadius.circular(14),
border: Border.all(
color: completed
? Colors.orange
    : Colors.grey.shade300,
width: completed ? 1.5 : 1,
),
),
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
if (!unlocked)
const Icon(
Icons.lock,
color: Colors.grey,
size: 22,
)
else
Text(
'$level',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
if (completed)
Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: List.generate(
3,
(i) => Icon(
i < stars
? Icons.star
    : Icons.star_border,
color: Colors.orange,
size: 13,
),
),
)
else if (unlocked)
Text(
_mode(level),
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 8,
color: Colors.green,
fontWeight: FontWeight.bold,
),
),
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
}

Widget _buildProgressHeader() {
return Container(
margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
padding: const EdgeInsets.all(16),
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [
Color(0xFFFF9800),
Color(0xFFFF7043),
],
),
borderRadius: BorderRadius.all(
Radius.circular(18),
),
),
child: Row(
children: [
const Icon(
Icons.calculate,
color: Colors.white,
size: 36,
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'Math Progress',
style: TextStyle(
color: Colors.white,
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 3),
Text(
'${_completedLevels.length} / 180 levels completed',
style: const TextStyle(
color: Colors.white,
fontSize: 12,
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

// ============================================================
// MATH RUSH GAME SCREEN
// ============================================================

class MathRushGameScreen extends StatefulWidget {
final int level;

const MathRushGameScreen({
super.key,
required this.level,
});

@override
State<MathRushGameScreen> createState() =>
_MathRushGameScreenState();
}

class _MathRushGameScreenState
extends State<MathRushGameScreen> {
late List<MathQuestion> _questions;

int _currentQuestion = 0;
int _score = 0;
int _correct = 0;
int _streak = 0;
int _bestStreak = 0;

int _secondsLeft = 20;

Timer? _timer;

bool _answered = false;
int? _selectedAnswer;

@override
void initState() {
super.initState();

_questions =
MathQuestionGenerator.generateLevel(
widget.level,
);

_startQuestionTimer();
}

bool get _isCrosswordLevel {
if (widget.level <= 60) {
return false;
}

if (widget.level <= 120) {
return widget.level.isEven;
}

return true;
}

int get _timeLimit {
if (widget.level <= 60) {
return 20;
}

if (widget.level <= 120) {
return 25;
}

return 30;
}

void _startQuestionTimer() {
_timer?.cancel();

_secondsLeft = _timeLimit;

_timer = Timer.periodic(
const Duration(seconds: 1),
(timer) {
if (!mounted || _answered) {
timer.cancel();
return;
}

setState(() {
_secondsLeft--;
});

if (_secondsLeft <= 0) {
timer.cancel();
_answer(null);
}
},
);
}

void _answer(int? answer) {
if (_answered) return;

_timer?.cancel();

final question = _questions[_currentQuestion];

final correct =
answer != null && answer == question.answer;

setState(() {
_answered = true;
_selectedAnswer = answer;

if (correct) {
_correct++;
_streak++;

if (_streak > _bestStreak) {
_bestStreak = _streak;
}

int points = 100;
points += _secondsLeft * 5;
points += _streak * 10;

_score += points;
} else {
_streak = 0;
}
});

Future.delayed(
const Duration(milliseconds: 900),
() {
if (!mounted) return;

if (_currentQuestion ==
_questions.length - 1) {
_finishGame();
} else {
setState(() {
_currentQuestion++;
_answered = false;
_selectedAnswer = null;
});

_startQuestionTimer();
}
},
);
}

Future<void> _finishGame() async {
_timer?.cancel();

final stars = _calculateStars();

final prefs =
await SharedPreferences.getInstance();

final completed =
prefs.getStringList(
'math_completed_levels',
) ??
[];

if (!completed.contains(
widget.level.toString(),
)) {
completed.add(
widget.level.toString(),
);

await prefs.setStringList(
'math_completed_levels',
completed,
);
}

final oldStars =
prefs.getInt(
'math_stars_${widget.level}',
) ??
0;

if (stars > oldStars) {
await prefs.setInt(
'math_stars_${widget.level}',
stars,
);
}

final oldScore =
prefs.getInt(
'math_best_score_${widget.level}',
) ??
0;

if (_score > oldScore) {
await prefs.setInt(
'math_best_score_${widget.level}',
_score,
);
}

if (!mounted) return;

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) =>
MathRushResultScreen(
level: widget.level,
score: _score,
correct: _correct,
total: _questions.length,
stars: stars,
bestStreak: _bestStreak,
),
),
);
}

int _calculateStars() {
final percentage =
_correct / _questions.length;

if (percentage >= 0.9) {
return 3;
}

if (percentage >= 0.7) {
return 2;
}

if (percentage >= 0.5) {
return 1;
}

return 0;
}

@override
void dispose() {
_timer?.cancel();
super.dispose();
}

@override
Widget build(BuildContext context) {
final question =
_questions[_currentQuestion];

return Scaffold(
appBar: AppBar(
title: Text(
'Math Rush - Level ${widget.level}',
),
),
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
_buildTopInfo(),
const SizedBox(height: 12),
LinearProgressIndicator(
value:
(_currentQuestion + 1) /
_questions.length,
color: Colors.orange,
),
const SizedBox(height: 18),
Expanded(
child: _isCrosswordLevel
? _buildCrosswordQuestion(
question,
)
    : _buildNormalQuestion(
question,
),
),
],
),
),
),
);
}

Widget _buildTopInfo() {
return Row(
children: [
Expanded(
child: _infoCard(
icon: Icons.timer,
title: 'Time',
value: '$_secondsLeft s',
),
),
const SizedBox(width: 8),
Expanded(
child: _infoCard(
icon: Icons.star,
title: 'Score',
value: '$_score',
),
),
const SizedBox(width: 8),
Expanded(
child: _infoCard(
icon: Icons.local_fire_department,
title: 'Streak',
value: '$_streak',
),
),
],
);
}

Widget _infoCard({
required IconData icon,
required String title,
required String value,
}) {
return Container(
padding: const EdgeInsets.symmetric(
vertical: 9,
horizontal: 5,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color: Colors.grey.shade300,
),
),
child: Column(
children: [
Icon(
icon,
color: Colors.orange,
size: 20,
),
const SizedBox(height: 2),
Text(
title,
style: const TextStyle(
fontSize: 9,
color: Colors.grey,
),
),
Text(
value,
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.bold,
),
),
],
),
);
}

Widget _buildNormalQuestion(
MathQuestion question,
) {
return Column(
children: [
Container(
width: double.infinity,
padding:
const EdgeInsets.symmetric(
vertical: 28,
horizontal: 12,
),
decoration: BoxDecoration(
color: const Color(0xFFFFF3E0),
borderRadius:
BorderRadius.circular(22),
border: Border.all(
color: Colors.orange.shade200,
),
),
child: Column(
children: [
const Icon(
Icons.calculate,
color: Colors.orange,
size: 48,
),
const SizedBox(height: 12),
const Text(
'Solve the equation',
style: TextStyle(
color: Colors.grey,
fontSize: 13,
),
),
const SizedBox(height: 12),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(
'${question.expression} = ?',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 27,
fontWeight: FontWeight.bold,
),
),
),
const SizedBox(height: 10),
const Text(
'+   −   ×   ÷',
style: TextStyle(
color: Colors.orange,
fontWeight: FontWeight.bold,
letterSpacing: 4,
),
),
],
),
),
const SizedBox(height: 20),
const Align(
alignment: Alignment.centerLeft,
child: Text(
'Choose the correct answer',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
),
const SizedBox(height: 12),
Expanded(
child: GridView.builder(
itemCount:
question.options.length,
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
childAspectRatio: 2.1,
),
itemBuilder: (context, index) {
return _answerButton(
question.options[index],
);
},
),
),
],
);
}

Widget _buildCrosswordQuestion(
MathQuestion question,
) {
final puzzle = question.crossword!;

return Column(
children: [
Container(
padding:
const EdgeInsets.symmetric(
vertical: 9,
horizontal: 14,
),
decoration: BoxDecoration(
color: const Color(0xFFE3F2FD),
borderRadius:
BorderRadius.circular(14),
),
child: const Row(
children: [
Icon(
Icons.grid_3x3,
color: Colors.blue,
),
SizedBox(width: 8),
Expanded(
child: Text(
'Math Crossword',
style: TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 13,
),
),
),
],
),
),
const SizedBox(height: 12),
Expanded(
child: SingleChildScrollView(
child: Column(
children: [
_buildCrosswordGrid(puzzle),
const SizedBox(height: 12),
const Text(
'Solve the equations by choosing the missing number.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
const SizedBox(height: 14),
GridView.builder(
shrinkWrap: true,
physics:
const NeverScrollableScrollPhysics(),
itemCount:
question.options.length,
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 4,
crossAxisSpacing: 8,
mainAxisSpacing: 8,
childAspectRatio: 1.6,
),
itemBuilder:
(context, index) {
return _answerButton(
question.options[index],
);
},
),
],
),
),
),
],
);
}

Widget _buildCrosswordGrid(
CrosswordPuzzle puzzle,
) {
final cells = puzzle.cells;

return Center(
child: Container(
padding: const EdgeInsets.all(7),
decoration: BoxDecoration(
color: const Color(0xFFF8FBFF),
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color: Colors.blue.shade200,
width: 1.5,
),
),
child: AspectRatio(
aspectRatio: 1,
child: GridView.builder(
physics:
const NeverScrollableScrollPhysics(),
itemCount: cells.length,
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 5,
),
itemBuilder:
(context, index) {
final cell = cells[index];

if (cell.value == null) {
return Container(
margin:
const EdgeInsets.all(1),
color: Colors.transparent,
);
}

final isMissing =
cell.isMissing;

return Container(
margin:
const EdgeInsets.all(1),
decoration: BoxDecoration(
color: isMissing
? Colors.amber.shade100
    : Colors.white,
border: Border.all(
color: isMissing
? Colors.orange
    : Colors.blue.shade200,
width:
isMissing ? 2 : 1,
),
),
alignment:
Alignment.center,
child: Text(
isMissing
? (_answered &&
_selectedAnswer !=
null
? '${_selectedAnswer!}'
    : '?')
    : cell.value!,
style: TextStyle(
fontSize:
cell.value!.length > 1
? 14
    : 19,
fontWeight:
FontWeight.bold,
color: isMissing
? Colors.orange.shade900
    : Colors.black87,
),
),
);
},
),
),
),
);
}

Widget _answerButton(int answer) {
final question =
_questions[_currentQuestion];

final isCorrect =
answer == question.answer;

final isSelected =
answer == _selectedAnswer;

Color background = Colors.white;
Color border = Colors.grey.shade300;

if (_answered && isCorrect) {
background = Colors.green.shade100;
border = Colors.green;
} else if (_answered && isSelected) {
background = Colors.red.shade100;
border = Colors.red;
}

return InkWell(
onTap: _answered
? null
    : () => _answer(answer),
borderRadius:
BorderRadius.circular(15),
child: Container(
decoration: BoxDecoration(
color: background,
borderRadius:
BorderRadius.circular(15),
border: Border.all(
color: border,
width: 1.5,
),
),
alignment: Alignment.center,
child: Text(
'$answer',
style: const TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
),
),
),
);
}
}

// ============================================================
// RESULT SCREEN
// ============================================================

class MathRushResultScreen
extends StatelessWidget {
final int level;
final int score;
final int correct;
final int total;
final int stars;
final int bestStreak;

const MathRushResultScreen({
super.key,
required this.level,
required this.score,
required this.correct,
required this.total,
required this.stars,
required this.bestStreak,
});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title:
const Text('Math Rush Result'),
automaticallyImplyLeading: false,
),
body: Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const SizedBox(height: 20),
const Icon(
Icons.emoji_events,
size: 85,
color: Colors.orange,
),
const SizedBox(height: 12),
Text(
'Level $level Complete!',
style: const TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 18),
Text(
'$score',
style: const TextStyle(
fontSize: 46,
fontWeight: FontWeight.bold,
color: Colors.orange,
),
),
const Text(
'SCORE',
style: TextStyle(
color: Colors.grey,
),
),
const SizedBox(height: 15),
Text(
'$correct / $total correct',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
'Best streak: $bestStreak 🔥',
style: const TextStyle(
fontSize: 16,
),
),
const SizedBox(height: 15),
Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: List.generate(
3,
(index) => Icon(
index < stars
? Icons.star
    : Icons.star_border,
color: Colors.orange,
size: 42,
),
),
),
const Spacer(),
SizedBox(
width: double.infinity,
height: 54,
child: ElevatedButton(
onPressed: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) =>
MathRushGameScreen(
level: level,
),
),
);
},
style:
ElevatedButton.styleFrom(
backgroundColor:
Colors.orange,
foregroundColor:
Colors.white,
),
child: const Text(
'Retry Level',
style: TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
),
),
const SizedBox(height: 10),
if (level < 180)
SizedBox(
width: double.infinity,
height: 54,
child: ElevatedButton(
onPressed: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) =>
MathRushGameScreen(
level: level + 1,
),
),
);
},
style:
ElevatedButton.styleFrom(
backgroundColor:
const Color(0xFFFF7043),
foregroundColor:
Colors.white,
),
child: const Text(
'Next Level',
style: TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
),
),
const SizedBox(height: 10),
TextButton(
onPressed: () {
Navigator.pop(context);
},
child: const Text(
'Back to Levels',
),
),
],
),
),
);
}
}

// ============================================================
// MATH QUESTION
// ============================================================

class MathQuestion {
final String expression;
final int answer;
final List<int> options;
final CrosswordPuzzle? crossword;

const MathQuestion({
required this.expression,
required this.answer,
required this.options,
this.crossword,
});
}

// ============================================================
// CROSSWORD CELL
// ============================================================

class CrosswordCell {
final String? value;
final bool isMissing;

const CrosswordCell({
this.value,
this.isMissing = false,
});

const CrosswordCell.empty()
    : value = null,
isMissing = false;
}

// ============================================================
// CROSSWORD PUZZLE
// ============================================================

class CrosswordPuzzle {
final List<CrosswordCell> cells;
final int answer;

const CrosswordPuzzle({
required this.cells,
required this.answer,
});
}

// ============================================================
// QUESTION GENERATOR
// ============================================================

class MathQuestionGenerator {
static final Random _random =
Random();

static List<MathQuestion> generateLevel(
int level,
) {
final isCrossword =
level > 60 &&
(level <= 120
? level.isEven
    : true);

return List.generate(
5,
(index) {
if (isCrossword) {
return _generateCrossword(
level,
index,
);
}

return _generateMixedQuestion(
level,
);
},
);
}

static MathQuestion _generateMixedQuestion(
int level,
) {
for (int attempt = 0;
attempt < 100;
attempt++) {
final question =
_tryGenerateMixed(level);

if (question != null) {
return question;
}
}

return _fallbackMixedQuestion();
}

static MathQuestion? _tryGenerateMixed(
int level,
) {
int maxNumber;

if (level <= 20) {
maxNumber = 10;
} else if (level <= 40) {
maxNumber = 20;
} else if (level <= 60) {
maxNumber = 30;
} else if (level <= 100) {
maxNumber = 50;
} else if (level <= 140) {
maxNumber = 80;
} else {
maxNumber = 100;
}

int a =
_random.nextInt(maxNumber) + 1;
int b =
_random.nextInt(maxNumber) + 1;
int c =
_random.nextInt(maxNumber) + 1;
int d =
_random.nextInt(maxNumber) + 1;
int e =
_random.nextInt(maxNumber) + 1;

final operations = [
'+',
'-',
'×',
'÷',
]..shuffle(_random);

final op1 = operations[0];
final op2 = operations[1];
final op3 = operations[2];
final op4 = operations[3];

if (op1 == '÷') {
b = _random.nextInt(8) + 1;
a =
b * (_random.nextInt(8) + 1);
}

if (op2 == '÷') {
c = _random.nextInt(8) + 1;
}

if (op3 == '÷') {
d = _random.nextInt(8) + 1;
}

if (op4 == '÷') {
e = _random.nextInt(8) + 1;
}

final values = [
a,
b,
c,
d,
e,
];

final expression =
'${values[0]} $op1 ${values[1]} '
'$op2 ${values[2]} $op3 ${values[3]} '
'$op4 ${values[4]}';

final answer = _evaluate(
values,
[
op1,
op2,
op3,
op4,
],
);

if (answer == null ||
answer <= 0 ||
answer > 10000) {
return null;
}

return MathQuestion(
expression: expression,
answer: answer,
options: _makeOptions(answer),
);
}

static int? _evaluate(
List<int> numbers,
List<String> operations,
) {
final values =
List<int>.from(numbers);
final ops =
List<String>.from(operations);

int i = 0;

while (i < ops.length) {
if (ops[i] == '×' ||
ops[i] == '÷') {
final a = values[i];
final b = values[i + 1];

int result;

if (ops[i] == '×') {
result = a * b;
} else {
if (b == 0 || a % b != 0) {
return null;
}

result = a ~/ b;
}

values[i] = result;
values.removeAt(i + 1);
ops.removeAt(i);
} else {
i++;
}
}

int result = values[0];

for (int j = 0;
j < ops.length;
j++) {
if (ops[j] == '+') {
result += values[j + 1];
} else {
result -= values[j + 1];
}
}

return result;
}

static List<int> _makeOptions(
int answer,
) {
final options = <int>{answer};

while (options.length < 4) {
final difference =
_random.nextInt(15) + 1;

final wrong = _random.nextBool()
? answer + difference
    : answer - difference;

if (wrong > 0 &&
wrong <= 10000) {
options.add(wrong);
}
}

final result = options.toList();
result.shuffle(_random);

return result;
}

static MathQuestion _fallbackMixedQuestion() {
return const MathQuestion(
expression:
'12 + 8 × 2 − 10 ÷ 5',
answer: 26,
options: [
26,
24,
28,
30,
],
);
}

static MathQuestion _generateCrossword(
int level,
int questionIndex,
) {
final templates = [
const _CrossTemplate(
2,
2,
4,
2,
4,
2,
8,
6,
4,
'+',
'×',
'×',
'+',
'-',
'-',
),
const _CrossTemplate(
3,
2,
5,
2,
4,
2,
8,
6,
4,
'+',
'×',
'×',
'+',
'-',
'-',
),
const _CrossTemplate(
4,
2,
6,
3,
5,
2,
10,
7,
5,
'+',
'×',
'×',
'+',
'-',
'-',
),
const _CrossTemplate(
5,
3,
8,
2,
6,
2,
11,
8,
5,
'+',
'×',
'×',
'+',
'-',
'-',
),
const _CrossTemplate(
6,
2,
8,
3,
7,
2,
13,
9,
5,
'+',
'×',
'×',
'+',
'-',
'-',
),
const _CrossTemplate(
7,
3,
10,
2,
8,
2,
15,
11,
6,
'+',
'×',
'×',
'+',
'-',
'-',
),
];

final template =
templates[
(level + questionIndex) %
templates.length];

final puzzle =
_createCrossword(template);

return MathQuestion(
expression:
'Math Crossword',
answer: puzzle.answer,
options: _makeOptions(
puzzle.answer,
),
crossword: puzzle,
);
}

static CrosswordPuzzle _createCrossword(
_CrossTemplate t,
) {
final cells =
List<CrosswordCell>.filled(
25,
const CrosswordCell.empty(),
);

cells[0] = CrosswordCell(
value: '${t.a}',
);

cells[1] = CrosswordCell(
value: t.op1,
);

cells[2] = CrosswordCell(
value: '${t.b}',
);

cells[3] = const CrosswordCell(
value: '=',
);

cells[4] = CrosswordCell(
value: '${t.c}',
);

cells[5] = CrosswordCell(
value: t.op3,
);

cells[7] = CrosswordCell(
value: t.op4,
);

cells[10] = CrosswordCell(
value: '${t.d}',
);

cells[11] = CrosswordCell(
value: t.op2,
);

cells[12] = const CrosswordCell(
value: '?',
isMissing: true,
);

cells[13] = const CrosswordCell(
value: '=',
);

cells[14] = CrosswordCell(
value: '${t.f}',
);

cells[15] = const CrosswordCell(
value: '=',
);

cells[17] = CrosswordCell(
value: t.op5,
);

cells[20] = CrosswordCell(
value: '${t.g}',
);

cells[21] = CrosswordCell(
value: t.op6,
);

cells[22] = CrosswordCell(
value: '${t.h}',
);

cells[23] = const CrosswordCell(
value: '=',
);

cells[24] = CrosswordCell(
value: '${t.i}',
);

return CrosswordPuzzle(
cells: cells,
answer: t.e,
);
}
}

// ============================================================
// CROSSWORD TEMPLATE
// ============================================================

class _CrossTemplate {
final int a;
final int b;
final int c;

final int d;
final int e;
final int f;

final int g;
final int h;
final int i;

final String op1;
final String op2;
final String op3;
final String op4;
final String op5;
final String op6;

const _CrossTemplate(
this.a,
this.b,
this.c,
this.d,
this.e,
this.f,
this.g,
this.h,
this.i,
this.op1,
this.op2,
this.op3,
this.op4,
this.op5,
this.op6,
);
}