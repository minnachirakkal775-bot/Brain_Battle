
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  static const int totalLevels = 180;
  static const String databaseName = 'brain_battle.db';

  static const List<String> symbols = [
    '🐶', '🐱', '🐼', '🦊', '🐸', '🐵',
    '🦁', '🐯', '🐨', '🐰', '🐻', '🐷',
    '🍎', '🍌', '🍇', '🍉', '🍓', '🍍',
    '🍒', '🥝', '🥭', '🍑', '🍋', '🥥',
    '🚗', '🚕', '🚌', '🚲', '🚀', '✈️',
    '🚁', '🚂', '🚢', '🛵', '🚜', '🚒',
    '⚽', '🏀', '🏈', '🎾', '🏆', '🎯',
    '🎸', '🎹', '🎺', '🥁', '🎻', '🎨',
    '🌞', '🌙', '⭐', '🌈', '☁️', '⚡',
    '🌸', '🌻', '🌷', '🌵', '🍀', '🌴',
    '💎', '💡', '⌚', '📱', '💻', '📷',
    '🔑', '🔔', '🎁', '🎈', '🧸', '🪁',
  ];

  Database? _database;

  int currentLevel = 1;
  int highestUnlockedLevel = 1;
  int moves = 0;
  int elapsedSeconds = 0;
  int score = 0;
  int stars = 0;

  List<String> cards = [];
  List<bool> flipped = [];
  List<bool> matched = [];

  int firstIndex = -1;
  bool checking = false;
  bool loading = true;
  bool completed = false;
  bool savingResult = false;

  Timer? timer;
  final Random random = Random();

  int get pairCount {
    if (currentLevel <= 3) return 4;
    if (currentLevel <= 10) return 6;
    if (currentLevel <= 25) return 8;
    if (currentLevel <= 50) return 10;
    if (currentLevel <= 100) return 12;
    return 15;
  }

  int get columnCount => pairCount > 12 ? 5 : 4;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    final directory = await getDatabasesPath();

    _database = await openDatabase(
      p.join(directory, databaseName),
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );

    return _database!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_match_results (
        level INTEGER PRIMARY KEY,
        completed INTEGER NOT NULL DEFAULT 0,
        best_score INTEGER NOT NULL DEFAULT 0,
        best_moves INTEGER NOT NULL DEFAULT 0,
        best_time_seconds INTEGER NOT NULL DEFAULT 0,
        stars INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_match_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value INTEGER NOT NULL
      )
    ''');

    await db.insert(
      'memory_match_settings',
      {'setting_key': 'unlocked_level', 'setting_value': 1},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> _getUnlockedLevel() async {
    final db = await database;
    final rows = await db.query(
      'memory_match_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['unlocked_level'],
      limit: 1,
    );

    if (rows.isEmpty) return 1;

    return (rows.first['setting_value'] as int)
        .clamp(1, totalLevels)
        .toInt();
  }

  Future<Map<String, int>> getDashboardProgress() async {
    final db = await database;
    final rows = await db.query(
      'memory_match_results',
      where: 'completed = ?',
      whereArgs: [1],
    );

    int totalStars = 0;
    int totalScore = 0;

    for (final row in rows) {
      totalStars += row['stars'] as int? ?? 0;
      totalScore += row['best_score'] as int? ?? 0;
    }

    return {
      'completedLevels': rows.length,
      'totalStars': totalStars,
      'totalScore': totalScore,
      'unlockedLevel': await _getUnlockedLevel(),
    };
  }

  Future<void> _saveLevelResult() async {
    final db = await database;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'memory_match_results',
        where: 'level = ?',
        whereArgs: [currentLevel],
        limit: 1,
      );

      final old = rows.isEmpty ? null : rows.first;
      final oldScore = old?['best_score'] as int? ?? 0;
      final oldStars = old?['stars'] as int? ?? 0;
      final oldMoves = old?['best_moves'] as int? ?? 0;
      final oldTime = old?['best_time_seconds'] as int? ?? 0;

      await txn.insert(
        'memory_match_results',
        {
          'level': currentLevel,
          'completed': 1,
          'best_score': max(score, oldScore),
          'best_moves': old == null
              ? moves
              : min(moves, oldMoves),
          'best_time_seconds': old == null || oldTime == 0
              ? elapsedSeconds
              : min(elapsedSeconds, oldTime),
          'stars': max(stars, oldStars),
          'completed_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final settingRows = await txn.query(
        'memory_match_settings',
        columns: ['setting_value'],
        where: 'setting_key = ?',
        whereArgs: ['unlocked_level'],
        limit: 1,
      );

      final unlocked = settingRows.isEmpty
          ? 1
          : settingRows.first['setting_value'] as int;

      final nextLevel = min(currentLevel + 1, totalLevels);

      if (nextLevel > unlocked) {
        await txn.insert(
          'memory_match_settings',
          {
            'setting_key': 'unlocked_level',
            'setting_value': nextLevel,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    timer?.cancel();
    _database?.close();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await getDashboardProgress();

      if (!mounted) return;

      setState(() {
        highestUnlockedLevel = progress['unlockedLevel'] ?? 1;
        currentLevel = highestUnlockedLevel;
        loading = false;
      });

      _prepareLevel();
    } catch (error) {
      debugPrint('Memory Match database error: $error');

      if (!mounted) return;

      setState(() {
        currentLevel = 1;
        highestUnlockedLevel = 1;
        loading = false;
      });

      _prepareLevel();
    }
  }

  void _prepareLevel() {
    timer?.cancel();

    final selected = List<String>.from(symbols)..shuffle(random);
    final chosen = selected.take(pairCount).toList();
    final newCards = [...chosen, ...chosen]..shuffle(random);

    setState(() {
      cards = newCards;
      flipped = List<bool>.filled(cards.length, false);
      matched = List<bool>.filled(cards.length, false);
      firstIndex = -1;
      checking = false;
      completed = false;
      savingResult = false;
      moves = 0;
      elapsedSeconds = 0;
      score = 0;
      stars = 0;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || completed) return;

      setState(() => elapsedSeconds++);
    });
  }

  void _selectCard(int index) {
    if (completed ||
        savingResult ||
        checking ||
        flipped[index] ||
        matched[index]) {
      return;
    }

    setState(() => flipped[index] = true);

    if (firstIndex == -1) {
      firstIndex = index;
      return;
    }

    final first = firstIndex;
    firstIndex = -1;
    moves++;

    if (cards[first] == cards[index]) {
      setState(() {
        matched[first] = true;
        matched[index] = true;
        score += 100;
      });

      if (matched.every((value) => value)) {
        _completeLevel();
      }
    } else {
      checking = true;

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        setState(() {
          flipped[first] = false;
          flipped[index] = false;
          checking = false;
        });
      });
    }
  }

  Future<void> _completeLevel() async {
    if (completed || savingResult) return;

    timer?.cancel();

    final timeBonus = max(0, 300 - elapsedSeconds);
    final moveBonus = max(0, pairCount * 200 - moves * 10);

    final earnedStars = moves <= pairCount
        ? 3
        : moves <= pairCount * 2
        ? 2
        : 1;

    setState(() {
      completed = true;
      savingResult = true;
      score += timeBonus + moveBonus;
      stars = earnedStars;
    });

    try {
      await _saveLevelResult();

      final progress = await getDashboardProgress();

      if (!mounted) return;

      setState(() {
        highestUnlockedLevel = progress['unlockedLevel'] ?? 1;
        savingResult = false;
      });

      _showResultDialog();
    } catch (error) {
      debugPrint('Could not save game result: $error');

      if (!mounted) return;

      setState(() => savingResult = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save progress. Please try again.'),
        ),
      );
    }
  }

  void _showResultDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Level Completed!',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            Text('Level $currentLevel'),
            Text(List.filled(stars, '⭐').join(' ')),
            const SizedBox(height: 12),
            Text('Score: $score'),
            Text('Moves: $moves'),
            Text('Time: ${_formatTime(elapsedSeconds)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openLevelSelection();
            },
            child: const Text('Levels'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              if (currentLevel < totalLevels) {
                _goToNextLevel();
              } else {
                _openLevelSelection();
              }
            },
            child: Text(
              currentLevel < totalLevels ? 'Next Level' : 'All Done!',
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextLevel() {
    if (currentLevel >= totalLevels) return;

    setState(() {
      currentLevel++;
      highestUnlockedLevel = max(highestUnlockedLevel, currentLevel);
    });

    _prepareLevel();
  }

  Future<void> _openLevelSelection() async {
    timer?.cancel();

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MemoryMatchLevelSelectionScreen(
          highestUnlockedLevel: highestUnlockedLevel,
          onLevelSelected: (level) {
            setState(() => currentLevel = level);
            _prepareLevel();
          },
        ),
      ),
    );

    if (!mounted) return;
    await _loadProgress();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Match - Level $currentLevel'),
        actions: [
          IconButton(
            onPressed: loading ? null : _openLevelSelection,
            icon: const Icon(Icons.grid_view),
            tooltip: 'Choose level',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _statCard('Moves', '$moves', Icons.touch_app),
                _statCard('Time', _formatTime(elapsedSeconds), Icons.timer),
                _statCard('Score', '$score', Icons.star),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final visible = flipped[index] || matched[index];

                return GestureDetector(
                  onTap: () => _selectCard(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: matched[index]
                          ? Colors.green.shade100
                          : visible
                          ? Colors.deepPurple.shade50
                          : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: matched[index]
                            ? Colors.green
                            : Colors.deepPurple.shade200,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: visible
                          ? Text(
                        cards[index],
                        style: const TextStyle(fontSize: 30),
                      )
                          : const Icon(
                        Icons.question_mark,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (savingResult)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Saving progress...'),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openLevelSelection,
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _prepareLevel,
                    child: const Text('Restart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoryMatchLevelSelectionScreen extends StatelessWidget {
  const MemoryMatchLevelSelectionScreen({
    super.key,
    required this.highestUnlockedLevel,
    required this.onLevelSelected,
  });

  final int highestUnlockedLevel;
  final ValueChanged<int> onLevelSelected;

  static const int totalLevels = 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Level'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Memory Match',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Unlocked: $highestUnlockedLevel / $totalLevels'),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: highestUnlockedLevel / totalLevels,
                  minHeight: 7,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: totalLevels,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final level = index + 1;
                final unlocked = level <= highestUnlockedLevel;

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: unlocked
                      ? () {
                    Navigator.pop(context);
                    onLevelSelected(level);
                  }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: unlocked
                          ? Colors.deepPurple
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          !unlocked
                              ? Icons.lock
                              : level == highestUnlockedLevel
                              ? Icons.play_circle_fill
                              : Icons.check_circle,
                          color: unlocked ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Level $level',
                          style: TextStyle(
                            color: unlocked ? Colors.white : Colors.black54,
                            fontSize: 12,
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
}
