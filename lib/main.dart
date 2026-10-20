import 'package:flutter/material.dart';

import 'database/database_test_screen.dart';

import 'screens/logic_master_screen.dart';
import 'screens/memory_match_screen.dart';
import 'screens/math_rush_screen.dart';
import 'screens/color_confusion_screen.dart';
import 'screens/odd_one_out_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/achievements_screen.dart';

void main() {
runApp(const BrainBattleApp());
}

class BrainBattleApp extends StatelessWidget {
const BrainBattleApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Brain Battle',
debugShowCheckedModeBanner: false,
theme: ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.deepPurple,
brightness: Brightness.light,
scaffoldBackgroundColor: const Color(0xFFF7F5FF),
appBarTheme: const AppBarTheme(
centerTitle: true,
elevation: 0,
),
cardTheme: const CardThemeData(
elevation: 3,
margin: EdgeInsets.zero,
),
),
home: const HomeScreen(),
);
}
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Brain Battle',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const SizedBox(height: 10),

// Brain icon
Container(
width: 110,
height: 110,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: const LinearGradient(
colors: [
Color(0xFF6C63FF),
Color(0xFF00C6FF),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
boxShadow: [
BoxShadow(
color: Colors.deepPurple.withValues(
alpha: 0.25,
),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: const Icon(
Icons.psychology,
color: Colors.white,
size: 65,
),
),

const SizedBox(height: 20),

const Text(
'Brain Battle',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 32,
fontWeight: FontWeight.bold,
color: Color(0xFF342E6E),
),
),

const SizedBox(height: 8),

const Text(
'Think Fast. Train Smart. Beat Your Best.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 15,
color: Colors.black54,
),
),

const SizedBox(height: 30),

// Play button
SizedBox(
width: double.infinity,
height: 58,
child: ElevatedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const GameSelectionScreen(),
),
);
},
icon: const Icon(
Icons.play_arrow,
size: 30,
),
label: const Text(
'PLAY BRAIN BATTLE',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
style: ElevatedButton.styleFrom(
backgroundColor:
const Color(0xFF6C63FF),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(18),
),
),
),
),

const SizedBox(height: 15),

// Dashboard
SizedBox(
width: double.infinity,
height: 52,
child: OutlinedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const DashboardScreen(),
),
);
},
icon: const Icon(
Icons.dashboard_outlined,
),
label: const Text(
'Dashboard & Progress',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
style: OutlinedButton.styleFrom(
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(16),
),
),
),
),

const SizedBox(height: 12),

// Achievements
SizedBox(
width: double.infinity,
height: 52,
child: OutlinedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const AchievementsScreen(),
),
);
},
icon: const Icon(
Icons.emoji_events_outlined,
),
label: const Text(
'Achievements',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
style: OutlinedButton.styleFrom(
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(16),
),
),
),
),

const SizedBox(height: 12),

// SQLite test
SizedBox(
width: double.infinity,
height: 52,
child: OutlinedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const DatabaseTestScreen(),
),
);
},
icon: const Icon(
Icons.storage_outlined,
),
label: const Text(
'Test SQLite Database',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
style: OutlinedButton.styleFrom(
foregroundColor:
Colors.deepPurple,
side: const BorderSide(
color: Colors.deepPurple,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(16),
),
),
),
),

const SizedBox(height: 25),

// Information card
Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(20),
),
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const Icon(
Icons.psychology_outlined,
size: 42,
color: Color(0xFF6C63FF),
),
const SizedBox(height: 12),
const Text(
'Train Your Brain',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
const Text(
'Challenge your memory, logic, '
'mathematical thinking and '
'observation skills with fun '
'offline brain-training games.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.black54,
height: 1.5,
),
),
],
),
),
),

const SizedBox(height: 15),

// Offline card
Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.green.withValues(
alpha: 0.08,
),
borderRadius:
BorderRadius.circular(16),
border: Border.all(
color: Colors.green.withValues(
alpha: 0.25,
),
),
),
child: const Row(
children: [
Icon(
Icons.offline_bolt,
color: Colors.green,
),
SizedBox(width: 12),
Expanded(
child: Text(
'Brain Battle works offline. '
'No internet connection is required '
'to play the games.',
style: TextStyle(
color: Colors.black87,
),
),
),
],
),
),

const SizedBox(height: 20),
],
),
),
),
);
}
}

// ============================================================
// GAME SELECTION SCREEN
// ============================================================

class GameSelectionScreen extends StatelessWidget {
const GameSelectionScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Choose Your Game',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(20),
children: [
_gameCard(
context,
title: 'Logic Master',
description:
'Solve number sequences, patterns and logical puzzles.',
icon: Icons.psychology,
color: const Color(0xFF6C63FF),
screen: const LogicMasterScreen(),
),

const SizedBox(height: 15),

_gameCard(
context,
title: 'Memory Match',
description:
'Remember cards and match identical pairs.',
icon: Icons.grid_view_rounded,
color: const Color(0xFF00A896),
screen: const MemoryMatchScreen(),
),

const SizedBox(height: 15),

_gameCard(
context,
title: 'Math Rush',
description:
'Solve arithmetic problems before time runs out.',
icon: Icons.calculate,
color: const Color(0xFFFF8C42),
screen: const MathRushScreen(),
),

const SizedBox(height: 15),

_gameCard(
context,
title: 'Color Confusion',
description:
'Identify the displayed color instead of the word.',
icon: Icons.palette,
color: const Color(0xFFE94F64),
screen: const ColorConfusionScreen(),
),

const SizedBox(height: 15),

_gameCard(
context,
title: 'Odd One Out',
description:
'Find the different shape, symbol or number.',
icon: Icons.filter_none,
color: const Color(0xFF3A86FF),
screen: const OddOneOutScreen(),
),

const SizedBox(height: 25),

// Dashboard button
SizedBox(
height: 52,
child: OutlinedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const DashboardScreen(),
),
);
},
icon: const Icon(
Icons.dashboard_outlined,
),
label: const Text(
'View Dashboard',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
),

const SizedBox(height: 20),
],
),
),
);
}

Widget _gameCard(
BuildContext context, {
required String title,
required String description,
required IconData icon,
required Color color,
required Widget screen,
}) {
return Card(
elevation: 3,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
child: InkWell(
borderRadius: BorderRadius.circular(20),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => screen,
),
);
},
child: Padding(
padding: const EdgeInsets.all(18),
child: Row(
children: [
Container(
width: 62,
height: 62,
decoration: BoxDecoration(
color: color.withValues(
alpha: 0.12,
),
borderRadius:
BorderRadius.circular(16),
),
child: Icon(
icon,
color: color,
size: 32,
),
),

const SizedBox(width: 16),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
description,
style: const TextStyle(
color: Colors.black54,
height: 1.3,
),
),
],
),
),

const SizedBox(width: 8),

const Icon(
Icons.arrow_forward_ios,
size: 18,
color: Colors.black45,
),
],
),
),
),
);
}
}