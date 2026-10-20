import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorConfusionScreen extends StatefulWidget {
const ColorConfusionScreen({super.key});

@override
State<ColorConfusionScreen> createState() => _ColorConfusionScreenState();
}

class _ColorConfusionScreenState extends State<ColorConfusionScreen> {
static const int totalLevels = 180;

Set<int> _completedLevels = {};
Map<int, int> _stars = {};
Map<int, int> _bestScores = {};

@override
void initState() {
super.initState();
_loadProgress();
}

Future<void> _loadProgress() async {
final prefs = await SharedPreferences.getInstance();

final completed =
prefs.getStringList('color_confusion_completed_levels') ?? [];

final stars = <int, int>{};
final scores = <int, int>{};

for (int level = 1; level <= totalLevels; level++) {
final star = prefs.getInt('color_confusion_stars_$level');
final score = prefs.getInt('color_confusion_best_score_$level');

if (star != null) {
stars[level] = star;
}

if (score != null) {
scores[level] = score;
}
}

if (!mounted) return;

setState(() {
_completedLevels = completed.map(int.parse).toSet();
_stars = stars;
_bestScores = scores;
});
}

Future<void> _startLevel(int level) async {
if (level > 1 && !_completedLevels.contains(level - 1)) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Complete Level ${level - 1} to unlock Level $level.',
),
),
);
return;
}

await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ColorConfusionGameScreen(level: level),
),
);

_loadProgress();
}

String _difficulty(int level) {
if (level <= 60) return 'EASY';
if (level <= 120) return 'MEDIUM';
return 'DIFFICULT';
}

Color _difficultyColor(int level) {
if (level <= 60) return Colors.green;
if (level <= 120) return Colors.orange;
return Colors.red;
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Color Confusion'),
centerTitle: true,
),
body: Column(
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
child: Column(
children: [
const Text(
'COLOR CONFUSION',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
const Text(
'Identify the INK COLOR, not the word!',
textAlign: TextAlign.center,
style: TextStyle(fontSize: 15),
),
const SizedBox(height: 12),
Text(
'${_completedLevels.length} / $totalLevels levels completed',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
],
),
),
const Divider(height: 1),
Expanded(
child: GridView.builder(
padding: const EdgeInsets.all(12),
itemCount: totalLevels,
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 3,
crossAxisSpacing: 10,
mainAxisSpacing: 10,
childAspectRatio: 0.95,
),
itemBuilder: (context, index) {
final level = index + 1;
final unlocked =
level == 1 || _completedLevels.contains(level - 1);
final completed = _completedLevels.contains(level);

final stars = _stars[level] ?? 0;
final bestScore = _bestScores[level];

return InkWell(
borderRadius: BorderRadius.circular(16),
onTap: unlocked ? () => _startLevel(level) : null,
child: Container(
decoration: BoxDecoration(
color: unlocked
? Theme.of(context).colorScheme.surface
    : Colors.grey.shade300,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: unlocked
? _difficultyColor(level)
    : Colors.grey,
width: 2,
),
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
unlocked
? (completed
? Icons.check_circle
    : Icons.play_circle_fill)
    : Icons.lock,
size: 30,
color: unlocked
? _difficultyColor(level)
    : Colors.grey,
),
const SizedBox(height: 5),
Text(
'Level $level',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 3),
Text(
_difficulty(level),
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.bold,
color: _difficultyColor(level),
),
),
const SizedBox(height: 3),
if (completed)
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: List.generate(
3,
(starIndex) => Icon(
starIndex < stars
? Icons.star
    : Icons.star_border,
size: 15,
color: Colors.amber,
),
),
),
if (bestScore != null)
Text(
'Best: $bestScore',
style: const TextStyle(fontSize: 10),
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
}

class ColorConfusionGameScreen extends StatefulWidget {
final int level;

const ColorConfusionGameScreen({
super.key,
required this.level,
});

@override
State<ColorConfusionGameScreen> createState() =>
_ColorConfusionGameScreenState();
}

class _ColorConfusionGameScreenState
extends State<ColorConfusionGameScreen> {
static const int questionsPerLevel = 5;

final Random _random = Random();

int _questionIndex = 0;
int _score = 0;
int _correctAnswers = 0;
int _streak = 0;
int _timeLeft = 20;

Timer? _timer;

late ColorQuestion _question;

bool _answered = false;
int? _selectedIndex;

List<ColorOption> get _availableColors {
if (widget.level <= 60) {
return ColorOption.basicColors;
}

if (widget.level <= 120) {
return ColorOption.mediumColors;
}

return ColorOption.allColors;
}

int get _timeLimit {
if (widget.level <= 60) return 20;
if (widget.level <= 120) return 15;
return 10;
}

@override
void initState() {
super.initState();
_startQuestion();
}

@override
void dispose() {
_timer?.cancel();
super.dispose();
}

void _startQuestion() {
_timer?.cancel();

final colors = List<ColorOption>.from(_availableColors);

final wordColor = colors[_random.nextInt(colors.length)];
ColorOption inkColor;

do {
inkColor = colors[_random.nextInt(colors.length)];
} while (inkColor.name == wordColor.name);

final shuffledOptions = List<ColorOption>.from(colors);

if (widget.level <= 60) {
shuffledOptions.shuffle(_random);
} else if (widget.level <= 120) {
shuffledOptions.shuffle(_random);
} else {
shuffledOptions.shuffle(_random);
}

setState(() {
_question = ColorQuestion(
word: wordColor.name,
inkColor: inkColor.color,
correctColorName: inkColor.name,
options: shuffledOptions,
);

_answered = false;
_selectedIndex = null;
_timeLeft = _timeLimit;
});

_timer = Timer.periodic(
const Duration(seconds: 1),
(timer) {
if (!mounted) {
timer.cancel();
return;
}

if (_timeLeft <= 1) {
timer.cancel();
_handleAnswer(null);
} else {
setState(() {
_timeLeft--;
});
}
},
);
}

void _handleAnswer(int? selectedIndex) {
if (_answered) return;

_timer?.cancel();

final isCorrect = selectedIndex != null &&
_question.options[selectedIndex].name ==
_question.correctColorName;

setState(() {
_answered = true;
_selectedIndex = selectedIndex;

if (isCorrect) {
_correctAnswers++;
_streak++;

final timeBonus = _timeLeft * 5;
final streakBonus = (_streak - 1) * 10;

_score += 100 + timeBonus + streakBonus;
} else {
_streak = 0;
}
});

Future.delayed(
const Duration(milliseconds: 700),
() {
if (!mounted) return;

if (_questionIndex < questionsPerLevel - 1) {
setState(() {
_questionIndex++;
});

_startQuestion();
} else {
_finishLevel();
}
},
);
}

Future<void> _finishLevel() async {
final accuracy =
(_correctAnswers / questionsPerLevel) * 100;

final stars = _calculateStars(accuracy);

final prefs = await SharedPreferences.getInstance();

final completed =
prefs.getStringList('color_confusion_completed_levels') ?? [];

if (!completed.contains(widget.level.toString())) {
completed.add(widget.level.toString());
}

await prefs.setStringList(
'color_confusion_completed_levels',
completed,
);

final oldStars =
prefs.getInt('color_confusion_stars_${widget.level}') ?? 0;

if (stars > oldStars) {
await prefs.setInt(
'color_confusion_stars_${widget.level}',
stars,
);
}

final oldScore =
prefs.getInt(
'color_confusion_best_score_${widget.level}',
) ??
0;

if (_score > oldScore) {
await prefs.setInt(
'color_confusion_best_score_${widget.level}',
_score,
);
}

if (!mounted) return;

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => ColorConfusionResultScreen(
level: widget.level,
score: _score,
correctAnswers: _correctAnswers,
stars: stars,
),
),
);
}

int _calculateStars(double accuracy) {
if (accuracy >= 90) return 3;
if (accuracy >= 70) return 2;
if (accuracy >= 50) return 1;
return 0;
}

@override
Widget build(BuildContext context) {
final progress =
(_questionIndex + 1) / questionsPerLevel;

return Scaffold(
appBar: AppBar(
title: Text('Level ${widget.level}'),
centerTitle: true,
),
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'Question ${_questionIndex + 1}/$questionsPerLevel',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
Text(
'Score: $_score',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
Text(
'🔥 $_streak',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(height: 10),
LinearProgressIndicator(
value: progress,
minHeight: 8,
borderRadius: BorderRadius.circular(10),
),
const SizedBox(height: 18),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(
Icons.timer,
color: Colors.red,
),
const SizedBox(width: 5),
Text(
'$_timeLeft s',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: _timeLeft <= 3
? Colors.red
    : Colors.black,
),
),
],
),
const SizedBox(height: 25),
const Text(
'Which COLOR is the word printed in?',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 30),
Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
vertical: 30,
horizontal: 15,
),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(20),
border: Border.all(
width: 2,
color: Colors.grey.shade300,
),
),
child: Text(
_question.word,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 48,
fontWeight: FontWeight.w900,
color: _question.inkColor,
),
),
),
const SizedBox(height: 30),
Expanded(
child: GridView.builder(
itemCount: _question.options.length,
gridDelegate:
SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount:
_question.options.length <= 4 ? 2 : 3,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
childAspectRatio: 2.1,
),
itemBuilder: (context, index) {
final option = _question.options[index];

final isCorrect =
option.name ==
_question.correctColorName;

final isSelected =
_selectedIndex == index;

Color? backgroundColor;

if (_answered) {
if (isCorrect) {
backgroundColor = Colors.green;
} else if (isSelected) {
backgroundColor = Colors.red;
}
}

return ElevatedButton(
onPressed: _answered
? null
    : () => _handleAnswer(index),
style: ElevatedButton.styleFrom(
backgroundColor: backgroundColor,
disabledBackgroundColor:
backgroundColor ??
Colors.grey.shade200,
foregroundColor:
backgroundColor != null
? Colors.white
    : Colors.black87,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(14),
),
),
child: Text(
option.name,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
);
},
),
),
],
),
),
),
);
}
}

class ColorConfusionResultScreen extends StatelessWidget {
final int level;
final int score;
final int correctAnswers;
final int stars;

const ColorConfusionResultScreen({
super.key,
required this.level,
required this.score,
required this.correctAnswers,
required this.stars,
});

@override
Widget build(BuildContext context) {
final accuracy = (correctAnswers / 5) * 100;

return Scaffold(
appBar: AppBar(
title: const Text('Level Complete'),
centerTitle: true,
automaticallyImplyLeading: false,
),
body: Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(
Icons.emoji_events,
size: 90,
color: Colors.amber,
),
const SizedBox(height: 15),
Text(
'Level $level Complete!',
style: const TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: List.generate(
3,
(index) => Icon(
index < stars
? Icons.star
    : Icons.star_border,
size: 40,
color: Colors.amber,
),
),
),
const SizedBox(height: 25),
_ResultRow(
label: 'Score',
value: '$score',
),
_ResultRow(
label: 'Correct',
value: '$correctAnswers / 5',
),
_ResultRow(
label: 'Accuracy',
value: '${accuracy.toStringAsFixed(0)}%',
),
const SizedBox(height: 30),
if (level < 180)
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
onPressed: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) =>
ColorConfusionGameScreen(
level: level + 1,
),
),
);
},
icon: const Icon(Icons.arrow_forward),
label: Text(
'Next Level (${level + 1})',
),
),
),
const SizedBox(height: 10),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) =>
ColorConfusionGameScreen(
level: level,
),
),
);
},
icon: const Icon(Icons.refresh),
label: const Text('Retry Level'),
),
),
const SizedBox(height: 10),
SizedBox(
width: double.infinity,
child: TextButton.icon(
onPressed: () {
Navigator.pop(context);
},
icon: const Icon(Icons.list),
label: const Text('Back to Levels'),
),
),
],
),
),
),
);
}
}

class _ResultRow extends StatelessWidget {
final String label;
final String value;

const _ResultRow({
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(
vertical: 6,
horizontal: 25,
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Text(
label,
style: const TextStyle(
fontSize: 17,
),
),
Text(
value,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
],
),
);
}
}

class ColorOption {
final String name;
final Color color;

const ColorOption({
required this.name,
required this.color,
});

static const List<ColorOption> basicColors = [
ColorOption(
name: 'RED',
color: Colors.red,
),
ColorOption(
name: 'BLUE',
color: Colors.blue,
),
ColorOption(
name: 'GREEN',
color: Colors.green,
),
ColorOption(
name: 'YELLOW',
color: Colors.yellow,
),
];

static const List<ColorOption> mediumColors = [
ColorOption(
name: 'RED',
color: Colors.red,
),
ColorOption(
name: 'BLUE',
color: Colors.blue,
),
ColorOption(
name: 'GREEN',
color: Colors.green,
),
ColorOption(
name: 'YELLOW',
color: Colors.yellow,
),
ColorOption(
name: 'ORANGE',
color: Colors.orange,
),
ColorOption(
name: 'PURPLE',
color: Colors.purple,
),
];

static const List<ColorOption> allColors = [
ColorOption(
name: 'RED',
color: Colors.red,
),
ColorOption(
name: 'BLUE',
color: Colors.blue,
),
ColorOption(
name: 'GREEN',
color: Colors.green,
),
ColorOption(
name: 'YELLOW',
color: Colors.yellow,
),
ColorOption(
name: 'ORANGE',
color: Colors.orange,
),
ColorOption(
name: 'PURPLE',
color: Colors.purple,
),
];
}

class ColorQuestion {
final String word;
final Color inkColor;
final String correctColorName;
final List<ColorOption> options;

const ColorQuestion({
required this.word,
required this.inkColor,
required this.correctColorName,
required this.options,
});
}
