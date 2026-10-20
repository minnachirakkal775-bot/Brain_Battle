import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DashboardScreen extends StatefulWidget {
const DashboardScreen({super.key});

@override
State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
static const int totalLevelsPerGame = 180;

bool isLoading = true;
String? errorMessage;

int totalCompleted = 0;
int totalStars = 0;
int totalScore = 0;

List<Map<String, dynamic>> gameProgress = [];

final List<Map<String, dynamic>> games = [
{
'name': 'Logic Master',
'type': 'Logic Master',
'icon': Icons.psychology,
'color': Colors.deepPurple,
},
{
'name': 'Memory Match',
'type': 'Memory Match',
'icon': Icons.grid_view,
'color': Colors.blue,
},
{
'name': 'Math Rush',
'type': 'Math Rush',
'icon': Icons.calculate,
'color': Colors.green,
},
{
'name': 'Color Confusion',
'type': 'Color Confusion',
'icon': Icons.palette,
'color': Colors.pink,
},
{
'name': 'Odd One Out',
'type': 'Odd One Out',
'icon': Icons.filter_none,
'color': Colors.indigo,
},
];

@override
void initState() {
super.initState();
loadDashboard();
}

Future<void> loadDashboard() async {
if (!mounted) return;

setState(() {
isLoading = true;
errorMessage = null;
});

try {
final List<Map<String, dynamic>> loadedGames = [];

int completedTotal = 0;
int starsTotal = 0;
int scoreTotal = 0;

for (final game in games) {
final String gameType = game['type'] as String;

// Read progress from the existing SQLite database helper.
final rows =
await DatabaseHelper.instance.getLevelProgress(gameType);

int completed = 0;
int stars = 0;
int score = 0;
int bestScore = 0;

for (final row in rows) {
final int levelCompleted =
_toInt(row['completed']);

final int levelStars =
_toInt(row['stars']);

final int levelScore =
_toInt(row['best_score']);

completed += levelCompleted;
stars += levelStars;
score += levelScore;

if (levelScore > bestScore) {
bestScore = levelScore;
}
}

completedTotal += completed;
starsTotal += stars;
scoreTotal += score;

loadedGames.add({
...game,
'completed': completed,
'stars': stars,
'score': score,
'bestScore': bestScore,
});
}

if (!mounted) return;

setState(() {
gameProgress = loadedGames;
totalCompleted = completedTotal;
totalStars = starsTotal;
totalScore = scoreTotal;
isLoading = false;
errorMessage = null;
});
} catch (e, stackTrace) {
debugPrint('Dashboard loading failed: $e');
debugPrintStack(stackTrace: stackTrace);

if (!mounted) return;

setState(() {
errorMessage = e.toString();
isLoading = false;
});
}
}

int _toInt(dynamic value) {
if (value is num) return value.toInt();
if (value is String) return int.tryParse(value) ?? 0;
return 0;
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF8F3FC),
appBar: AppBar(
backgroundColor: const Color(0xFFFFF8FF),
elevation: 0,
leading: const BackButton(),
title: const Text(
'Dashboard & Progress',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Colors.black,
),
),
actions: [
IconButton(
onPressed: isLoading ? null : loadDashboard,
tooltip: 'Refresh progress',
icon: const Icon(Icons.refresh),
),
],
),
body: _buildBody(),
);
}

Widget _buildBody() {
if (isLoading) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (errorMessage != null) {
return Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
color: Colors.red,
size: 45,
),
const SizedBox(height: 12),
const Text(
'Unable to load dashboard',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
Text(
errorMessage!,
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 12),
),
const SizedBox(height: 16),
ElevatedButton.icon(
onPressed: loadDashboard,
icon: const Icon(Icons.refresh),
label: const Text('Retry'),
),
],
),
),
);
}

return RefreshIndicator(
onRefresh: loadDashboard,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.all(16),
children: [
_buildWelcomeCard(),
const SizedBox(height: 18),

const Text(
'Overall Progress',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 10),

Row(
children: [
Expanded(
child: _buildStatCard(
icon: Icons.emoji_events,
value: '$totalCompleted',
label: 'Levels',
color: Colors.deepPurple,
),
),
const SizedBox(width: 8),
Expanded(
child: _buildStatCard(
icon: Icons.star,
value: '$totalStars',
label: 'Stars',
color: Colors.amber.shade800,
),
),
const SizedBox(width: 8),
Expanded(
child: _buildStatCard(
icon: Icons.scoreboard,
value: '$totalScore',
label: 'Score',
color: Colors.green,
),
),
],
),

const SizedBox(height: 22),

const Text(
'Game Progress',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 10),

...gameProgress.map(
(game) => Padding(
padding: const EdgeInsets.only(bottom: 10),
child: _buildGameCard(game),
),
),

const SizedBox(height: 12),

OutlinedButton.icon(
onPressed: loadDashboard,
icon: const Icon(Icons.refresh),
label: const Text('Refresh Progress'),
),
],
),
);
}

Widget _buildWelcomeCard() {
return Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [
Color(0xFF7045C5),
Color(0xFF2196F3),
],
),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.deepPurple.withValues(alpha: 0.15),
blurRadius: 8,
offset: const Offset(0, 4),
),
],
),
child: const Row(
children: [
CircleAvatar(
radius: 25,
backgroundColor: Colors.white,
child: Icon(
Icons.psychology,
color: Colors.deepPurple,
size: 30,
),
),
SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Brain Battle',
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 18,
),
),
SizedBox(height: 5),
Text(
'Train your brain. Improve your skills.',
style: TextStyle(
color: Colors.white,
fontSize: 11,
),
),
],
),
),
],
),
);
}

Widget _buildStatCard({
required IconData icon,
required String value,
required String label,
required Color color,
}) {
return Card(
elevation: 2,
color: const Color(0xFFF7F0FA),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: Padding(
padding: const EdgeInsets.symmetric(
vertical: 14,
horizontal: 4,
),
child: Column(
children: [
Icon(icon, color: color, size: 22),
const SizedBox(height: 8),
Text(
value,
textAlign: TextAlign.center,
style: TextStyle(
color: color,
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
label,
style: const TextStyle(fontSize: 10),
),
],
),
),
);
}

Widget _buildGameCard(Map<String, dynamic> game) {
final int completed = _toInt(game['completed']);
final int stars = _toInt(game['stars']);
final int bestScore = _toInt(game['bestScore']);
final Color color = game['color'] as Color;
final IconData icon = game['icon'] as IconData;
final String name = game['name'] as String;

final double progress =
(completed / totalLevelsPerGame).clamp(0.0, 1.0);

return Card(
elevation: 2,
color: const Color(0xFFF9F2FC),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
children: [
Row(
children: [
CircleAvatar(
backgroundColor: color.withValues(alpha: 0.12),
child: Icon(icon, color: color),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
name,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 13,
),
),
const SizedBox(height: 4),
Text(
'$completed / $totalLevelsPerGame levels completed',
style: const TextStyle(
fontSize: 10,
color: Colors.black54,
),
),
],
),
),
Column(
children: [
const Icon(
Icons.star,
color: Colors.amber,
size: 18,
),
Text(
'$stars',
style: const TextStyle(fontSize: 10),
),
],
),
],
),
const SizedBox(height: 12),
ClipRRect(
borderRadius: BorderRadius.circular(8),
child: LinearProgressIndicator(
value: progress,
minHeight: 5,
backgroundColor: color.withValues(alpha: 0.12),
valueColor: AlwaysStoppedAnimation<Color>(color),
),
),
const SizedBox(height: 8),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'${(progress * 100).toStringAsFixed(1)}% completed',
style: const TextStyle(
fontSize: 9,
color: Colors.black54,
),
),
Text(
'Best: $bestScore',
style: const TextStyle(
fontSize: 9,
color: Colors.black54,
),
),
],
),
],
),
),
);
}
}
