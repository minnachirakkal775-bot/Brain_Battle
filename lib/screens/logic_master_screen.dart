import 'dart:math';

import 'package:flutter/material.dart';
import '../database/database_helper.dart';

/// Logic Master: 180 levels, five questions per level.
/// Progress and game sessions are stored in SQLite.
class LogicMasterScreen extends StatelessWidget {
  const LogicMasterScreen({super.key});

  @override
  Widget build(BuildContext context) => const LogicLevelScreen();
}

class LogicLevelScreen extends StatefulWidget {
  const LogicLevelScreen({super.key});

  @override
  State<LogicLevelScreen> createState() => _LogicLevelScreenState();
}

class _LogicLevelScreenState extends State<LogicLevelScreen> {
  static const int totalLevels = 180;
  Set<int> completedLevels = {};
  Map<int, int> stars = {};
  Map<int, int> bestScores = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final rows =
      await DatabaseHelper.instance.getLevelProgress('Logic Master');
      final completed = <int>{};
      final loadedStars = <int, int>{};
      final loadedScores = <int, int>{};

      for (final row in rows) {
        final level = row['level'] as int;
        if (level < 1 || level > totalLevels) continue;
        if ((row['completed'] as int? ?? 0) == 1) completed.add(level);
        loadedStars[level] = row['stars'] as int? ?? 0;
        loadedScores[level] = row['best_score'] as int? ?? 0;
      }

      if (!mounted) return;
      setState(() {
        completedLevels = completed;
        stars = loadedStars;
        bestScores = loadedScores;
        loading = false;
      });
    } catch (e) {
      debugPrint('Could not load Logic Master progress: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  bool _isUnlocked(int level) =>
      level == 1 || completedLevels.contains(level - 1);

  String _difficulty(int level) =>
      level <= 60 ? 'Easy' : level <= 120 ? 'Medium' : 'Difficult';

  Color _difficultyColor(int level) =>
      level <= 60 ? Colors.green : level <= 120 ? Colors.orange : Colors.red;

  int get totalStars => stars.values.fold(0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Logic Master'), centerTitle: true),
      body: Column(
        children: [
          _buildHeader(),
          _buildDifficultyLegend(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              itemCount: totalLevels,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (_, index) => _buildLevelCard(index + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final progress = completedLevels.length / totalLevels;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.indigo.shade500],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology, color: Colors.white, size: 38),
          const SizedBox(height: 6),
          const Text(
            'Logic Master',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Solve patterns, sequences and logic puzzles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${completedLevels.length} / $totalLevels',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '⭐ $totalStars Stars',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem('Easy', Colors.green),
          _legendItem('Medium', Colors.orange),
          _legendItem('Difficult', Colors.red),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label,
          style:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _buildLevelCard(int level) {
    final unlocked = _isUnlocked(level);
    final completed = completedLevels.contains(level);
    final levelStars = stars[level] ?? 0;
    final color = _difficultyColor(level);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: unlocked
          ? () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LogicGameScreen(level: level),
          ),
        );
        await _loadProgress();
      }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        decoration: BoxDecoration(
          color: unlocked ? Theme.of(context).colorScheme.surface : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed
                ? Colors.green
                : unlocked
                ? color
                : Colors.grey.shade300,
            width: completed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              !unlocked
                  ? Icons.lock
                  : completed
                  ? Icons.check_circle
                  : Icons.play_circle_fill,
              color: !unlocked
                  ? Colors.grey.shade500
                  : completed
                  ? Colors.green
                  : color,
              size: 19,
            ),
            const SizedBox(height: 2),
            Text(
              '$level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: unlocked ? color : Colors.grey.shade500,
              ),
            ),
            Text(
              _difficulty(level),
              maxLines: 1,
              style: TextStyle(
                fontSize: 7.5,
                color: unlocked ? color : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            if (completed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (i) => Icon(
                    i < levelStars ? Icons.star : Icons.star_border,
                    size: 10,
                    color: Colors.amber,
                  ),
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class LogicGameScreen extends StatefulWidget {
  final int level;
  const LogicGameScreen({super.key, required this.level});

  @override
  State<LogicGameScreen> createState() => _LogicGameScreenState();
}

class _LogicGameScreenState extends State<LogicGameScreen> {
  static const int questionsPerLevel = 5;
  late final List<LogicQuestion> questions;
  int currentQuestion = 0;
  int correctAnswers = 0;
  int selectedAnswer = -1;
  bool answered = false;
  bool processing = false;
  late final DateTime startedAt;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    questions = LogicQuestionGenerator.generateLevel(widget.level);
  }

  String get difficulty =>
      widget.level <= 60 ? 'Easy' : widget.level <= 120 ? 'Medium' : 'Difficult';

  Color get difficultyColor => widget.level <= 60
      ? Colors.green
      : widget.level <= 120
      ? Colors.orange
      : Colors.red;

  void _selectAnswer(int index) {
    if (answered || processing) return;
    setState(() {
      selectedAnswer = index;
      answered = true;
      if (index == questions[currentQuestion].correctIndex) correctAnswers++;
    });
  }

  Future<void> _nextQuestion() async {
    if (!answered || processing) return;
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = -1;
        answered = false;
      });
      return;
    }

    setState(() => processing = true);
    final score = correctAnswers * 20;
    final accuracy = correctAnswers / questionsPerLevel * 100.0;
    final earnedStars = accuracy >= 90
        ? 3
        : accuracy >= 70
        ? 2
        : accuracy >= 50
        ? 1
        : 0;
    final duration = DateTime.now().difference(startedAt).inSeconds;

    try {
      final db = DatabaseHelper.instance;
      await db.saveGameSession(
        gameType: 'Logic Master',
        level: widget.level,
        score: score,
        accuracy: accuracy,
        durationSeconds: duration,
      );
      await db.saveLevelProgress(
        gameType: 'Logic Master',
        level: widget.level,
        completed: true,
        stars: earnedStars,
        bestScore: score,
      );
    } catch (e) {
      debugPrint('Could not save Logic Master result: $e');
      if (!mounted) return;
      setState(() => processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save progress: $e')),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LogicResultScreen(
          level: widget.level,
          score: score,
          correctAnswers: correctAnswers,
          totalQuestions: questionsPerLevel,
          stars: earnedStars,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '${currentQuestion + 1}/$questionsPerLevel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: difficultyColor.withValues(alpha: 0.10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: difficultyColor),
                      const SizedBox(width: 8),
                      Text('Logic Master',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: difficultyColor)),
                    ],
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: difficultyColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(difficulty,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (currentQuestion + 1) / questionsPerLevel,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.deepPurple.shade50,
                          Colors.indigo.shade50
                        ]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepPurple.shade100),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              size: 36, color: Colors.deepPurple),
                          const SizedBox(height: 14),
                          Text(
                            question.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(question.options.length, (index) {
                      final isCorrect = index == question.correctIndex;
                      final isSelected = index == selectedAnswer;
                      var background = Theme.of(context).colorScheme.surface;
                      var border = Colors.grey.shade300;
                      var textColor = Theme.of(context).colorScheme.onSurface;
                      if (answered && isCorrect) {
                        background = Colors.green.shade50;
                        border = Colors.green;
                        textColor = Colors.green.shade800;
                      } else if (answered && isSelected) {
                        background = Colors.red.shade50;
                        border = Colors.red;
                        textColor = Colors.red.shade800;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => _selectAnswer(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 17),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: border, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(question.options[index],
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor)),
                                ),
                                if (answered && isCorrect)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                if (answered && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (answered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: selectedAnswer == question.correctIndex
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          question.explanation,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: answered && !processing ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    currentQuestion == questions.length - 1
                        ? 'FINISH LEVEL'
                        : 'NEXT QUESTION',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogicQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const LogicQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class LogicQuestionGenerator {
  static final Random _random = Random();

  static List<LogicQuestion> generateLevel(int level) {
    return List.generate(5, (i) {
      final seed = (level - 1) * 5 + i;
      if (level <= 60) return _easy(seed);
      if (level <= 120) return _medium(seed);
      return _difficult(seed);
    });
  }

  static LogicQuestion _easy(int seed) {
    switch (seed % 5) {
      case 0:
        final start = 2 + seed % 10;
        final step = 2 + seed % 5;
        final values = List.generate(5, (i) => start + i * step);
        return _numeric('${values.join(', ')}, ?', values.last + step,
            'The numbers increase by $step each time.');
      case 1:
        final start = 3 + seed % 8;
        final step = 2 + seed % 4;
        final values = List.generate(5, (i) => start + i * step);
        return _numeric('${values.join(' → ')} → ?', values.last + step,
            'Add $step to each number.');
      case 2:
        final step = 2 + seed % 5;
        final start = 30 + seed % 10;
        final values = List.generate(5, (i) => start - i * step);
        return _numeric('${values.join(', ')}, ?', values.last - step,
            'The sequence decreases by $step each time.');
      case 3:
        final multiplier = seed.isEven ? 2 : 3;
        final start = 1 + seed % 4;
        final values = List.generate(
            5, (i) => start * pow(multiplier, i).toInt());
        return _numeric('${values.join(', ')}, ?',
            values.last * multiplier, 'Multiply each number by $multiplier.');
      default:
        final base = 2 + seed % 6;
        final values = [base * 2, base * 4, base * 6, base * 8, base * 9];
        final options = ['${values[0]}', '${values[1]}', '${values[2]}',
          '${values[3]}', '${values[4]}'];
        final correct = values[4].toString();
        final shuffled = [...options]..shuffle(_random);
        return LogicQuestion(
          question: 'Which value breaks the pattern?\n${values.join(', ')}',
          options: shuffled,
          correctIndex: shuffled.indexOf(correct),
          explanation: 'The first four values are even multiples of $base; '
              '${values[4]} is not.',
        );
    }
  }

  static LogicQuestion _medium(int seed) {
    switch (seed % 6) {
      case 0:
        final a = 2 + seed % 5;
        final b = 5 + seed % 5;
        final values = [a, b, a + 2, b + 2, a + 4, b + 4];
        return _numeric('${values.join(', ')}, ?', a + 6,
            'There are two alternating sequences, each increasing by 2.');
      case 1:
        final start = 1 + seed % 5;
        final values = List.generate(5, (i) => (start + i) * (start + i));
        final n = start + 5;
        return _numeric('${values.join(', ')}, ?', n * n,
            'These are consecutive square numbers.');
      case 2:
        final start = 2 + seed % 5;
        final add = 1 + seed % 4;
        final values = <int>[start];
        for (int i = 1; i < 5; i++) {
          values.add(values.last * 2 + add);
        }
        return _numeric('${values.join(', ')}, ?', values.last * 2 + add,
            'Multiply by 2, then add $add.');
      case 3:
        final start = 10 + seed % 10;
        final step = 2 + seed % 3;
        final values = <int>[start];
        for (int i = 0; i < 4; i++) {
          values.add(values.last + step + (i + 1) * 2);
        }
        final answer = values.last + step + 10;
        return _numeric('${values.take(5).join(', ')}, ?', answer,
            'The difference increases by 2 each time.');
      case 4:
        final start = 4 + seed % 5;
        final values = [start, start + 3, start + 9, start + 18, start + 30];
        return _numeric('${values.join(', ')}, ?', values.last + 15,
            'The differences are +3, +6, +9, +12, then +15.');
      default:
        final a = 10 + seed % 10;
        final b = 5 + seed % 5;
        return _numeric('If A = $a and B = $b, what is A + B?', a + b,
            'A + B = $a + $b = ${a + b}.');
    }
  }

  static LogicQuestion _difficult(int seed) {
    switch (seed % 7) {
      case 0:
        final a = 1 + seed % 3;
        final b = 2 + seed % 3;
        final values = <int>[a, b];
        for (int i = 2; i < 6; i++) {
          values.add(values[i - 1] + values[i - 2]);
        }
        return _numeric('${values.join(', ')}, ?',
            values[4] + values[5], 'Each number is the sum of the previous two.');
      case 1:
        const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
        final start = seed % 5;
        final values = List.generate(5, (i) => primes[start + i]);
        return _numeric('${values.join(', ')}, ?', primes[start + 5],
            'These are consecutive prime numbers.');
      case 2:
        final start = 1 + seed % 3;
        final values = List.generate(5, (i) => pow(start + i, 3).toInt());
        final n = start + 5;
        return _numeric('${values.join(', ')}, ?', n * n * n,
            'These are consecutive cube numbers.');
      case 3:
        final start = 5 + seed % 5;
        final values = <int>[start];
        values.add(values.last + 3);
        values.add(values.last * 2);
        values.add(values.last + 5);
        values.add(values.last * 2);
        return _numeric('${values.join(', ')}, ?', values.last + 7,
            'Alternate adding increasing odd numbers and multiplying by 2.');
      case 4:
        final start = 5 + seed % 5;
        const differences = [3, 6, 11, 18, 27];
        final values = <int>[start];
        for (final difference in differences) {
          values.add(values.last + difference);
        }
        return _numeric('${values.take(5).join(', ')}, ?', values.last,
            'The differences are 3, 6, 11, 18, 27.');
      case 5:
        final x = 4 + seed % 5;
        final multiplier = 2 + seed % 3;
        return _numeric('If x = $x, what is ($x × $multiplier) + 3?',
            x * multiplier + 3, 'Multiply $x by $multiplier, then add 3.');
      default:
        final start = 3 + seed % 5;
        final values = [start, start * 2, start * 2 + 3,
          (start * 2 + 3) * 2, (start * 2 + 3) * 2 + 5];
        return _numeric('${values.join(', ')}, ?', values.last * 2,
            'Alternate multiplying by 2 and adding increasing odd numbers.');
    }
  }

  static LogicQuestion _numeric(String prompt, int answer, String explanation) {
    final values = <int>{answer};
    final variation = max(8, (answer.abs() * 0.25).round());
    while (values.length < 4) {
      final offset = _random.nextInt(variation * 2 + 1) - variation;
      if (offset != 0 && answer + offset >= 0) values.add(answer + offset);
    }
    final options = values.map((v) => v.toString()).toList()..shuffle(_random);
    return LogicQuestion(
      question: prompt,
      options: options,
      correctIndex: options.indexOf(answer.toString()),
      explanation: explanation,
    );
  }
}

class LogicResultScreen extends StatelessWidget {
  final int level;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int stars;

  const LogicResultScreen({
    super.key,
    required this.level,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.stars,
  });

  double get accuracy =>
      totalQuestions == 0 ? 0 : correctAnswers / totalQuestions * 100;

  String get message => stars == 3
      ? 'Excellent! You are a Logic Master!'
      : stars == 2
      ? 'Great job! Keep training your brain.'
      : stars == 1
      ? 'Good effort! Try again for more stars.'
      : 'Keep practicing. You can do better!';

  void _backToLevels(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Complete'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.deepPurple.shade400,
                    Colors.indigo.shade400
                  ]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 58),
              ),
              const SizedBox(height: 18),
              Text('Level $level Complete!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 27, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      size: 48,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: _statCard(Icons.check_circle,
                      '$correctAnswers/$totalQuestions', 'Correct')),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard(
                      Icons.percent, '${accuracy.round()}%', 'Accuracy')),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard(Icons.score, '$score', 'Score')),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LogicGameScreen(level: level)),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETRY LEVEL'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (level < 180)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                LogicGameScreen(level: level + 1)),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('NEXT LEVEL ${level + 1}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _backToLevels(context),
                icon: const Icon(Icons.grid_view),
                label: const Text('BACK TO LEVELS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(height: 7),
          Text(value,
              style:
              const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
