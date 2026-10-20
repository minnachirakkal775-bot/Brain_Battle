import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OddOneOutScreen extends StatefulWidget {
  const OddOneOutScreen({super.key});

  @override
  State<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends State<OddOneOutScreen> {
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
        prefs.getStringList('odd_one_out_completed_levels') ?? [];

    final stars = <int, int>{};
    final scores = <int, int>{};

    for (int level = 1; level <= totalLevels; level++) {
      final star = prefs.getInt('odd_one_out_stars_$level');
      final score = prefs.getInt('odd_one_out_best_score_$level');

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

  bool _isUnlocked(int level) {
    if (level == 1) return true;
    return _completedLevels.contains(level - 1);
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

  Future<void> _openLevel(int level) async {
    if (!_isUnlocked(level)) {
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
        builder: (_) => OddOneOutGameScreen(level: level),
      ),
    );

    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odd One Out'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.filter_none,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Odd One Out',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Find the different shape, symbol or number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
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
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final level = index + 1;
                final unlocked = _isUnlocked(level);
                final completed = _completedLevels.contains(level);
                final stars = _stars[level] ?? 0;
                final bestScore = _bestScores[level];

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openLevel(level),
                  child: Container(
                    decoration: BoxDecoration(
                      color: unlocked
                          ? Colors.white
                          : Colors.grey.shade200,
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
                              ? completed
                              ? Icons.check_circle
                              : Icons.play_circle_fill
                              : Icons.lock,
                          size: 29,
                          color: unlocked
                              ? _difficultyColor(level)
                              : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level $level',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _difficulty(level),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _difficultyColor(level),
                          ),
                        ),
                        const SizedBox(height: 3),
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
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
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

// ============================================================
// GAME SCREEN
// ============================================================

class OddOneOutGameScreen extends StatefulWidget {
  final int level;

  const OddOneOutGameScreen({
    super.key,
    required this.level,
  });

  @override
  State<OddOneOutGameScreen> createState() =>
      _OddOneOutGameScreenState();
}

class _OddOneOutGameScreenState
    extends State<OddOneOutGameScreen> {
  static const int questionsPerLevel = 5;

  late List<OddOneOutQuestion> _questions;

  int _questionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _streak = 0;

  int _timeLeft = 20;

  Timer? _timer;

  bool _answered = false;
  int? _selectedIndex;

  int get _timeLimit {
    if (widget.level <= 60) return 20;
    if (widget.level <= 120) return 15;
    return 10;
  }

  @override
  void initState() {
    super.initState();

    _questions = OddOneOutGenerator.generateLevel(
      widget.level,
    );

    _startQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuestion() {
    _timer?.cancel();

    setState(() {
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

    final question = _questions[_questionIndex];

    final correct = selectedIndex != null &&
        selectedIndex == question.oddIndex;

    setState(() {
      _answered = true;
      _selectedIndex = selectedIndex;

      if (correct) {
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

    final completed = prefs.getStringList(
      'odd_one_out_completed_levels',
    ) ??
        [];

    if (!completed.contains(widget.level.toString())) {
      completed.add(widget.level.toString());
    }

    await prefs.setStringList(
      'odd_one_out_completed_levels',
      completed,
    );

    final oldStars = prefs.getInt(
      'odd_one_out_stars_${widget.level}',
    ) ??
        0;

    if (stars > oldStars) {
      await prefs.setInt(
        'odd_one_out_stars_${widget.level}',
        stars,
      );
    }

    final oldScore = prefs.getInt(
      'odd_one_out_best_score_${widget.level}',
    ) ??
        0;

    if (_score > oldScore) {
      await prefs.setInt(
        'odd_one_out_best_score_${widget.level}',
        _score,
      );
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OddOneOutResultScreen(
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
    final question = _questions[_questionIndex];

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
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
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
              const SizedBox(height: 15),
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
              const SizedBox(height: 15),
              Text(
                question.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: question.items.length,
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                    question.items.length <= 6 ? 2 : 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = question.items[index];

                    final isCorrect =
                        index == question.oddIndex;

                    final isSelected =
                        index == _selectedIndex;

                    Color borderColor =
                        Colors.grey.shade300;

                    Color backgroundColor =
                        Colors.white;

                    if (_answered) {
                      if (isCorrect) {
                        borderColor = Colors.green;
                        backgroundColor =
                            Colors.green.withValues(alpha: 0.12);
                      } else if (isSelected) {
                        borderColor = Colors.red;
                        backgroundColor =
                            Colors.red.withValues(alpha: 0.12);
                      }
                    }

                    return InkWell(
                      borderRadius:
                      BorderRadius.circular(20),
                      onTap: _answered
                          ? null
                          : () => _handleAnswer(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: borderColor,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: OddVisual(
                            item: item,
                            level: widget.level,
                          ),
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

// ============================================================
// VISUAL ITEM
// ============================================================

class OddVisual extends StatelessWidget {
  final OddVisualItem item;
  final int level;

  const OddVisual({
    super.key,
    required this.item,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    if (item.type == OddVisualType.number) {
      return Text(
        item.value,
        style: TextStyle(
          fontSize: level > 120 ? 42 : 38,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (item.type == OddVisualType.letter) {
      return Text(
        item.value,
        style: TextStyle(
          fontSize: level > 120 ? 44 : 40,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (item.type == OddVisualType.symbol) {
      return Text(
        item.value,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Icon(
      item.icon,
      size: level > 120 ? 58 : 52,
      color: item.color,
    );
  }
}

// ============================================================
// RESULT SCREEN
// ============================================================

class OddOneOutResultScreen extends StatelessWidget {
  final int level;
  final int score;
  final int correctAnswers;
  final int stars;

  const OddOneOutResultScreen({
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
            mainAxisAlignment:
            MainAxisAlignment.center,
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
                mainAxisAlignment:
                MainAxisAlignment.center,
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
                value:
                '${accuracy.toStringAsFixed(0)}%',
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
                              OddOneOutGameScreen(
                                level: level + 1,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_forward,
                    ),
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
                            OddOneOutGameScreen(
                              level: level,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Retry Level',
                  ),
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
                  label: const Text(
                    'Back to Levels',
                  ),
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
        horizontal: 30,
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

// ============================================================
// DATA TYPES
// ============================================================

enum OddVisualType {
  shape,
  symbol,
  number,
  letter,
}

class OddVisualItem {
  final OddVisualType type;
  final String value;
  final IconData? icon;
  final Color? color;

  const OddVisualItem({
    required this.type,
    required this.value,
    this.icon,
    this.color,
  });

  factory OddVisualItem.shape(
      IconData icon, {
        Color color = Colors.indigo,
      }) {
    return OddVisualItem(
      type: OddVisualType.shape,
      value: 'shape',
      icon: icon,
      color: color,
    );
  }

  factory OddVisualItem.symbol(
      String value,
      ) {
    return OddVisualItem(
      type: OddVisualType.symbol,
      value: value,
    );
  }

  factory OddVisualItem.number(
      int value,
      ) {
    return OddVisualItem(
      type: OddVisualType.number,
      value: '$value',
    );
  }

  factory OddVisualItem.letter(
      String value,
      ) {
    return OddVisualItem(
      type: OddVisualType.letter,
      value: value,
    );
  }
}

class OddOneOutQuestion {
  final String instruction;
  final List<OddVisualItem> items;
  final int oddIndex;

  const OddOneOutQuestion({
    required this.instruction,
    required this.items,
    required this.oddIndex,
  });
}

// ============================================================
// QUESTION GENERATOR
// ============================================================

class OddOneOutGenerator {
  static List<OddOneOutQuestion> generateLevel(
      int level,
      ) {
    final random = Random(level * 731);

    return List.generate(
      5,
          (index) => _generateQuestion(
        level,
        random,
        index,
      ),
    );
  }

  static OddOneOutQuestion _generateQuestion(
      int level,
      Random random,
      int index,
      ) {
    if (level <= 60) {
      return _easyQuestion(random, index);
    }

    if (level <= 120) {
      return _mediumQuestion(random, index);
    }

    return _difficultQuestion(random, index);
  }

  // ==========================================================
  // EASY
  // ==========================================================

  static OddOneOutQuestion _easyQuestion(
      Random random,
      int index,
      ) {
    final type = random.nextInt(3);

    if (type == 0) {
      return _shapeQuestion(random);
    }

    if (type == 1) {
      return _numberQuestion(random);
    }

    return _symbolQuestion(random);
  }

  // ==========================================================
  // MEDIUM
  // ==========================================================

  static OddOneOutQuestion _mediumQuestion(
      Random random,
      int index,
      ) {
    final type = random.nextInt(4);

    if (type == 0) {
      return _shapeQuestion(random);
    }

    if (type == 1) {
      return _numberPatternQuestion(random);
    }

    if (type == 2) {
      return _letterQuestion(random);
    }

    return _symbolQuestion(random);
  }

  // ==========================================================
  // DIFFICULT
  // ==========================================================

  static OddOneOutQuestion _difficultQuestion(
      Random random,
      int index,
      ) {
    final type = random.nextInt(5);

    if (type == 0) {
      return _difficultShapeQuestion(random);
    }

    if (type == 1) {
      return _difficultNumberQuestion(random);
    }

    if (type == 2) {
      return _letterQuestion(random);
    }

    if (type == 3) {
      return _symbolQuestion(random);
    }

    return _patternQuestion(random);
  }

  // ==========================================================
  // SHAPES
  // ==========================================================

  static OddOneOutQuestion _shapeQuestion(
      Random random,
      ) {
    final icons = [
      Icons.circle,
      Icons.square,
      Icons.star,
      Icons.favorite,
      Icons.diamond,
    ];

    final normal =
    icons[random.nextInt(icons.length)];

    IconData odd;

    do {
      odd = icons[random.nextInt(icons.length)];
    } while (odd == normal);

    final oddIndex = random.nextInt(6);

    final items = List.generate(
      6,
          (index) => OddVisualItem.shape(
        index == oddIndex ? odd : normal,
      ),
    );

    return OddOneOutQuestion(
      instruction: 'Find the different shape',
      items: items,
      oddIndex: oddIndex,
    );
  }

  static OddOneOutQuestion _difficultShapeQuestion(
      Random random,
      ) {
    final normal = [
      Icons.circle,
      Icons.square,
      Icons.star,
      Icons.favorite,
    ][random.nextInt(4)];

    final oddOptions = [
      Icons.circle_outlined,
      Icons.square_outlined,
      Icons.star_border,
      Icons.favorite_border,
    ];

    final odd =
    oddOptions[random.nextInt(oddOptions.length)];

    final oddIndex = random.nextInt(9);

    final items = List.generate(
      9,
          (index) {
        if (index == oddIndex) {
          return OddVisualItem.shape(odd);
        }

        return OddVisualItem.shape(normal);
      },
    );

    return OddOneOutQuestion(
      instruction: 'Find the subtle shape difference',
      items: items,
      oddIndex: oddIndex,
    );
  }

  // ==========================================================
  // NUMBERS
  // ==========================================================

  static OddOneOutQuestion _numberQuestion(
      Random random,
      ) {
    final base =
        random.nextInt(8) + 1;

    final oddIndex = random.nextInt(6);

    final items = List.generate(
      6,
          (index) {
        if (index == oddIndex) {
          return OddVisualItem.number(
            base + 1,
          );
        }

        return OddVisualItem.number(base);
      },
    );

    return OddOneOutQuestion(
      instruction: 'Find the different number',
      items: items,
      oddIndex: oddIndex,
    );
  }

  static OddOneOutQuestion _numberPatternQuestion(
      Random random,
      ) {
    final start =
        random.nextInt(20) + 1;

    final step =
        random.nextInt(4) + 1;

    final oddIndex = random.nextInt(6);

    final items = List.generate(
      6,
          (index) {
        if (index == oddIndex) {
          return OddVisualItem.number(
            start +
                index * step +
                1,
          );
        }

        return OddVisualItem.number(
          start + index * step,
        );
      },
    );

    return OddOneOutQuestion(
      instruction:
      'Find the number that breaks the pattern',
      items: items,
      oddIndex: oddIndex,
    );
  }

  static OddOneOutQuestion _difficultNumberQuestion(
      Random random,
      ) {
    final start =
        random.nextInt(8) + 2;

    final step =
        random.nextInt(5) + 2;

    final oddIndex = random.nextInt(9);

    final items = List.generate(
      9,
          (index) {
        if (index == oddIndex) {
          return OddVisualItem.number(
            start +
                index * step +
                step,
          );
        }

        return OddVisualItem.number(
          start + index * step,
        );
      },
    );

    return OddOneOutQuestion(
      instruction:
      'Find the number that does not follow the sequence',
      items: items,
      oddIndex: oddIndex,
    );
  }

  // ==========================================================
  // SYMBOLS
  // ==========================================================

  static OddOneOutQuestion _symbolQuestion(
      Random random,
      ) {
    final symbols = [
      '★',
      '●',
      '◆',
      '▲',
      '■',
      '♥',
    ];

    final normal =
    symbols[random.nextInt(symbols.length)];

    String odd;

    do {
      odd =
      symbols[random.nextInt(symbols.length)];
    } while (odd == normal);

    final oddIndex = random.nextInt(6);

    final items = List.generate(
      6,
          (index) {
        return OddVisualItem.symbol(
          index == oddIndex ? odd : normal,
        );
      },
    );

    return OddOneOutQuestion(
      instruction: 'Find the different symbol',
      items: items,
      oddIndex: oddIndex,
    );
  }

  // ==========================================================
  // LETTERS
  // ==========================================================

  static OddOneOutQuestion _letterQuestion(
      Random random,
      ) {
    final letters = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
    ];

    final normal =
    letters[random.nextInt(letters.length)];

    String odd;

    do {
      odd =
      letters[random.nextInt(letters.length)];
    } while (odd == normal);

    final oddIndex = random.nextInt(9);

    final items = List.generate(
      9,
          (index) {
        return OddVisualItem.letter(
          index == oddIndex ? odd : normal,
        );
      },
    );

    return OddOneOutQuestion(
      instruction: 'Find the different letter',
      items: items,
      oddIndex: oddIndex,
    );
  }

  // ==========================================================
  // ADVANCED PATTERN
  // ==========================================================

  static OddOneOutQuestion _patternQuestion(
      Random random,
      ) {
    final values = [
      '▲',
      '▲',
      '▲',
      '▲',
      '▲',
      '△',
      '▲',
      '▲',
      '▲',
    ];

    values.shuffle(random);

    final actualOddIndex =
    values.indexOf('△');

    final items = values
        .map(
          (value) =>
          OddVisualItem.symbol(value),
    )
        .toList();

    return OddOneOutQuestion(
      instruction:
      'Find the symbol that is slightly different',
      items: items,
      oddIndex: actualOddIndex,
    );
  }
}