import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsScreen extends StatefulWidget {
const AchievementsScreen({super.key});

@override
State<AchievementsScreen> createState() =>
_AchievementsScreenState();
}

class _AchievementsScreenState
extends State<AchievementsScreen> {
bool loading = true;
String? errorMessage;

int totalCompleted = 0;
int totalStars = 0;

int logicCompleted = 0;
int memoryCompleted = 0;
int mathCompleted = 0;
int colorCompleted = 0;
int oddCompleted = 0;

int logicStars = 0;
int memoryStars = 0;
int mathStars = 0;
int colorStars = 0;
int oddStars = 0;

@override
void initState() {
super.initState();
_loadAchievements();
}

// =============================================================
// LOAD ACHIEVEMENT DATA
// =============================================================

Future<void> _loadAchievements() async {
if (mounted) {
setState(() {
loading = true;
errorMessage = null;
});
}

try {
final prefs =
await SharedPreferences.getInstance();

// ---------------------------------------------------------
// COMPLETED LEVELS
// ---------------------------------------------------------

final logicLevels =
prefs.getStringList(
'logic_completed_levels',
) ??
<String>[];

final memoryLevels =
prefs.getStringList(
'memory_completed_levels',
) ??
<String>[];

final mathLevels =
prefs.getStringList(
'math_rush_completed_levels',
) ??
<String>[];

final colorLevels =
prefs.getStringList(
'color_confusion_completed_levels',
) ??
<String>[];

final oddLevels =
prefs.getStringList(
'odd_one_out_completed_levels',
) ??
<String>[];

// ---------------------------------------------------------
// COUNT VALID COMPLETED LEVELS
// ---------------------------------------------------------

logicCompleted =
_countValidLevels(logicLevels);

memoryCompleted =
_countValidLevels(memoryLevels);

mathCompleted =
_countValidLevels(mathLevels);

colorCompleted =
_countValidLevels(colorLevels);

oddCompleted =
_countValidLevels(oddLevels);

totalCompleted =
logicCompleted +
memoryCompleted +
mathCompleted +
colorCompleted +
oddCompleted;

// ---------------------------------------------------------
// CALCULATE STARS
// ---------------------------------------------------------

logicStars =
_calculateStars(
prefs,
'logic',
);

memoryStars =
_calculateStars(
prefs,
'memory',
);

mathStars =
_calculateStars(
prefs,
'math_rush',
);

colorStars =
_calculateStars(
prefs,
'color_confusion',
);

oddStars =
_calculateStars(
prefs,
'odd_one_out',
);

totalStars =
logicStars +
memoryStars +
mathStars +
colorStars +
oddStars;
} catch (e) {
errorMessage =
'Unable to load achievements.';
} finally {
if (mounted) {
setState(() {
loading = false;
});
}
}
}

// =============================================================
// VALID LEVEL COUNT
// =============================================================

int _countValidLevels(
List<String> levels,
) {
final validLevels = <int>{};

for (final value in levels) {
final level = int.tryParse(value);

if (level != null &&
level >= 1 &&
level <= 180) {
validLevels.add(level);
}
}

return validLevels.length;
}

// =============================================================
// CALCULATE STARS
// =============================================================

int _calculateStars(
SharedPreferences prefs,
String prefix,
) {
int result = 0;

for (int level = 1; level <= 180; level++) {
result +=
prefs.getInt(
'${prefix}_stars_$level',
) ??
0;
}

return result;
}

// =============================================================
// REFRESH
// =============================================================

Future<void> _refresh() async {
await _loadAchievements();
}

// =============================================================
// ACHIEVEMENT LIST
// =============================================================

List<Achievement> _getAchievements() {
return [
Achievement(
title: 'First Win',
description:
'Complete your first level.',
icon: Icons.flag,
requirement: totalCompleted >= 1,
progress:
totalCompleted.clamp(0, 1),
target: 1,
),

Achievement(
title: 'Brain Starter',
description:
'Complete 5 levels.',
icon: Icons.play_arrow,
requirement:
totalCompleted >= 5,
progress:
totalCompleted.clamp(0, 5),
target: 5,
),

Achievement(
title: 'Brain Trainer',
description:
'Complete 10 levels.',
icon: Icons.psychology,
requirement:
totalCompleted >= 10,
progress:
totalCompleted.clamp(0, 10),
target: 10,
),

Achievement(
title: 'Level Master',
description:
'Complete 25 levels.',
icon: Icons.military_tech,
requirement:
totalCompleted >= 25,
progress:
totalCompleted.clamp(0, 25),
target: 25,
),

Achievement(
title: 'Brain Champion',
description:
'Complete 50 levels.',
icon: Icons.emoji_events,
requirement:
totalCompleted >= 50,
progress:
totalCompleted.clamp(0, 50),
target: 50,
),

Achievement(
title: 'Brain Legend',
description:
'Complete 100 levels.',
icon: Icons.workspace_premium,
requirement:
totalCompleted >= 100,
progress:
totalCompleted.clamp(0, 100),
target: 100,
),

Achievement(
title: 'Star Collector',
description:
'Earn 25 stars.',
icon: Icons.star,
requirement:
totalStars >= 25,
progress:
totalStars.clamp(0, 25),
target: 25,
),

Achievement(
title: 'Star Master',
description:
'Earn 50 stars.',
icon: Icons.stars,
requirement:
totalStars >= 50,
progress:
totalStars.clamp(0, 50),
target: 50,
),

Achievement(
title: 'Star Champion',
description:
'Earn 100 stars.',
icon: Icons.auto_awesome,
requirement:
totalStars >= 100,
progress:
totalStars.clamp(0, 100),
target: 100,
),

Achievement(
title: 'Logic Expert',
description:
'Complete 25 Logic Master levels.',
icon: Icons.psychology,
requirement:
logicCompleted >= 25,
progress:
logicCompleted.clamp(0, 25),
target: 25,
),

Achievement(
title: 'Memory Expert',
description:
'Complete 25 Memory Match levels.',
icon: Icons.memory,
requirement:
memoryCompleted >= 25,
progress:
memoryCompleted.clamp(0, 25),
target: 25,
),

Achievement(
title: 'Math Expert',
description:
'Complete 25 Math Rush levels.',
icon: Icons.calculate,
requirement:
mathCompleted >= 25,
progress:
mathCompleted.clamp(0, 25),
target: 25,
),

Achievement(
title: 'Color Expert',
description:
'Complete 25 Color Confusion levels.',
icon: Icons.color_lens,
requirement:
colorCompleted >= 25,
progress:
colorCompleted.clamp(0, 25),
target: 25,
),

Achievement(
title: 'Odd One Expert',
description:
'Complete 25 Odd One Out levels.',
icon: Icons.filter_none,
requirement:
oddCompleted >= 25,
progress:
oddCompleted.clamp(0, 25),
target: 25,
),

Achievement(
title: 'Brain Battle Master',
description:
'Complete all 180 levels in one game.',
icon: Icons.workspace_premium,
requirement:
logicCompleted >= 180 ||
memoryCompleted >= 180 ||
mathCompleted >= 180 ||
colorCompleted >= 180 ||
oddCompleted >= 180,
progress:
_masterProgress(),
target: 180,
),
];
}

int _masterProgress() {
return [
logicCompleted,
memoryCompleted,
mathCompleted,
colorCompleted,
oddCompleted,
].reduce(max);
}

// =============================================================
// BUILD
// =============================================================

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Achievements',
),
centerTitle: true,
),
body: loading
? const Center(
child: CircularProgressIndicator(),
)
    : errorMessage != null
? _buildError()
    : RefreshIndicator(
onRefresh: _refresh,
child: _buildContent(),
),
);
}

// =============================================================
// ERROR
// =============================================================

Widget _buildError() {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons.error_outline,
size: 60,
color: Colors.red.shade400,
),
const SizedBox(height: 15),
const Text(
'Could not load achievements',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
errorMessage ??
'Please try again.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.grey.shade700,
),
),
const SizedBox(height: 20),
ElevatedButton.icon(
onPressed: _loadAchievements,
icon: const Icon(
Icons.refresh,
),
label: const Text(
'TRY AGAIN',
),
),
],
),
),
);
}

// =============================================================
// CONTENT
// =============================================================

Widget _buildContent() {
final achievements =
_getAchievements();

final unlockedCount =
achievements
    .where(
(achievement) =>
achievement.requirement,
)
    .length;

final completion =
achievements.isEmpty
? 0.0
    : unlockedCount /
achievements.length;

return ListView(
physics:
const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.fromLTRB(
16,
16,
16,
30,
),
children: [
_buildHeader(
unlockedCount,
achievements.length,
completion,
),

const SizedBox(height: 18),

_buildStatsCard(),

const SizedBox(height: 20),

const Text(
'Achievements',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 10),

...achievements.map(
(achievement) =>
_buildAchievementCard(
achievement,
),
),
],
);
}

// =============================================================
// HEADER
// =============================================================

Widget _buildHeader(
int unlocked,
int total,
double completion,
) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
Colors.deepPurple.shade700,
Colors.indigo.shade500,
],
),
borderRadius:
BorderRadius.circular(20),
),
child: Column(
children: [
const Icon(
Icons.emoji_events,
color: Colors.white,
size: 48,
),
const SizedBox(height: 8),
const Text(
'Your Achievements',
style: TextStyle(
color: Colors.white,
fontSize: 23,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
'$unlocked of $total unlocked',
style: const TextStyle(
color: Colors.white70,
fontSize: 13,
),
),
const SizedBox(height: 15),
ClipRRect(
borderRadius:
BorderRadius.circular(10),
child: LinearProgressIndicator(
value: completion,
minHeight: 9,
backgroundColor:
Colors.white24,
valueColor:
const AlwaysStoppedAnimation<
Color>(
Colors.white,
),
),
),
const SizedBox(height: 8),
Text(
'${(completion * 100).round()}% Complete',
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
],
),
);
}

// =============================================================
// STATS
// =============================================================

Widget _buildStatsCard() {
return Row(
children: [
Expanded(
child: _statCard(
Icons.check_circle,
'$totalCompleted',
'Levels',
),
),
const SizedBox(width: 10),
Expanded(
child: _statCard(
Icons.star,
'$totalStars',
'Stars',
),
),
const SizedBox(width: 10),
Expanded(
child: _statCard(
Icons.psychology,
'5',
'Games',
),
),
],
);
}

Widget _statCard(
IconData icon,
String value,
String label,
) {
return Container(
padding: const EdgeInsets.symmetric(
vertical: 15,
horizontal: 6,
),
decoration: BoxDecoration(
color: Colors.deepPurple.shade50,
borderRadius:
BorderRadius.circular(15),
),
child: Column(
children: [
Icon(
icon,
color: Colors.deepPurple,
size: 25,
),
const SizedBox(height: 6),
Text(
value,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 2),
Text(
label,
style: TextStyle(
fontSize: 10,
color: Colors.grey.shade700,
),
),
],
),
);
}

// =============================================================
// ACHIEVEMENT CARD
// =============================================================

Widget _buildAchievementCard(
Achievement achievement,
) {
final unlocked =
achievement.requirement;

final progress =
achievement.target == 0
? 0.0
    : (achievement.progress /
achievement.target)
    .clamp(0.0, 1.0);

return Container(
margin:
const EdgeInsets.only(bottom: 12),
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: unlocked
? Colors.amber.shade50
    : Colors.grey.shade100,
borderRadius:
BorderRadius.circular(16),
border: Border.all(
color: unlocked
? Colors.amber.shade300
    : Colors.grey.shade300,
),
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// ICON
Container(
width: 52,
height: 52,
decoration: BoxDecoration(
color: unlocked
? Colors.amber.shade100
    : Colors.grey.shade200,
shape: BoxShape.circle,
),
child: Icon(
unlocked
? achievement.icon
    : Icons.lock_outline,
color: unlocked
? Colors.amber.shade800
    : Colors.grey.shade500,
size: 27,
),
),

const SizedBox(width: 13),

// DETAILS
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
achievement.title,
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
color: unlocked
? Colors.black87
    : Colors.grey.shade700,
),
),
),
if (unlocked)
const Icon(
Icons.check_circle,
color: Colors.green,
size: 20,
),
],
),

const SizedBox(height: 4),

Text(
achievement.description,
style: TextStyle(
fontSize: 12,
color:
Colors.grey.shade700,
height: 1.3,
),
),

const SizedBox(height: 9),

// PROGRESS
Row(
children: [
Expanded(
child: ClipRRect(
borderRadius:
BorderRadius.circular(
10,
),
child:
LinearProgressIndicator(
value: progress,
minHeight: 6,
backgroundColor:
Colors.grey.shade300,
valueColor:
AlwaysStoppedAnimation<
Color>(
unlocked
? Colors.green
    : Colors.deepPurple,
),
),
),
),
const SizedBox(width: 8),
Text(
'${achievement.progress}/${achievement.target}',
style: TextStyle(
fontSize: 10,
fontWeight:
FontWeight.bold,
color:
Colors.grey.shade700,
),
),
],
),
],
),
),
],
),
);
}
}

// ===============================================================
// ACHIEVEMENT MODEL
// ===============================================================

class Achievement {
final String title;
final String description;
final IconData icon;
final bool requirement;
final int progress;
final int target;

const Achievement({
required this.title,
required this.description,
required this.icon,
required this.requirement,
required this.progress,
required this.target,
});
}

// ===============================================================
// HELPER
// ===============================================================

int max(int a, int b) {
return a > b ? a : b;
}
